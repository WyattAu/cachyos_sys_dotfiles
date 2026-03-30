# Only run on CachyOS, skip on WSL/Arch
if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

# --- GLOBAL PATHS (Available in all shells) ---
fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/.cargo/bin"
fish_add_path "$HOME/.elan/bin"
fish_add_path "$HOME/.opencode/bin"
fish_add_path "$HOME/.bun/bin"
set -gx PNPM_HOME "$HOME/.local/share/pnpm"
fish_add_path "$PNPM_HOME"

if status is-interactive
    # --- CORE ENVIRONMENT ---
    set -gx EDITOR nvim
    set -gx VISUAL nvim

    # Starship Prompt
    starship init fish | source

    # --- SSH / KEYCHAIN ---
    if test -f /usr/bin/ksshaskpass
        set -x SSH_ASKPASS /usr/bin/ksshaskpass
        set -x SSH_ASKPASS_REQUIRE force
    end

    if type -q keychain
        set -l ssh_keys
        for key in id_ed25519 id_rsa id_forgejo id_ecdsa
            test -f ~/.ssh/$key && set -a ssh_keys $key
        end
        if test (count $ssh_keys) -gt 0
            keychain --eval --quiet $ssh_keys | source
        end
    end

    # --- WSL FIXES ---
    if grep -qi microsoft /proc/version 2>/dev/null
        set -gx LD_LIBRARY_PATH /usr/lib/wsl/lib $LD_LIBRARY_PATH
        set -gx MESA_LOADER_DRIVER_OVERRIDE zink
    end

    # --- TOOLCHAIN INIT ---
    if type -q direnv
        direnv hook fish | source
    end
    
    # --- ALIASES ---
    alias ls="eza --icons"
    alias cat="bat"
    alias update="sys-sync"
    alias save="sys-save"
    alias nuke="sudo pacman -Rns"
    alias cleanup="sudo pacman -Qtdq | sudo pacman -Rns -"

    # ==========================================
    # GHQ + FZF WORKTREE WORKFLOW
    # ==========================================
    
    # 1. The Repo Jumper Function
    function __ghq_fzf_repo
        # Check if ghq is installed
        if not type -q ghq
            echo "ghq not found"
            return
        end

        set -l repo (ghq list | fzf --prompt="🐙 Repo > " --preview "eza -al --color=always --icons --group-directories-first (ghq root)/{}")
        if test -n "$repo"
            cd (ghq root)/$repo
            commandline -f repaint
        end
    end
    
    alias repo="__ghq_fzf_repo"

    # 2. The Git Worktree Automator
    function wt -d "Fuzzy find a branch and create/jump to a git worktree"
        if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
            echo "Not a git repository"
            return 1
        end

        set -l branch (git branch -a --format='%(refname:short)' | sed 's|^origin/||' | sort -u | fzf --prompt="🌿 Branch > ")
        
        if test -n "$branch"
            set -l worktree_dir "../$branch"
            if not test -d "$worktree_dir"
                git worktree add "$worktree_dir" "$branch"
            end
            cd "$worktree_dir"
        end
    end
end # End of if status is-interactive block

# ==========================================
# KEY BINDING OVERRIDE (THE NUCLEAR OPTION)
# ==========================================

function fish_user_key_bindings
    # Remove any existing binding for Ctrl+G
    bind -e \cg
    
    # Bind for Emacs mode (Default)
    bind \cg '__ghq_fzf_repo'
    
    # Bind for Vi mode (Insert and Default modes)
    # This is likely why yours was failing if you use Neovim/Vi bindings
    if bind -M insert >/dev/null 2>&1
        bind -M insert \cg '__ghq_fzf_repo'
        bind -M default \cg '__ghq_fzf_repo'
    end
end

# FORCE Fish to evaluate the bindings immediately
fish_user_key_bindings
