# CachyOS / Arch Multi-Device Dotfiles

Personal infrastructure-as-code for a multi-device Arch/CachyOS/WSL environment. Managed by **[chezmoi](https://www.chezmoi.io/) (user-space configs) and **[Ansible](https://www.ansible.com/)** (system provisioning).

## Quick Reference

| Command | What It Does |
|--------|--------------|
| `sys-sync` | Pulls repo changes, reinstalls packages, applies configs, reloads KDE. Run after any infra change. |
| `save` | Captures dotfile changes, commits, pushes to GitHub. |
| `bootstrap.sh` | Full system bootstrap from scratch. Run with `sudo`. |
| `sys-save` | Legacy alias for `save`. |

## Supported Hosts

| Hostname | Machine | OS | Layers Loaded |
|----------|--------|----|---------------|
| `wyattdeskacercachy` | Acer Desktop | CachyOS | common → arch_native → cachyos → host |
| `msi-z16` | MSI Creator Z16 Laptop | Arch | common → arch_native → arch_only → host |
| `wsl-dev` | WSL2 Development | WSL (Arch) | common → host |

## Architecture

```
chezmoi/                          # Repo root (~/.local/share/chezmoi)
├── ansible/                      # System provisioning (run as root via bootstrap.sh)
│   ├── local.yml               # Main playbook (~620 lines, 17 sections)
│   ├── ansible.cfg            # Ansible settings
│   ├── files/                  # Static files deployed by Ansible
│   │   └── portainer-compose.yml
│   ├── templates/             # Jinja2 templates for system configs
│   │   ├── 99-hft-tuning.conf.j2    → /etc/sysctl.d/       (sysctl tuning)
│   │   ├── 99-hft-kernel.conf      → /etc/limine-entry-tool.d/ (kernel params)
│   │   ├── 99-perf-limits.conf     → /etc/security/limits.d/ (fd limits)
│   │   ├── cpupower.conf.j2         → /etc/default/cpupower-service.conf (CPU governor)
│   │   └── 60-nvme-scheduler.rules → /etc/udev/rules.d/      (NVMe scheduler)
│   └── host_vars/              # Variable layers (merged at runtime)
│       ├── common.yml           # ALL systems (WSL + Native)
│       ├── arch_native.yml      # All bare-metal Linux (Arch + CachyOS)
│       ├── arch_only.yml       # Vanilla Arch only (conflicts with CachyOS)
│       ├── cachyos.yml         # CachyOS-specific additions
│       ├── msi-z16.yml         # MSI laptop overrides
│       ├── wyattdeskacercachy.yml  # Acer desktop overrides
│       └── wsl-dev.yml        # WSL overrides
│
├── scripts/                     # Management scripts
│   ├── bootstrap.sh            # Full system bootstrap (sudo wrapper for ansible)
│   ├── sys-sync               # Pull + provision + apply + KDE reload
│   └── sys-save               # Capture changes + commit + push
│
├── private_dot_config/          # User-space configs (deployed by chezmoi)
│   ├── fish/                  # Shell (primary)
│   │   ├── config.fish
│   │   └── functions/__ghq_fzf_repo.fish
│   ├── kitty/                 # Terminal
│   │   └── kitty.conf.tmpl
│   ├── nvim/                  # Editor
│   │   └── init.lua
│   ├── starship.toml          # Prompt
│   ├── gitconfig.tmpl         # Git credentials (templated per-host)
│   ├── editorconfig           # Cross-editor formatting
│   ├── clangd/config.yaml    # C/C++ LSP settings
│   ├── gdb/gdbinit            # Debugger config
│   ├── direnv/direnv.toml.tmpl  # Environment manager
│   ├── MangoHud/             # Gaming performance overlay
│   ├── retroarch/retroarch.cfg # Emulation frontend
│   ├── heroic/config.json.tmpl  # Epic/GOG launcher
│   ├── lutris/system.yml.tmpl   # Game launcher
│   ├── protonvpn/README.md.tmpl # VPN preference reference (templated)
│   └── electron-flags.conf.tmpl, element-desktop-flags.conf.tmpl,
│       signal-desktop-flags.conf.tmpl, whatsapp-for-linux-flags.conf.tmpl  # Wayland
│
├── .chezmoidata/defaults.toml  # Chezmoi template variables
├── .chezmoiignore.tmpl       # Platform-conditional exclusions
├── .gitignore                # Git ignore rules
└── dot_editorconfig          # Cross-editor formatting rules
```

## Variable Loading Order

The playbook loads host variables in this order. Later layers override earlier ones:

```
common.yml ─────┐
arch_native.yml ───┤
cachyos.yml ─────┤  Merged package/service/config lists
arch_only.yml ───┤
<hostname>.yml ───┘
```

- **WSL:** Loads `common.yml` + `<hostname>.yml` only. All native/cachyos/arch-only layers skipped.
- **CachyOS native:** Loads `common.yml` + `arch_native.yml` + `cachyos.yml` + `<hostname>.yml`. Arch-only layer skipped.
- **Arch native:** Loads `common.yml` + `arch_native.yml` + `arch_only.yml` + `<hostname>.yml`. CachyOS layer skipped.

Detection is automatic: WSL via kernel string, CachyOS via `ID=cachyos` in `/etc/os-release`.

## Playbook Sections

The playbook (`local.yml`) runs in this order:

| Section | What | Conditional |
|--------|------|-----------|
| 1. Environment Detection | Identify WSL, CachyOS, hostname | Always |
| 2. Variable Loading | Merge 4 layers of host_vars | All layers |
| 3. Auto-Update Timer | systemd timer for daily `sys-sync` | Native only |
| 4. Privilege & Updates | sudoers, pacman update, AUR upgrade | Always |
| 5. Package Installation | Merge all layer package lists, install | All layers |
| 6. Management Scripts | Ensure scripts are executable | Always |
| 7. Toolchains | Rust (rustup), Lean 4 (elan), Nix (multi-user) | All/Nix |
| 8. Directory Structure | Create `~/dev/` and `~/personal_structure` | Always |
| 9. Hardware Fixes | MSI audio fix (msi-z16 only) | Per-host |
| 10. System Config | Groups, services, PipeWire audio | Native only |
| 10b. Container Infra | Portainer via docker compose | Native only |
| 11. Sysctl Tuning | VM, kernel, network performance parameters | Native only |
| 12. CPU Governor | Set frequency governor via cpupower | Native only |
| 13. SCX Scheduler | Enable sched_ext scheduler loader | Native only |
| 14. NVMe Scheduler | Set `none` scheduler for NVMe via udev | Native only |
| 15. Kernel Params | Deploy boot parameters (Limine on CachyOS, GRUB on Arch) | Native only |
| 16. Huge Pages | Pre-allocate 2MB huge pages (if configured per-host) | Native only |
| 17. Security Limits | File descriptor and memlock limits | Native only |

## Performance Tuning

### Kernel Boot Parameters

Per-host values defined in each `<hostname>.yml` file. CachyOS uses Limine drop-ins (auto-updated via `limine-update`). Vanilla Arch uses GRUB (`/etc/default/grub`, auto-updated via `grub-mkconfig`).

| Host | Parameters | Purpose |
|------|-----------|---------|
| Acer Desktop (CachyOS) | `mitigations=off` | +5-30% IPC (personal box, not internet-facing) |
| MSI Laptop (Arch) | `amdgpu.ppfeaturemask=0xffffffff`, `ibt=off` | Unlock AMD GPU overclocking, disable IBT for gaming perf |

All other CachyOS defaults are optimal — no additional sysctl tuning or CPU governor overrides needed. `power-profiles-daemon` manages CPU frequency (balanced = powersave governor, allows turbo boost).

### Sysctl Tuning

The playbook deploys `/etc/sysctl.d/99-hft-tuning.conf` on every run (even if empty, to clear stale values from previous configs). Per-host values are defined in `sysctl_tuning` in each `<hostname>.yml`.

### I/O Scheduler

All NVMe devices → `none` scheduler (no-op). Managed via udev rule.

### SCX Scheduler

`sched_ext` scheduler via `scx_loader --auto` (D-Bus on-demand). Auto-selects the best scheduler based on workload. Enabled on all native hosts.

## Directory Structure

The playbook creates two directory trees:

### Development (`~/dev/`)

```
~/dev/
├── src/          # GHQ root (all repos cloned here)
├── build/        # Build artifacts
├── sandbox/      # Experiments / spikes
├── scripts/      # Personal scripts
├── benchmarks/   # Performance benchmarks
└── docker/       # Docker compose files (Portainer, etc.)
```

### Personal (`~/personal_structure` in host_vars)

```
~/
├── Documents/
│   ├── work/          # Work projects
│   ├── notes/         # Notes, markdown
│   ├── pdfs/          # Papers, manuals, whitepapers
│   ├── receipts/      # Purchase records, invoices
│   └── contracts/      # Legal, employment, NDAs
├── Media/
│   ├── Movies/        # Films
│   ├── TV/            # TV series
│   ├── Anime/         # Anime series
│   ├── Music/         # Music library
│   ├── Audiobooks/    # Audiobooks
│   └── Podcasts/      # Podcast downloads
├── Library/
│   ├── Books/         # Calibre library
│   ├── Papers/        # Zotero storage
│   └── Audiobooks/    # Calibre audiobooks
├── Games/
│   ├── Steam/         # → symlink to ~/.local/share/Steam
│   ├── heroic/        # Epic + GOG (Heroic launcher)
│   ├── lutris/        # Lutris games
│   ├── Emulation/     # ROMs, BIOS files
│   │   └── Saves/
│   ├── Saves/         # PC game save backups
│   ├── Mods/          # Mod archives
│   └── Screenshots/    # In-game screenshots
├── Downloads/
├── Screenshots/
├── Recordings/
└── Inbox/              # Temporary landing zone
```

## Gaming Stack

| Launcher | Install Path | Config |
|----------|-------------|--------|
| Steam | `~/Games/Steam/` (symlink to `~/.local/share/Steam/`) | Built-in |
| Heroic (Epic + GOG) | `~/Games/heroic/` | `~/.config/heroic/config.json.tmpl` |
| Lutris | `~/Games/lutris/` | `~/.config/lutris/system.yml.tmpl` |
| RetroArch | `~/Games/Emulation/` | `~/.config/retroarch/retroarch.cfg` |
| MangoHud | Overlay (all games) | `~/.config/MangoHud/MangoHud.conf.tmpl` |

**How to install a game:** Open the appropriate launcher → install. The game lands in the correct directory automatically. No manual path configuration needed.

## Library & Reference Stack

| Tool | Data Path | Config |
|------|-----------|--------|
| Calibre | `~/Library/Books/` | First launch: `books` → set library path |
| Zotero | `~/Library/Papers/` | First launch: `zotero` → set data directory |
| OCIS | Syncs to `ocis.wyattau.com` | `~/.config/ownCloud/owncloud.cfg` (runtime — not managed by chezmoi) |

**How to add a book:** Drop PDF → `books` → add to Calibre → OCIS syncs to server.
**How to add a paper:** Download PDF → `zotero` → import → OCIS syncs to server.

## Docker & Containers

- **Docker** + **docker compose v2** installed via `common_packages` (all hosts).
- **Portainer** deployed as container at `~/dev/docker/portainer-compose.yml`.
- Access: `https://localhost:9443` after first `sys-sync`.
- Additional compose files go in `~/dev/docker/`.

## Container Infrastructure

| Service | File | Access |
|---------|------|--------|
| Portainer | `~/dev/docker/portainer-compose.yml` | `https://localhost:9443` |

## Toolchains

| Tool | Install Method | First-Run Detection |
|------|--------------|---------------------|
| Rust | `rustup default stable` | `~/.cargo/bin/cargo` exists |
| Lean 4 | `elan-init.sh -y` | `~/.elan/bin/lean` exists |
| Nix | Official multi-user installer | `/nix/store` exists |

All three are installed by the playbook as the actual user (not root), with idempotency guards — they only install once.

## VPN (ProtonVPN)

ProtonVPN is installed on all native Linux hosts (excluded on WSL). The stack includes:

| Component | Package | Source | Purpose |
|-----------|---------|--------|---------|
| CLI | `proton-vpn-cli` | Official repos | Core VPN control (connect, disconnect, server lists) |
| Daemon | `proton-vpn-daemon` | Official repos | System service, manages split tunneling |
| GUI | `proton-vpn-qt-app` | AUR | Qt frontend, KDE-native dark theme, system tray |
| Keyring | `gnome-keyring` | Official repos | Credential storage (works with KWallet) |

**Default settings** (from `.chezmoidata/defaults.toml`):

| Setting | Default | Description |
|---------|---------|-------------|
| Protocol | WireGuard | Faster, modern protocol |
| Kill Switch | On | Blocks all traffic if VPN drops |
| Split Tunneling | On | Only specified apps route through VPN (toggleable in GUI) |
| DNS | On | ProtonVPN DNS with NetShield ad-blocker |
| Auto-Connect | Off | Manual connection on launch |
| Secure Core | Off | Route through privacy-friendly countries (slower) |

**Split tunneling** is enabled by default but can be toggled off in the GUI at any time. When on, only apps you explicitly add go through the VPN — useful for keeping gaming traffic direct while routing browsers through the VPN.

### First-Run Setup

1. Open `proton_vpn_qt` from the application menu
2. Sign in with your Proton account (interactive, stored in keyring)
3. Configure split tunneling apps if desired (Settings → Split Tunneling)
4. All other settings match the defaults above — adjust in the GUI as needed

### CLI Usage

```bash
protonvpn c            # Connect to fastest server
protonvpn c -p wireguard  # Connect with specific protocol
protonvpn c US         # Connect to specific country
protonvpn d            # Disconnect
protonvpn s            # Show status
```

### Per-Host VPN Overrides

Add to `~/.config/chezmoi/chezmoi.toml` on any machine:

```toml
vpn_protocol = "openvpn"
vpn_split_tunneling = false
```

## Shell Setup

**Primary shell:** Fish (`~/.config/fish/config.fish`)

Key bindings:
- `Ctrl+G` — Fuzzy-find a GHQ repo and `cd` into it

Key aliases:
| Alias | Command |
|-------|---------|
| `update` / `sys-sync` | Full system sync |
| `save` | Commit and push dotfile changes |
| `books` | Open Calibre with correct library |
| `zotero` | Open Zotero |
| `heroic` | Open Heroic Games Launcher |
| `lutris` | Open Lutris |
| `dc` | `docker compose` |
| `dps` | `docker ps` |
| `repo` | GHQ fuzzy repo finder |

## Platform Differences (WSL vs Native)

| Feature | Native (Arch/CachyOS) | WSL |
|--------|--------------------------|-----|
| Kernel params | Managed (Limine on CachyOS, GRUB on Arch) | Windows controls kernel |
| Performance tuning | Kernel params, SCX scheduler | None |
| Gaming stack | Full (Steam, Heroic, Lutris, RetroArch) | None |
| Desktop configs | KDE/Plasma, MangoHud, RetroArch | Excluded via `.chezmoiignore.tmpl` |
| Docker | Full (daemon + compose + Portainer) | Full (daemon + compose) |
| VPN (ProtonVPN) | Full (CLI + GUI + daemon) | None |
| Nix | Installed (multi-user daemon) | Skipped |

## First-Time Setup (Fresh Machine)

```bash
# 1. Install Arch (or CachyOS), create user, log in

# 2. One-liner bootstrap (installs git, ansible, paru, clones repo, provisions system)
curl -sSf https://raw.githubusercontent.com/WyattAu/cachyos_sys_dotfiles/master/scripts/bootstrap.sh | sudo bash

# 3. Reboot (activates kernel params if any are configured for this host)
sudo reboot

# 4. Add SSH public key to GitHub and TrueNAS (if bootstrap generated a new key)
cat ~/.ssh/id_ed25519.pub

# 5. One-time app setup (post-reboot)
owncloudclient  # Connect to ocis.wyattau.com, configure sync folders
books            # Calibre → set library path to ~/Library/Books
zotero           # Set data dir to ~/Library/Papers
heroic           # Connect Epic + GOG accounts
proton_vpn_qt    # Sign in with Proton account, configure split tunneling
```

Steps 1-2 take ~10 minutes. Step 3-4 are one-time. Step 5 takes ~15 minutes. After that, the system is fully configured.

**What the bootstrap does automatically:**
- Installs `git`, `ansible`, `base-devel` (if missing)
- Installs `paru` AUR helper from source (if missing)
- Clones this repo to `~/.local/share/chezmoi/` (if missing)
- Generates an ed25519 SSH key (if missing)
- Installs Ansible collections (`community.general`, `kewlfft.aur`, `community.docker`)
- Runs the full playbook (packages, toolchains, directories, configs, services, containers)
- Applies all chezmoi dotfiles (shell, editor, terminal, gaming, desktop configs)

## Daily Operations

```bash
sys-sync    # Pull changes, reinstall packages, apply configs, reload KDE
save        # Capture dotfile changes, commit, push to GitHub
```

`sys-sync` runs automatically via systemd timer: 15 minutes after boot, then daily.

## Adding New Content

| Content | Action | Location |
|---------|--------|----------|
| New game | Open launcher → install | Launcher manages path |
| New book | Drop PDF → `books` → add to Calibre | `~/Library/Books/` |
| New paper | Download PDF → `zotero` → import | `~/Library/Papers/` |
| New ROM | Drop in `~/Games/Emulation/` | RetroArch finds it |
| New movie | Drop in `~/Media/Movies/` | OCIS syncs |
| New app (CLI) | Add to `common_packages` or `native_packages` → `sys-sync` | System package |
| New app (GUI) | Add to `native_aur_pkgs` → `sys-sync` | AUR package |
| New app (system) | Add to `native_packages` → `sys-sync` | System package |
| VPN settings | Edit `.chezmoidata/defaults.toml` → `chezmoi apply` | `~/.config/protonvpn/` |
| New host | Create `<hostname>.yml` in `host_vars/` → `sys-sync` | Host vars |
| New sysctl | Add to `sysctl_tuning` in host vars → `sys-sync` | `/etc/sysctl.d/` |
| New boot param | Add to `kernel_params` in host vars → `sys-sync` (GRUB updates automatically) | `/etc/default/grub` or `/boot/limine.conf` |

## Adding a New Machine

```bash
# 1. Install Arch (or CachyOS), create user, log in
# 2. curl -sSf https://raw.githubusercontent.com/WyattAu/cachyos_sys_dotfiles/master/scripts/bootstrap.sh | sudo bash
# 3. Reboot. Done — everything provisioned automatically.
```

If the new machine needs custom hardware or tuning, create a new `<hostname>.yml` in `ansible/host_vars/` and set the hostname (`hostnamectl set-hostname <name>`) before running the bootstrap.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `sys-sync` fails with Ansible errors | Check that `bootstrap.sh` installed required collections (`community.general`, `kewlfft.aur`, `community.docker`) |
| Performance tuning not applied after reboot | CachyOS: run `sudo limine-update` then reboot. Arch: kernel params are set via GRUB automatically. |
| `sys-sync` alias not found | The alias is defined in Fish's interactive block. Use `/home/<user>/.local/share/chezmoi/scripts/sys-sync` directly, or open a new Fish shell |
| Portainer not starting | Check `docker ps -a` — the compose file is at `~/dev/docker/portainer-compose.yml` |
| Steam games not at `~/Games/Steam/` | The symlink is created on first Fish launch. Run `fish` then check `ls ~/Games/Steam` |
| OCIS sync not working | Run `owncloudclient` → add account → `ocis.wyattau.com` → configure folder pairs |
| ProtonVPN won't connect | Ensure `gnome-keyring` is running; check `protonvpn s` for status; verify `NetworkManager` is active |

## Repository

- **Remote:** `https://github.com/WyattAu/cachyos_sys_dotfiles.git`
- **Branch:** `master`
- **License:** Personal (no LICENSE file — add one if publishing)
