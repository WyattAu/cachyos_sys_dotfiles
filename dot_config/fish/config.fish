# Only run on CachyOS, skip on WSL/Arch
if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

if status is-interactive
    # Set Default Editor to Neovim
    set -gx EDITOR nvim
    set -gx VISUAL nvim

    # Starship Prompt
    starship init fish | source

    # SSH / Keychain setup
    # Only use ksshaskpass if it exists (KDE systems)
    if test -f /usr/bin/ksshaskpass
        set -x SSH_ASKPASS /usr/bin/ksshaskpass
        set -x SSH_ASKPASS_REQUIRE force
    end

    # Keychain for SSH key management (only load existing keys)
    if type -q keychain
        set -l ssh_keys
        for key in id_ed25519 id_rsa id_forgejo id_ecdsa
            test -f ~/.ssh/$key && set -a ssh_keys $key
        end
        if test (count $ssh_keys) -gt 0
            keychain --eval --quiet $ssh_keys | source
        end
    end

    # WSL-specific settings
    if grep -qi microsoft /proc/version 2>/dev/null
        # Force WSLg libraries
        set -gx LD_LIBRARY_PATH /usr/lib/wsl/lib $LD_LIBRARY_PATH
        # Fix for some Mesa/LLVM errors
        set -gx MESA_LOADER_DRIVER_OVERRIDE zink
    end

    # Direnv
    if type -q direnv
        direnv hook fish | source
    end
    
    # Bun
    set -gx BUN_INSTALL "$HOME/.bun"
    fish_add_path "$BUN_INSTALL/bin"

    # PNPM
    set -gx PNPM_HOME "$HOME/.local/share/pnpm"
    fish_add_path "$PNPM_HOME"

    # Node Global Binaries (Fallback)
    fish_add_path "$HOME/.local/bin"
    
    # Aliases
    alias ls="eza --icons"
    alias cat="bat"
    alias update="sys-sync"
    alias save="sys-save"
    alias nuke="sudo pacman -Rns"
    alias cleanup="sudo pacman -Qtdq | sudo pacman -Rns -"
end
