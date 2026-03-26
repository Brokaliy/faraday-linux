# =============================================================================
# Faraday Linux — Fish shell configuration
# Deployed to ~/.config/fish/config.fish via home-manager
# =============================================================================

# Only configure for interactive sessions
if not status is-interactive
    exit
end

# =============================================================================
# PRIVACY — NO SHELL HISTORY
# Fish stores history in ~/.local/share/fish/fish_history
# We route it to /dev/null and clear any existing history
# =============================================================================
set -g fish_history ""          # Disable in-memory history
builtin history clear 2>/dev/null

# Also prevent fish from writing the history file by setting the path to /dev/null
# (Fish doesn't support HISTFILE env like bash, so we use the config var)
set -g fish_history_file /dev/null

# =============================================================================
# ENVIRONMENT
# =============================================================================
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx BROWSER firefox
set -gx PAGER "bat --paging=always"
set -gx STARSHIP_CONFIG /etc/faraday/starship.toml

# Tor SOCKS5 proxy for CLI tools
set -gx ALL_PROXY   "socks5://127.0.0.1:9050"
set -gx HTTPS_PROXY "socks5://127.0.0.1:9050"
set -gx HTTP_PROXY  "socks5://127.0.0.1:9050"
set -gx NO_PROXY    "localhost,127.0.0.1,::1"

# Remove fish greeting — fastfetch handles the welcome
set -g fish_greeting ""

# =============================================================================
# ALIASES
# =============================================================================

# --- File navigation ---
alias ls   'eza --icons --group-directories-first'
alias ll   'eza -la --icons --git --group-directories-first'
alias la   'eza -a --icons --group-directories-first'
alias lt   'eza --tree --icons --level=2'
alias l    'eza -l --icons'

# --- Better defaults ---
alias cat  'bat --theme=base16'
alias grep 'grep --color=auto'
alias cls  'clear'
alias ..   'cd ..'
alias ...  'cd ../..'

# --- NixOS system management ---
alias update       'sudo nixos-rebuild switch --flake /etc/nixos#faraday'
alias update-test  'sudo nixos-rebuild test --flake /etc/nixos#faraday'
alias nix-clean    'sudo nix-collect-garbage -d; and sudo nix store optimise'
alias nix-gen      'sudo nix-env --list-generations --profile /nix/var/nix/profiles/system'
alias nix-rollback 'sudo nixos-rebuild switch --rollback'

# --- Faraday / privacy tools ---
alias tor-status   'systemctl status tor'
alias tor-restart  'sudo systemctl restart tor'
alias vpn-status   'mullvad status'
alias vpn-on       'mullvad connect'
alias vpn-off      'mullvad disconnect'
alias myip         'torify curl -s https://api.ipify.org; and echo'
alias check-tor    'torify curl -s https://check.torproject.org/api/ip | jq .'
alias mac-show     'ip link show | grep "link/ether"'

# --- Safety ---
alias rm 'rm -i'
alias cp 'cp -i'
alias mv 'mv -i'

# --- Git (torified) ---
alias git 'torify git'

# =============================================================================
# FUNCTIONS
# =============================================================================

# Quick note to RAM-only tmpfs (erased on reboot)
function note --description "Write a quick note to tmpfs (no disk persistence)"
    set notefile "/tmp/faraday-note-"(date +%s)
    eval $EDITOR $notefile
    echo "[note saved to $notefile — erased on reboot]"
end

# Encrypt a file with age
function encrypt --description "Encrypt a file with age"
    if test -z "$argv[1]"
        echo "Usage: encrypt <file> [recipient-pubkey]"
        return 1
    end
    set out "$argv[1].age"
    if test -n "$argv[2]"
        age -r $argv[2] -o $out $argv[1] && echo "Encrypted → $out"
    else
        age -p -o $out $argv[1] && echo "Encrypted → $out (passphrase)"
    end
end

# Wipe a file securely
function wipe --description "Securely shred and delete a file"
    if test -z "$argv[1]"
        echo "Usage: wipe <file>"
        return 1
    end
    shred -vzu -n 3 $argv[1] && echo "Wiped: $argv[1]"
end

# Strip metadata from a file
function scrub --description "Strip metadata from a file using mat2"
    if test -z "$argv[1]"
        echo "Usage: scrub <file>"
        return 1
    end
    mat2 --inplace $argv[1] && echo "Metadata stripped: $argv[1]"
end

# Override cd to show directory contents after navigating
function cd --description "cd + auto-ls"
    builtin cd $argv
    and eza --icons --group-directories-first
end

# =============================================================================
# FASTFETCH — run on every new interactive session
# =============================================================================
if command -v fastfetch &>/dev/null
    fastfetch --config /etc/faraday/fastfetch.jsonc
end

# =============================================================================
# STARSHIP PROMPT — must be last
# =============================================================================
if command -v starship &>/dev/null
    starship init fish | source
end
