{ config, pkgs, lib, ... }:

# =============================================================================
# FARADAY HOME MANAGER CONFIG
# User-level dotfiles. KDE Plasma handles the DE; this manages terminal,
# shell prompt, GTK theme, and config file deployment.
# =============================================================================

{
  home.stateVersion = "24.11";
  home.username = "faraday";
  home.homeDirectory = "/home/faraday";

  # ---------------------------------------------------------------------------
  # KITTY TERMINAL
  # ---------------------------------------------------------------------------
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };
    settings = {
      # --- Colors (Faraday dark — background #0a0d14, cyan #7dcfff) ---
      background            = "#0a0d14";
      foreground            = "#c0caf5";
      selection_background  = "#1a1f2e";
      selection_foreground  = "#7dcfff";
      cursor                = "#7dcfff";
      cursor_text_color     = "#0a0d14";
      url_color             = "#7dcfff";

      # ANSI 16 colors
      color0  = "#0d1117"; color8  = "#1a2035";
      color1  = "#f7768e"; color9  = "#ff9e9e";
      color2  = "#9ece6a"; color10 = "#b9e083";
      color3  = "#e0af68"; color11 = "#ffd28f";
      color4  = "#4a9eff"; color12 = "#7dcfff";
      color5  = "#bb9af7"; color13 = "#caa9fa";
      color6  = "#7dcfff"; color14 = "#a9daff";
      color7  = "#c0caf5"; color15 = "#e0f0ff";

      # --- Window ---
      window_padding_width     = 12;
      background_opacity       = "0.95";
      dynamic_background_color = false;

      # --- Tab bar ---
      tab_bar_edge                = "top";
      tab_bar_style               = "powerline";
      tab_powerline_style         = "slanted";
      tab_bar_min_tabs            = 1;
      active_tab_title_template   = " {index}: {title[:20]} ";
      inactive_tab_title_template = " {index}: {title[:20]} ";
      active_tab_background       = "#7dcfff";
      active_tab_foreground       = "#0a0d14";
      inactive_tab_background     = "#1a1f2e";
      inactive_tab_foreground     = "#4a6fa5";
      tab_bar_background          = "#0a0d14";

      # --- Behavior ---
      scrollback_lines        = 10000;
      enable_audio_bell       = false;
      confirm_os_window_close = 0;
      disable_ligatures       = "never";
      adjust_line_height      = 2;

      # --- Wayland ---
      linux_display_server = "wayland";
    };

    keybindings = {
      "ctrl+t"         = "new_tab_with_cwd";
      "ctrl+w"         = "close_tab";
      "ctrl+tab"       = "next_tab";
      "ctrl+shift+tab" = "previous_tab";
      "ctrl+backslash" = "launch --location=vsplit --cwd=current";
      "ctrl+minus"     = "launch --location=hsplit --cwd=current";
      "ctrl+left"      = "neighboring_window left";
      "ctrl+right"     = "neighboring_window right";
      "ctrl+up"        = "neighboring_window up";
      "ctrl+down"      = "neighboring_window down";
      "ctrl+equal"     = "change_font_size all +1.0";
      "ctrl+0"         = "change_font_size all 0";
    };
  };

  # ---------------------------------------------------------------------------
  # STARSHIP PROMPT
  # ---------------------------------------------------------------------------
  programs.starship = {
    enable = true;
    settings = {
      format = lib.concatStrings [
        "[╭─](bold #7dcfff)"
        "$username"
        "$hostname"
        "$directory"
        "$git_branch"
        "$git_status"
        "$python"
        "$nodejs"
        "$rust"
        "$golang"
        "$cmd_duration"
        "$fill"
        "$time"
        "\n"
        "[╰─](bold #7dcfff)"
        "$character"
      ];

      add_newline = false;

      character = {
        success_symbol = "[❯](bold #7dcfff)";
        error_symbol   = "[❯](bold red)";
        vimcmd_symbol  = "[❮](bold #4a9eff)";
      };

      username = {
        show_always = true;
        format      = "[$user]($style)";
        style_user  = "bold #7dcfff";
        style_root  = "bold red";
      };

      hostname = {
        ssh_only = false;
        format   = "[@$hostname](bold #4a6fa5) ";
      };

      directory = {
        format            = "[$path]($style)[$read_only](bold red) ";
        style             = "bold #7dcfff";
        truncation_length = 3;
        truncate_to_repo  = true;
        read_only         = " 󰌾";
      };

      git_branch = {
        format = "[ $symbol$branch(:$remote_branch)]($style) ";
        style  = "bold #4a9eff";
        symbol = " ";
      };

      git_status = {
        format     = "([$all_status$ahead_behind]($style) )";
        style      = "bold red";
        conflicted = "⚡";
        ahead      = "⬆\${count}";
        behind     = "⬇\${count}";
        diverged   = "⇕⬆\${ahead_count}⬇\${behind_count}";
        up_to_date = "";
        untracked  = "[?\${count}](yellow)";
        modified   = "[✎\${count}](yellow)";
        staged     = "[+\${count}](green)";
        deleted    = "[✗\${count}](red)";
      };

      cmd_duration = {
        min_time = 2000;
        format   = "[ $duration]($style) ";
        style    = "bold yellow";
      };

      python = {
        format       = "[ \${symbol}\${pyenv_prefix}(\${version})(\($virtualenv\))]($style) ";
        style        = "bold yellow";
        symbol       = " ";
        detect_files = [ "*.py" "requirements.txt" "pyproject.toml" ".python-version" ];
      };

      nodejs = {
        format       = "[ $symbol($version)]($style) ";
        style        = "bold #6cc24a";
        symbol       = " ";
        detect_files = [ "package.json" ".nvmrc" ".node-version" ];
      };

      rust = {
        format       = "[ $symbol($version)]($style) ";
        style        = "bold #f74c00";
        symbol       = " ";
        detect_files = [ "Cargo.toml" "Cargo.lock" ];
      };

      golang = {
        format       = "[ $symbol($version)]($style) ";
        style        = "bold #00acd7";
        symbol       = " ";
        detect_files = [ "go.mod" "go.sum" ];
      };

      fill = { symbol = " "; };

      time = {
        disabled    = false;
        format      = "[$time]($style) ";
        style       = "#1a1f2e";
        time_format = "%H:%M";
      };

      nix_shell = {
        format    = "[ $symbol$state( \\($name\\))]($style) ";
        style     = "bold #5277c3";
        symbol    = "󱄅 ";
        heuristic = true;
      };

      aws        = { disabled = true; };
      azure      = { disabled = true; };
      gcloud     = { disabled = true; };
      terraform  = { disabled = true; };
      kubernetes = { disabled = true; };
      package    = { disabled = true; };
    };
  };

  # ---------------------------------------------------------------------------
  # GTK THEME
  # ---------------------------------------------------------------------------
  gtk = {
    enable = true;
    theme      = { name = "adw-gtk3-dark"; package = pkgs.adw-gtk3; };
    iconTheme  = { name = "Papirus-Dark";  package = pkgs.papirus-icon-theme; };
    cursorTheme = { name = "Bibata-Modern-Ice"; package = pkgs.bibata-cursors; };
    font = { name = "Inter"; size = 11; };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.theme = null;
  };

  # ---------------------------------------------------------------------------
  # QT THEME — let KDE manage it
  # ---------------------------------------------------------------------------
  qt = {
    enable = true;
    platformTheme.name = "kde";
  };

  # ---------------------------------------------------------------------------
  # XDG DIRS
  # ---------------------------------------------------------------------------
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      download  = "${config.home.homeDirectory}/Downloads";
      documents = "${config.home.homeDirectory}/Documents";
      pictures  = "${config.home.homeDirectory}/Pictures";
      videos    = "${config.home.homeDirectory}/Videos";
    };
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html"               = "firefox.desktop";
        "x-scheme-handler/http"   = "firefox.desktop";
        "x-scheme-handler/https"  = "firefox.desktop";
        "application/pdf"         = "okularApplication_pdf.desktop";
        "image/*"                 = "imv.desktop";
        "video/*"                 = "mpv.desktop";
      };
    };
  };

  # ---------------------------------------------------------------------------
  # KDE PLASMA THEMING
  # Deploy Faraday color scheme + KDE config to activate it on first login
  # ---------------------------------------------------------------------------

  # Faraday color scheme (dark blue/cyan) — selectable in System Settings
  home.file.".local/share/color-schemes/FaradayDark.colors".source = ./assets/kde/faraday.colors;

  # kdeglobals — activate Faraday color scheme, Papirus icons, font
  home.file.".config/kdeglobals".text = ''
    [ColorScheme]
    Name=Faraday Dark

    [General]
    ColorScheme=FaradayDark
    Name=Faraday Dark

    [Icons]
    Theme=Papirus-Dark

    [KDE]
    SingleClick=false
    LookAndFeelPackage=org.kde.breezedark.desktop
    AnimationDurationFactor=0.5

    [WM]
    activeBackground=10,13,20
    activeBlend=125,207,255
    activeForeground=125,207,255
    inactiveBackground=10,13,20
    inactiveBlend=100,130,180
    inactiveForeground=100,130,180
  '';

  # kwinrc — window decorations + effects (blur, wobbly off for performance)
  home.file.".config/kwinrc".text = ''
    [Compositing]
    AnimationSpeed=3
    Backend=OpenGL
    GLCore=true
    OpenGLIsUnsafe=false

    [Effect-overview]
    BorderActivate=9

    [Plugins]
    blurEnabled=true
    kwin4_effect_fadeEnabled=true
    kwin4_effect_maximizeEnabled=true
    kwin4_effect_scaleEnabled=true
    wobblyWindowsEnabled=false
    zoomEnabled=false

    [Windows]
    BorderlessMaximizedWindows=false
    FocusPolicy=ClickToFocus
  '';

  # Plasma panel / global theme hint (uses Breeze Dark base + our color scheme)
  home.file.".config/plasmarc".text = ''
    [Theme]
    name=breeze-dark
  '';

  # KDE autostart — show Faraday status notification on login
  home.file.".config/autostart/faraday-status.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Faraday Status
    Exec=bash -c 'sleep 5 && notify-send -i security-high -u normal "Faraday Linux" "$(systemctl is-active tor >/dev/null && echo "✓ Tor active" || echo "✗ Tor inactive") | $(mullvad status 2>/dev/null | head -1 || echo "Mullvad: check status")"'
    X-KDE-autostart-after=panel
    StartupNotify=false
  '';

  # ---------------------------------------------------------------------------
  # CONFIG FILE SYMLINKS
  # ---------------------------------------------------------------------------
  home.file.".config/fastfetch/config.jsonc".source = ./assets/shell/fastfetch.jsonc;
  home.file.".config/kitty/kitty.faraday.conf".source = ./assets/kitty/kitty.conf;
  home.file.".config/fish/conf.d/faraday.fish".source = ./assets/shell/config.fish;
}
