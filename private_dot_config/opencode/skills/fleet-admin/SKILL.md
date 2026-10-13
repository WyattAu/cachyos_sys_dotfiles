---
name: Fleet Admin
description: >
  Use when managing this machine fleet or the dotfiles repo: sys-sync /
  sys-check / sys-save workflows, Ansible host_vars layering, chezmoi
  config changes, TrueNAS, Headscale, Vault, monitoring, Docker stacks.
---

# Fleet Administration

This repo is infrastructure-as-code for an Arch/CachyOS/WSL fleet:
chezmoi (user-space configs) + Ansible (system provisioning).

## Hosts

| Hostname | Machine | Layers |
|----------|---------|--------|
| `wyattdeskacercachy` | Acer desktop | common → arch_native → cachyos → host |
| `msi-z16` | MSI Creator Z16 laptop | common → arch_native → cachyos → host |
| `msi-ge66` | MSI GE66 Raider laptop | common → arch_native → cachyos → host |
| `wsl-dev` | WSL2 (Arch) | common → host |

`cachyos-x8664` may appear as a generic CachyOS name — treat like a
native host. WSL excludes KDE/desktop roles via `.chezmoiignore.tmpl`.

## Workflows

- `sys-sync` — canonical full sync: snapper snapshot → `chezmoi update`
  → `ansible-playbook local.yml` (become) → `chezmoi apply --force` →
  KDE reload → smoke tests. `--dry-run` = `--check` + `chezmoi diff`.
- `sys-check` — hourly systemd timer + post-sync. Exit code = number of
  failed checks; Telegram alert on failure (token in
  `/etc/alertmanager/telegram-token`, never in the repo).
- `sys-save` — capture dotfile changes, commit, push.
- Quirk: scripts run **directly from the chezmoi source dir**
  (`~/.local/share/chezmoi/scripts/`) — `scripts/` files are not
  templated, so never put `{{ }}` in them.

## Ansible

- Playbook: `ansible/local.yml` (hosts: localhost, become). Roles run in
  order: packages → toolchains → opencode → directories → hardware →
  system → vault → monitoring → containers → performance.
- Variables layer in `host_vars/`: `common.yml` → `arch_native.yml` →
  `arch_only.yml` / `cachyos.yml` → `<hostname>.yml`. Add host packages
  to the right layer, not the playbook.
- AUR via `kewlfft.aur.aur` + paru, builds in `/var/tmp/aur_build`
  (temp swap via loop device on btrfs). Chaotic-AUR provides prebuilts.
- The role ends matter: `opencode` role asserts its own install; failed
  AUR packages are surfaced but ignored (one bad package must not kill
  a sync).

## Services & URLs

| Thing | Where |
|-------|-------|
| TrueNAS | `192.168.1.3` — central monitoring + infra stacks (`truenas/`) |
| Headscale | `https://headscale.wyattau.com` — authkey at `/etc/tailscale/headscale-authkey` or Vault `secret/vpn/tailscale`; enrollment timer retries until a key appears |
| Forgejo (git) | `ssh.wyattau.com` — origin for this repo |
| OCIS (ownCloud) | `https://ocis.wyattau.com`, sync root `~/ownCloud` |
| Vault | auto-unseal timer; scripts `vault-init.sh` (once), `vault-store.sh`, `vault-unseal.sh`, `vault-backup.sh` |
| Backups | snapper (pre-sys-sync + timeline) + `/mnt/truebackup` mount + pika-backup |
| Portainer | compose in `~/dev/docker`, image pinned in `ansible/files/portainer-compose.yml` |

## Rules

1. Never commit secrets. Tokens/keys live in Vault or root-owned files
   under `/etc` (telegram token, headscale authkey). If a change needs
   a secret, wire it through Vault or a 0600 file — never into YAML.
2. Package changes go in `host_vars` lists with a comment; AUR only
   when nothing official exists (`extra` > chaotic > AUR).
3. ProtonVPN killswitch stays on; don't weaken firewalld beyond the
   declared exceptions (KDE Connect 1714-1764).
4. After changing this repo: `sys-sync --dry-run` first on one host,
   then real `sys-sync`, then `sys-check` must exit 0 before pushing.
5. The Nix flake in `tests/` is for VM-level tests; day-to-day
   verification is `sys-check`.
