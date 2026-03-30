function __ghq_fzf_repo
    set -l repos (ghq list)
    if test -z "$repos"
        echo "No repos found. Run 'ghq get <url>' first."
        return
    end

    set -l repo (echo "$repos" | fzf --prompt="🐙 Repo > " --preview "eza -al --color=always --icons --group-directories-first (ghq root)/{}")
    if test -n "$repo"
        cd (ghq root)/$repo
        commandline -f repaint
    end
end
