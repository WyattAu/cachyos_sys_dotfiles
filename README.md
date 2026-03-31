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
│   ├── local.yml               # Main playbook (549 lines, 17 sections)
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
│   ├── ownCloud/owncloud.cfg  # OCIS sync client
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
| 15. Kernel Params | Deploy Limine drop-in with boot parameters | Native only |
| 16. Huge Pages | Pre-allocate 2MB huge pages | Native only |
| 17. Security Limits | File descriptor and memlock limits | Native only |

## Performance Tuning

### Kernel Boot Parameters (via Limine drop-in)

Applied after `sudo limine-update && sudo reboot`:

| Parameter | Purpose | Effect |
|-----------|---------|--------|
| `preempt=full` | Full kernel preemption | Lower scheduling latency |
| `nmi_watchdog=0` | Disable NMI watchdog | Frees perf counter |
| `tsc=reliable` | Trust TSC clocksource | Prevents clocksource switching |
| `processor.max_cstate=3` | Limit deep C-states | Reduces wake latency (~100μs → ~10μs) |
| `intel_idle.max_cstate=3` | Intel firmware C-state limit | Same as above |
| `mitigations=off` | Disable CPU mitigations | +5-30% IPC (trusted hardware only) |

Per-host values defined in each `<hostname>.yml` file. The MSI laptop uses `amdgpu.ppfeaturemask=0xffffffff` instead of Intel C-state controls.

### Sysctl Tuning (deployed to `/etc/sysctl.d/99-hft-tuning.conf`)

| Category | Parameter | Value (Desktop) | Value (Laptop) |
|----------|-----------|------------------|----------------|
| VM | `vm.swappiness` | 10 | 30 |
| VM | `vm.dirty_ratio` | 20 | 20 |
| VM | `vm.nr_hugepages` | 512 (1GB) | 256 (512MB) |
| Kernel | `perf_event_paranoid` | 0 | 0 |
| Kernel | `sched_autogroup_enabled` | 0 | 0 |
| Net | `net.core.busy_poll` | 50μs | 50μs |
| Net | `net.core.rmem_max` | 16MB | 16MB |
| Net | `net.ipv4.tcp_low_latency` | 1 | 1 |

### CPU Governor

| Host | Governor | Rationale |
|------|----------|------------|
| Acer Desktop | `performance` | All cores maxed. Gamemode overrides on-demand. |
| MSI Laptop | `ondemand` | Battery-friendly. Use `performance` when plugged in. |

### I/O Scheduler

All NVMe devices → `none` scheduler (no-op). Managed via udev rule.

### SCX Scheduler

`sched_ext` scheduler via `scx_loader --auto` (D-Bus on-demand). Auto-selects the best scheduler based on workload. Enabled on all native hosts.

### Huge Pages

Pre-allocated at boot via sysctl. Desktop: 512 pages (1GB), Laptop: 256 pages (512MB). Used for low-latency shared memory and memory-mapped data structures.

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
│   ├── work/          # Work / HFT related
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
| OCIS | Syncs to `ocis.wyattau.com` | `~/.config/ownCloud/owncloud.cfg` |

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
| Kernel params | Managed (Limine drop-in) | Windows controls kernel |
| Performance tuning | Full (sysctl, governor, SCX, hugepages) | None |
| Gaming stack | Full (Steam, Heroic, Lutris, RetroArch) | None |
| Desktop configs | KDE/Plasma, MangoHud, RetroArch | Excluded via `.chezmoiignore.tmpl` |
| Docker | Full (daemon + compose + Portainer) | Full (daemon + compose) |
| Nix | Installed (multi-user daemon) | Skipped |

## First-Time Setup (Fresh Machine)

```bash
# 1. Install OS and log in

# 2. Install git and clone repo
sudo pacman -S git
git clone https://github.com/WyattAu/cachyos_sys_dotfiles.git ~/.local/share/chezmoi

# 3. Bootstrap (installs packages, configs, performance tuning, containers)
sudo ~/.local/share/chezmoi/scripts/bootstrap.sh

# 4. Reboot (activates kernel params, huge pages, governor, SCX)
sudo limine-update
sudo reboot

# 5. One-time app setup (post-reboot)
owncloudclient  # Connect to ocis.wyattau.com, configure sync folders
books            # Calibre → set library path to ~/Library/Books
zotero           # Set data dir to ~/Library/Papers
heroic           # Connect Epic + GOG accounts
```

Steps 1-4 take ~10 minutes. Step 5 takes ~15 minutes. After that, the system is fully configured.

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
| New host | Create `<hostname>.yml` in `host_vars/` → `sys-sync` | Host vars |
| New sysctl | Add to `sysctl_tuning` in host vars → `sys-sync` | `/etc/sysctl.d/` |
| New boot param | Add to `kernel_params` in host vars → `limine-update && reboot` | `/boot/limine.conf` |

## Adding a New Machine

```bash
# 1. Install OS
# 2. git clone repo to ~/.local/share/chezmoi
# 3. sudo bootstrap.sh
# 4. Done — everything replicated automatically
```

If the new machine needs custom hardware or tuning, create a new `<hostname>.yml` in `ansible/host_vars/` before running `bootstrap.sh`.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `sys-sync` fails with Ansible errors | Check that `bootstrap.sh` installed required collections (`community.general`, `kewlfft.aur`, `community.docker`) |
| Performance tuning not applied after reboot | Run `sudo limine-update` then reboot — kernel params only apply after bootloader update |
| `sys-sync` alias not found | The alias is defined in Fish's interactive block. Use `/home/<user>/.local/share/chezmoi/scripts/sys-sync` directly, or open a new Fish shell |
| Portainer not starting | Check `docker ps -a` — the compose file is at `~/dev/docker/portainer-compose.yml` |
| Steam games not at `~/Games/Steam/` | The symlink is created on first Fish launch. Run `fish` then check `ls ~/Games/Steam` |
| OCIS sync not working | Run `owncloudclient` → add account → `ocis.wyattau.com` → configure folder pairs |

## Repository

- **Remote:** `https://github.com/WyattAu/cachyos_sys_dotfiles.git`
- **Branch:** `master`
- **License:** Personal (no LICENSE file — add one if publishing)
