source /usr/share/cachyos-fish-config/cachyos-config.fish

if status is-interactive
    # 1. Starship Prompt
    starship init fish | source

    # 2. SSH / Keychain setup (KDE Wallet Integration)
    set -x SSH_ASKPASS /usr/bin/ksshaskpass
    set -x SSH_ASKPASS_REQUIRE force  # Forces the GUI prompt

    if type -q keychain
        # Load your specific keys here
        keychain --eval --quiet id_forgejo id_ed25519 | source
    end

    # 3. Direnv (Dev Tools)
    if type -q direnv
        direnv hook fish | source
    end

    # 4. Aliases
    alias ls="eza --icons"
    alias cat="bat"
    alias update="sys-sync"
    alias save="sys-save"
    
    # Maintenance Aliases
    alias nuke="sudo pacman -Rns"
    alias cleanup="sudo pacman -Qtdq | sudo pacman -Rns -"
end
