source /usr/share/cachyos-fish-config/cachyos-config.fish
if status is-interactive
    # ... existing starship init ...

    # 1. Set up graphical password prompt (KDE Wallet)
    set -x SSH_ASKPASS /usr/bin/ksshaskpass
    set -x SSH_ASKPASS_REQUIRE force  # Forces the GUI prompt

    # 2. Initialize Keychain
    # --quiet: Don't spam terminal on open
    # --agents ssh: We only care about SSH, not GPG
    # List your keys here (id_forgejo, id_ed25519)
    if type -q keychain
        keychain --eval --quiet --agents ssh id_forgejo id_ed25519 | source
    end
enD
if type -q direnv
    direnv hook fish | source
end
# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end
# "Nuke" a package: Removes package + unused dependencies + config files
alias nuke="sudo pacman -Rns"

# Clean up "Orphans" (Dependencies left behind by other uninstalls)
alias cleanup="sudo pacman -Qtdq | sudo pacman -Rns -"
