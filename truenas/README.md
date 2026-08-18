# TrueNAS Central Monitoring

VictoriaMetrics + vmalert + alertmanager on TrueNAS SCALE, exposed at
`https://vm.wyattau.com` via the existing Cloudflare Tunnel. Hosts push
metrics with vmagent (already scaffolded in the dotfiles playbook).

```
hosts (vmagent) ──TLS──▶ Cloudflare ──▶ cloudflared (NAS) ──▶ VM:8428
                                                              ├─ vmalert (rules)
                                                              └─ alertmanager ─▶ Telegram
```

## Files

| File | Purpose |
|---|---|
| `docker-compose.yml` | The stack. Versions pinned (VM 1.138.0, AM 0.33.1) |
| `vm-prometheus.yml` | Self-scrape only — hosts push, never scraped |
| `alerts.yml` | Alert rules (incl. HostNoData, 1h sleep-tolerant) |
| `alertmanager.yml` | Telegram routing; token in mounted file |
| `cloudflared-ingress.yml` | Ingress snippet to merge into existing tunnel |

## Deploy (SSH path)

1. **Copy files** to the NAS, e.g. `/mnt/tank/apps/monitoring/`:
   ```bash
   scp truenas/{docker-compose.yml,vm-prometheus.yml,alerts.yml,alertmanager.yml} \
       root@<nas>:/mnt/tank/apps/monitoring/
   ```

2. **Remote-write auth** — generate a bcrypt hash (the compose file reads
   `VM_AUTH_USER`/`VM_AUTH_PASSWORD` from an env file):
   ```bash
   cd /mnt/tank/apps/monitoring
   cat > .env <<EOF
   VM_AUTH_USER=vmwriter
   VM_AUTH_PASSWORD=<long-random-password>
   EOF
   chmod 600 .env
   ```
   Record the password — hosts need the same pair (step 5).

3. **Telegram token file** (bot token from @BotFather — same bot as local):
   ```bash
   echo -n "123456:ABC-DEF..." > telegram-token
   chmod 600 telegram-token   # compose mounts it read-only
   ```

4. **Tunnel ingress** — merge the snippet from `cloudflared-ingress.yml`
   into your existing cloudflared config on the NAS, add the DNS CNAME
   for `vm.wyattau.com` (or let `cloudflared` create it:
   `cloudflared tunnel route dns <tunnel> vm.wyattau.com`), restart cloudflared.

5. **Cloudflare Access** (Zero Trust dashboard) — two self-hosted apps:
   - `vm.wyattau.com/api/v1/write` → policy **Bypass** (Service Auth):
     VM's basic auth protects this path
   - `vm.wyattau.com` (everything else) → policy **Allow**, your email,
     email-OTP — guards the UI and query API

6. **Start the stack**:
   ```bash
   cd /mnt/tank/apps/monitoring && docker compose up -d
   docker compose ps        # all three healthy
   ```

> Custom App (web UI) path: create the app with the same image/version,
> env vars, and volume mounts from `docker-compose.yml`; host paths under
> `/mnt/...`. The SSH path above is usually faster.

## Verify

```bash
# 1. Stack health
curl -s http://<nas>:8428/health          # from LAN → OK

# 2. Auth enforced (from a host, through the tunnel)
curl -s -o /dev/null -w "%{http_code}\n" \
     https://vm.wyattau.com/api/v1/write -X POST   # 401 without creds

# 3. Remote-write works with creds (empty body → 400 = auth passed)
curl -s -o /dev/null -w "%{http_code}\n" -X POST \
     -u vmwriter:<password> https://vm.wyattau.com/api/v1/write   # 400

# 4. Telegram end-to-end
curl -s -X POST http://<nas>:9093/api/v2/alerts -H 'Content-Type: application/json' \
  -d '[{"labels":{"alertname":"NasTest","severity":"info","instance":"truenas"}}]'
# → message arrives within ~30s
```

## Flip the hosts

In the dotfiles repo, `ansible/host_vars/common.yml`:

```yaml
monitoring_remote_write_url: "https://vm.wyattau.com/api/v1/write"
monitoring_remote_write_user: "vmwriter"
monitoring_remote_write_pass: "<password from step 2>"
```

Then `sys-sync` on every host → vmagent activates, scrapes local
node_exporter, remote-writes to the NAS. Buffers locally whenever the
NAS/tunnel is unreachable — safe for sleeping laptops.

> Secret note: the password briefly lives in the repo working tree this way.
> Acceptable for a personal repo; alternatively set the two vars per-host in
> an uncommitted overlay. Committing is simpler and the repo is private.

## Rollback

```bash
cd /mnt/tank/apps/monitoring && docker compose down   # stack off
# hosts: blank monitoring_remote_write_url in common.yml + sys-sync
#        → vmagent stops; local monitoring (sys-monitor) still available
```

Volumes persist under the `monitoring_vm-data` docker volume — no data
loss on `down`. `down -v` only if you want the metrics gone.
