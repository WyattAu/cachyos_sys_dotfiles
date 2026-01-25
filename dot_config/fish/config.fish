source /usr/share/cachyos-fish-config/cachyos-config.fish

if type -q direnv
    direnv hook fish | source
end
# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end
