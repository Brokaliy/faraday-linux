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
  # Color scheme available in user share (plasma-apply-colorscheme reads here)
  # System-wide /etc/xdg/ config handles the actual defaults (see desktop.nix)
  # ---------------------------------------------------------------------------

  # Faraday color scheme in user share so System Settings can show it
  home.file.".local/share/color-schemes/FaradayDark.colors".source = ./assets/kde/faraday.colors;

  # Kvantum user config — use KvDark base theme
  home.file.".config/Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=KvDark
  '';

  # Autostart — apply theme via plasma CLI tools on every login
  # This is the ONLY reliable way to force KDE to use our color scheme.
  home.file.".config/autostart/faraday-theme.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Faraday Theme Setup
    Exec=bash -c 'sleep 3 && plasma-apply-colorscheme FaradayDark && plasma-apply-cursortheme Bibata-Modern-Ice && plasma-apply-wallpaperimage /etc/faraday/wallpaper.png && kwriteconfig6 --file kdeglobals --group General --key ColorScheme FaradayDark && kwriteconfig6 --file kdeglobals --group Icons --key Theme Papirus-Dark && kwriteconfig6 --file plasmarc --group Theme --key name breeze-dark && qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true'
    X-KDE-autostart-phase=1
    StartupNotify=false
  '';

  # Autostart — security status notification
  home.file.".config/autostart/faraday-status.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Faraday Status
    Exec=bash -c 'sleep 6 && notify-send -i security-high -u normal "Faraday Linux" "$(systemctl is-active tor >/dev/null 2>&1 && echo "✓ Tor active" || echo "✗ Tor INACTIVE") | $(mullvad status 2>/dev/null | head -1 || echo "Mullvad: not connected")"'
    X-KDE-autostart-phase=2
    StartupNotify=false
  '';

  # ---------------------------------------------------------------------------
  # CONFIG FILE SYMLINKS
  # ---------------------------------------------------------------------------
  # KDE wallpaper — Tux-in-cage logo
  home.file.".config/plasma-org.kde.plasma.desktop-appletsrc".text = ''
    [Containments][1][Wallpaper][org.kde.image][General]
    Image=/etc/faraday/logo.png
  '';

  home.file.".config/fastfetch/config.jsonc".source = ./assets/shell/fastfetch.jsonc;
  home.file.".config/kitty/kitty.faraday.conf".source = ./assets/kitty/kitty.conf;
  home.file.".config/fish/conf.d/faraday.fish".source = ./assets/shell/config.fish;
}
