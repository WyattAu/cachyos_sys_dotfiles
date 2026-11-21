# TrueNAS Matrix Homeserver (continuwuity)

Self-hosted Matrix homeserver on TrueNAS SCALE, exposed at
`https://matrix.wyattau.com` via the existing Cloudflare Tunnel. Phase 0 of
the Rust-ecosystem dogfooding plan: run stock upstream, learn its failure
modes, then fork and swap in our crates (`metrics-kit`, `outbox-kit`,
`worker-kit`, ...: see the fork at
`~/dev/src/github.com/continuwuity/continuwuity`).

```
Element/clients ──TLS──▶ Cloudflare ──▶ cloudflared (NAS) ──▶ continuwuity:8008
remote homeservers ──┘                    (existing tunnel)     └─ matrix-db volume
```

Client AND federation traffic both ride `:443` through the tunnel: nothing
listens on `:8448` anywhere. `CONTINUWUITY_WELL_KNOWN` in the compose file
handles the delegation.

## Files

| File | Purpose |
|---|---|
| `docker-compose.yml` | The stack. Pinned to `v26.9.1` (docker.io mirror of the primary forgejo.ellis.link registry) |
| `continuwuity-resolv.conf` | Real DNS resolvers in-container (Docker's embedded DNS breaks federation) |
| `cloudflared-ingress.yml` | Ingress snippet to merge into the existing tunnel + the no-Access-app warning |

## Server name (read before first start)

`CONTINUWUITY_SERVER_NAME` is **permanent**: changing it later wipes all
accounts, rooms, and federation identity. Current choice:

- `matrix.wyattau.com`: self-contained, no apex dependency. IDs look like
  `@wyatt:matrix.wyattau.com`.
- Alternative (only before first start): apex delegation gives
  `@wyatt:wyattau.com` but requires serving `/.well-known/matrix/*` from the
  apex domain and routing apex traffic through the tunnel. Not worth it
  unless you want the clean IDs.

## Deploy (SSH path)

1. **Copy files** to the NAS, e.g. `/mnt/tank/apps/matrix/`:
   ```bash
   ssh root@<nas> 'mkdir -p /mnt/tank/apps/matrix'
   scp truenas-matrix/{docker-compose.yml,continuwuity-resolv.conf,cloudflared-ingress.yml} \
       root@<nas>:/mnt/tank/apps/matrix/
   ```

2. **Tunnel ingress**: merge the rule from `cloudflared-ingress.yml` into
   the existing cloudflared config, route DNS, restart cloudflared. Do NOT
   add a Cloudflare Access app for this hostname (see the snippet's warning
  : an Access policy breaks clients and federation).

3. **First-run bootstrap**: one account, then close registration:
   ```bash
   cd /mnt/tank/apps/matrix
   sed -i 's/CONTINUWUITY_ALLOW_REGISTRATION: "false"/CONTINUWUITY_ALLOW_REGISTRATION: "true"/' docker-compose.yml
   docker compose up -d && sleep 5

   # Register via any client (e.g. app.element.io -> Change homeserver ->
   # matrix.wyattau.com). The FIRST registered user becomes server admin.

   sed -i 's/CONTINUWUITY_ALLOW_REGISTRATION: "true"/CONTINUWUITY_ALLOW_REGISTRATION: "false"/' docker-compose.yml
   docker compose up -d   # registration closed again
   ```

4. **Confirm closed**:
   ```bash
   curl -s -X POST https://matrix.wyattau.com/_matrix/client/v3/register \
        -d '{"username":"nope","password":"nope","auth":{"type":"m.login.dummy"}}'
   # expect M_FORBIDDEN / registration disabled, never a 200 with a token
   ```

## Verify

```bash
# 1. Stack local (on the NAS)
curl -s http://127.0.0.1:8008/_matrix/client/versions      # 200 + version list

# 2. Tunnel path (from anywhere)
curl -s https://matrix.wyattau.com/_matrix/client/versions  # 200 + version list

# 3. Well-known delegation
curl -s https://matrix.wyattau.com/.well-known/matrix/client
# {"m.homeserver":{"base_url":"https://matrix.wyattau.com"}}
curl -s https://matrix.wyattau.com/.well-known/matrix/server
# {"m.server":"matrix.wyattau.com:443"}

# 4. Federation inbound (remote servers hit :443 per the delegation)
curl -s https://matrix.wyattau.com/_matrix/federation/v1/version
# {"server":{"name":"continuwuity","version":"..."}}

# 5. End-to-end: log into app.element.io, join #matrix:matrix.org
```

If federation fails but local works: almost always DNS (step 0 of
troubleshooting: the resolv.conf mount) or the tunnel ingress missing.

## Optional: metrics into VictoriaMetrics

Stock upstream can expose Prometheus metrics (requires a build with the
`prometheus` feature: test it first):

```bash
curl -s http://127.0.0.1:8008/metrics | head    # if 404, feature not in image
```

The fork build additionally serves OpenMetrics at
`/metrics/openmetrics` (phase 1, `render_openmetrics()`), which is the
endpoint the metrics-kit dogfooding plugs into.

If it works, add to `/mnt/tank/apps/monitoring/vm-prometheus.yml` scrape
configs: `job_name: continuwuity`, `targets: ['<nas-lan-ip>:8008']`: wait,
port 8008 is bound to 127.0.0.1 only. Either scrape via the tunnel
(https, no Access app in the way) or add a second 127.0.0.1 bind; simplest
is letting the NAS-local vm-scrape job target `localhost:8008` since
VictoriaMetrics runs on the same box. This is where `metrics-kit`
dogfooding plugs in later (phase 1 of the fork plan).

## Rollback

```bash
cd /mnt/tank/apps/matrix && docker compose down   # stack off, data kept
```

Volume `matrix-db` persists across `down`. `down -v` only if starting over
 and remember a fresh start means the same `SERVER_NAME` (identity is the
name, not the data). Remove the ingress rule + DNS record to fully retire
the hostname.

## Phase plan: status (synced 2026-10-24)

- **Phase 0** (this runbook): ready to execute; blocked only on NAS SSH
  access (key provisioning).
- **Phase 1**: BUILT on branch `wyatt/dogfood-phase1` (metrics-kit
  OpenMetrics exposition + labelled gauge mirror; post-rebase commits
  `09bc084f`, `25466202`; originally cited as `989478b`/`4557c6a` —
  branch rebased 2026-11, hashes refreshed). Not yet in any image:
  swapping in requires building the image from that branch (below).
- **Phase 2**: RESEARCH-NO (2026-10, with receipt): the sending-queue
  swap was investigated and declined for now; `worker-kit`/`loop-retry`
  stay un-wired. Re-open only with a concrete failure mode the stock
  sender actually exhibits.
- **Phase 3**: BUILT on the same branch (webhookkit-signed admin
  notifications on local registrations, commit `4d9fe0d`; webhookkit
  pinned `=2.2.0` registry, the canonical signing API).

### Swapping in the fork (after phase 0 settles)

Build the image from the branch, pin the compose to it, and both
landings arrive together:

```bash
cd ~/dev/src/github.com/continuwuity/continuwuity
git checkout wyatt/dogfood-phase1
docker build -t ghcr.io/wyattau/continuwuity:dogfood-phase1 .
docker push ghcr.io/wyattau/continuwuity:dogfood-phase1
# then on the NAS: compose image line -> that ref, docker compose up -d
```

- Discipline unchanged: upstream-first PRs for anything generic (the
  OpenMetrics route issue is drafted in the fork's
  `UPSTREAM-ISSUE-openmetrics.md`, held for filing); rebase the fork
  regularly (currently 4 commits behind upstream, no conflicts on the
  touched surface); `complement/` test suite after every swap.

## INCIDENT 2026-11-20: DM room stuck extremities (OPEN)

The DM `!IEwsBK9qdYhPcm6QA668Ek9HAPIm9Mucc9LvPQltn3g` timeline tip froze
at ~5.7h before detection. Events accepted after that (txn 200s from
multiple sessions) detached from the tip — invisible to /sync and
/messages on every client. Suspected trigger: concurrent sends from
four peregrine sessions (tui, gui, listener, probe) forked the
extremity graph; `docker restart continuwuity` did not re-wedge it
(recomputed the same stuck state); admin surface has no extremity
repair. NAS clock verified NTP-clean (+0.001s). Other rooms (admin)
advance normally — room-scoped.

Detection recipe (works from any client token):
```
FROM=$(curl -s ".../rooms/$ENC/messages?dir=b&limit=1" -H "Auth..." | jq -r .end)
curl -s ".../messages?dir=f&from=$FROM&limit=50" -H "Auth..." | jq '.chunk | length'
# 0 chunks with recent sends outstanding == stuck tip
```

Options: (1) leave+recreate DM as workaround, (2) upstream continuuwuity
issue with the stuck event ids, (3) DB extremity surgery in matrix-db
(last resort). Peregrine-side: incident row in docs/ROADMAP.md.

### UPDATE 2026-11-21: data intact — tip view only

A client session with a PRE-FREEZE sync token (old `since`) streams all
post-freeze events via incremental sync — nothing was lost. Only
tip-based reads (fresh /sync bootstrap, /messages dir=b) serve the
frozen tip. Fresh sessions see lies; old sessions see truth. Workaround
room `!uqmTBOhb...` ("peregrine") created and verified end-to-end.
Upstream issue still worth filing (fresh clients can't see the room's
tail — that breaks any new device).
