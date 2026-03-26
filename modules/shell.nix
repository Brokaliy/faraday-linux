{ config, pkgs, lib, ... }:

# =============================================================================
# FARADAY SHELL MODULE
# Deploys the complete terminal environment:
#   - Bash + Fish configured with no-history policy
#   - Fastfetch (ASCII cage logo + Tor/VPN/DNS status)
#   - Starship prompt (Faraday cyan theme)
#   - All config files deployed to /etc/faraday/ so they survive nixos-rebuild
#   - home-manager wires ~/.config symlinks for the default user
# =============================================================================

{
  # ---------------------------------------------------------------------------
  # PACKAGES
  # Shell tools, fonts, icon theme, cursor
  # ---------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    # Shells
    fish
    bash

    # Prompt
    starship

    # System info
    fastfetch

    # Better CLI tools (aliased in bashrc / config.fish)
    eza          # Better ls
    bat          # Better cat (syntax highlighting)
    fd           # Better find
    ripgrep      # Better grep
    jq           # JSON processor
    age          # Modern file encryption
    mat2         # Metadata stripping
    shred        # Secure file deletion (coreutils)

    # Fonts — Nerd Fonts for icons in starship, fastfetch, eza
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code

    # Icons + cursor (system-wide GTK/Qt defaults)
    papirus-icon-theme   # Icon theme: Papirus-Dark
    bibata-cursors       # Cursor: Bibata-Modern-Ice
  ];

  # ---------------------------------------------------------------------------
  # FONTS — declare to fontconfig
  # ---------------------------------------------------------------------------
  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      inter
      noto-fonts
      noto-fonts-emoji
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font Mono" "JetBrainsMono Nerd Font" ];
        sansSerif = [ "Inter" "Noto Sans" ];
        serif     = [ "Noto Serif" ];
        emoji     = [ "Noto Color Emoji" ];
      };
      # Enable LCD subpixel anti-aliasing
      subpixel.rgba = "rgb";
      hinting = {
        enable = true;
        style  = "slight";
      };
    };
  };

  # ---------------------------------------------------------------------------
  # ICON THEME & CURSOR — system-wide defaults via gsettings
  # Hyprland/GTK apps pick these up automatically.
  # ---------------------------------------------------------------------------
  environment.etc."gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-icon-theme-name  = Papirus-Dark
    gtk-cursor-theme-name = Bibata-Modern-Ice
    gtk-cursor-theme-size = 24
    gtk-theme-name        = adw-gtk3-dark
    gtk-application-prefer-dark-theme = true
    gtk-font-name         = Inter 11
  '';

  environment.etc."gtk-4.0/settings.ini".text = ''
    [Settings]
    gtk-icon-theme-name  = Papirus-Dark
    gtk-cursor-theme-name = Bibata-Modern-Ice
    gtk-cursor-theme-size = 24
    gtk-application-prefer-dark-theme = true
    gtk-font-name         = Inter 11
  '';

  # XDG cursor spec — picked up by Wayland compositors
  environment.etc."X11/cursors/default".source = "${pkgs.bibata-cursors}/share/icons/Bibata-Modern-Ice";

  # ---------------------------------------------------------------------------
  # DEPLOY CONFIGS TO /etc/faraday/
  # These paths are permanent — survive nixos-rebuild, present for all users.
  # home-manager symlinks them into ~/.config/ for the default user.
  # ---------------------------------------------------------------------------
  environment.etc = {
    # Fastfetch ASCII logo
    "faraday/fastfetch-logo.txt" = {
      source = ../assets/shell/faraday-logo.txt;
      mode   = "0444";
    };

    # Fastfetch config (references the logo at /etc/faraday/fastfetch-logo.txt)
    "faraday/fastfetch.jsonc" = {
      source = ../assets/shell/fastfetch.jsonc;
      mode   = "0444";
    };

    # Starship prompt config
    "faraday/starship.toml" = {
      source = ../assets/shell/starship.toml;
      mode   = "0444";
    };

    # Bash config (sourced by programs.bash.interactiveShellInit below)
    "faraday/bashrc" = {
      source = ../assets/shell/bashrc;
      mode   = "0444";
    };

    # Fish config (sourced by programs.fish.interactiveShellInit below)
    "faraday/config.fish" = {
      source = ../assets/shell/config.fish;
      mode   = "0444";
    };

    # Kitty config
    "faraday/kitty.conf" = {
      source = ../assets/kitty/kitty.conf;
      mode   = "0444";
    };
  };

  # ---------------------------------------------------------------------------
  # BASH — system-wide interactive config
  # Sources /etc/faraday/bashrc for every interactive bash session.
  # Also enforces no-history policy at the system level so even if a user
  # doesn't have our bashrc, they still don't get history files.
  # ---------------------------------------------------------------------------
  programs.bash = {
    enable = true;
    # System-wide no-history enforcement (before user configs run)
    shellInit = ''
      # Faraday: disable bash history system-wide
      unset HISTFILE
      export HISTSIZE=0
      export HISTFILESIZE=0
      export HISTFILE=/dev/null
    '';
    # Source our full Faraday bashrc for interactive sessions
    interactiveShellInit = ''
      if [ -f /etc/faraday/bashrc ]; then
        source /etc/faraday/bashrc
      fi
    '';
  };

  # ---------------------------------------------------------------------------
  # FISH — optional shell, same privacy + alias config
  # ---------------------------------------------------------------------------
  programs.fish = {
    enable = true;
    # System-wide fish vendor config sourced before user config
    vendor.config.enable = true;
    # Source our Faraday fish config
    interactiveShellInit = ''
      if test -f /etc/faraday/config.fish
          source /etc/faraday/config.fish
      end
    '';
    # System-wide aliases (also in config.fish, but belt-and-suspenders)
    shellAliases = {
      ls     = "eza --icons --group-directories-first";
      ll     = "eza -la --icons --git --group-directories-first";
      la     = "eza -a --icons";
      cat    = "bat --theme=base16";
      update = "sudo nixos-rebuild switch --flake /etc/nixos#faraday";
    };
  };

  # ---------------------------------------------------------------------------
  # ZSH — privacy config for users who prefer zsh
  # ---------------------------------------------------------------------------
  programs.zsh = {
    enable = true;
    histSize = 0;
    histFile = "/dev/null";
    shellInit = ''
      # Faraday: disable zsh history
      unset HISTFILE
      HISTSIZE=0
      SAVEHIST=0
    '';
    interactiveShellInit = ''
      export STARSHIP_CONFIG=/etc/faraday/starship.toml
      if command -v fastfetch &>/dev/null; then
        fastfetch --config /etc/faraday/fastfetch.jsonc
      fi
      if command -v starship &>/dev/null; then
        eval "$(starship init zsh)"
      fi
    '';
    shellAliases = {
      ls     = "eza --icons";
      ll     = "eza -la --icons --git";
      la     = "eza -a --icons";
      cat    = "bat --theme=base16";
      update = "sudo nixos-rebuild switch --flake /etc/nixos#faraday";
      git    = "torify git";
    };
  };

  # ---------------------------------------------------------------------------
  # STARSHIP — global config pointer
  # Every shell sources STARSHIP_CONFIG from our bashrc/config.fish,
  # but set it globally too so it works even in non-sourced contexts.
  # ---------------------------------------------------------------------------
  environment.sessionVariables = {
    STARSHIP_CONFIG    = "/etc/faraday/starship.toml";
    FASTFETCH_CONFIG   = "/etc/faraday/fastfetch.jsonc";
    # Bat color theme
    BAT_THEME          = "base16";
    # eza date format
    EZA_COLORS         = "da=38;2;125;207;255";
  };

  # ---------------------------------------------------------------------------
  # HOME-MANAGER INTEGRATION
  # Symlink /etc/faraday/ configs into ~/.config/ for the faraday user.
  # This means nixos-rebuild updates the symlink targets, so configs are
  # always up to date without manual intervention.
  # ---------------------------------------------------------------------------
  # This is applied in home.nix via home.file — see that file for the
  # actual symlink declarations. We just document the contract here:
  #
  #   /etc/faraday/fastfetch.jsonc  → ~/.config/fastfetch/config.jsonc
  #   /etc/faraday/starship.toml    → ~/.config/starship.toml
  #   /etc/faraday/kitty.conf       → ~/.config/kitty/kitty.conf
  #   /etc/faraday/config.fish      → ~/.config/fish/conf.d/faraday.fish
  # ---------------------------------------------------------------------------
}
