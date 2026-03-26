{ config, pkgs, lib, ... }:

# =============================================================================
# FARADAY HOME MANAGER CONFIG
# User-level dotfiles for the live session / installed user.
# Manages Hyprland, Waybar, Wofi, Kitty, Starship configs.
# =============================================================================

{
  home.stateVersion = "24.11";
  home.username = "faraday";
  home.homeDirectory = "/home/faraday";

  # ---------------------------------------------------------------------------
  # HYPRLAND CONFIG
  # ---------------------------------------------------------------------------
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = false;

    settings = {
      # ----- Monitors -----
      # "preferred" auto-detects; add specific entries for multi-monitor
      monitor = [
        ",preferred,auto,1"
      ];

      # ----- General -----
      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 2;
        "col.active_border" = "rgba(00d4ffee) rgba(0066ffee) 45deg";
        "col.inactive_border" = "rgba(1a2035aa)";
        layout = "dwindle";
        allow_tearing = false;
      };

      # ----- Decoration -----
      decoration = {
        rounding = 8;
        active_opacity = 1.0;
        inactive_opacity = 0.92;
        fullscreen_opacity = 1.0;
        drop_shadow = true;
        shadow_range = 12;
        shadow_render_power = 3;
        "col.shadow" = "rgba(00d4ff33)";
        blur = {
          enabled = true;
          size = 6;
          passes = 2;
          new_optimizations = true;
          vibrancy = 0.2;
        };
      };

      # ----- Animations -----
      animations = {
        enabled = true;
        bezier = [
          "faraday, 0.05, 0.9, 0.1, 1.05"
          "linear, 0.0, 0.0, 1.0, 1.0"
          "smooth, 0.25, 0.46, 0.45, 0.94"
        ];
        animation = [
          "windows, 1, 5, faraday"
          "windowsOut, 1, 4, smooth, popin 80%"
          "border, 1, 8, linear"
          "borderangle, 1, 20, linear, loop"
          "fade, 1, 6, smooth"
          "workspaces, 1, 5, faraday, slidevert"
        ];
      };

      # ----- Input -----
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
          disable_while_typing = true;
        };
        sensitivity = 0;
        accel_profile = "flat";
      };

      # ----- Dwindle Layout -----
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      # ----- Misc -----
      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = true;
      };

      # ----- Autostart -----
      exec-once = [
        "hyprpaper"
        "waybar"
        "dunst"
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        "nm-applet --indicator"
        # Show Tor status notification on login
        "sleep 5 && faraday-status | head -20 | notify-send -t 8000 'Faraday Security Status' \"$(faraday-status)\""
      ];

      # ----- Keybindings -----
      "$mod" = "SUPER";

      bind = [
        # Apps
        "$mod, Return, exec, kitty"
        "$mod, E, exec, nautilus"
        "$mod, F, exec, firefox"
        "$mod, Space, exec, wofi --show drun"

        # Window management
        "$mod, Q, killactive"
        "$mod SHIFT, E, exit"
        "$mod, V, togglefloating"
        "$mod, P, pseudo"
        "$mod, J, togglesplit"
        "$mod, F11, fullscreen"

        # Screenshots
        ", Print, exec, hyprshot -m output"
        "$mod, Print, exec, hyprshot -m region"

        # Move focus
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        "$mod, h, movefocus, l"
        "$mod, l, movefocus, r"
        "$mod, k, movefocus, u"
        "$mod, j, movefocus, d"

        # Workspaces
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"

        # Lock screen
        "$mod, L, exec, hyprlock"

        # Faraday status
        "$mod, S, exec, kitty --title 'Faraday Status' faraday-status"

        # Clipboard history
        "$mod, C, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy"
      ];

      bindm = [
        # Mouse window management
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      bindl = [
        # Media keys
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
      ];

      binde = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86MonBrightnessUp, exec, brightnessctl s 10%+"
        ", XF86MonBrightnessDown, exec, brightnessctl s 10%-"
      ];

      # Window rules
      windowrulev2 = [
        "float, class:^(nm-connection-editor)$"
        "float, class:^(pavucontrol)$"
        "float, title:^(Faraday Status)$"
        "size 600 400, title:^(Faraday Status)$"
        "center, title:^(Faraday Status)$"
        # Kitty: enable blur on the semi-transparent background
        "blur, class:^(kitty)$"
        "opacity 0.95 0.90, class:^(kitty)$"  # active / inactive opacity
        # KeePassXC: float, sensible default size
        "float, class:^(org.keepassxc.KeePassXC)$"
        "size 900 650, class:^(org.keepassxc.KeePassXC)$"
        "center, class:^(org.keepassxc.KeePassXC)$"
      ];
    };
  };

  # ---------------------------------------------------------------------------
  # HYPRPAPER (wallpaper)
  # ---------------------------------------------------------------------------
  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [ "/etc/faraday/wallpaper.png" ];
      wallpaper = [ ",/etc/faraday/wallpaper.png" ];
      splash = false;
      ipc = "on";
    };
  };

  # ---------------------------------------------------------------------------
  # HYPRLOCK (screen locker)
  # ---------------------------------------------------------------------------
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = false;
        hide_cursor = true;
        grace = 0;
        no_fade_in = false;
      };
      background = [{
        monitor = "";
        path = "/etc/faraday/wallpaper.png";
        blur_passes = 3;
        blur_size = 8;
        brightness = 0.5;
      }];
      input-field = [{
        monitor = "";
        size = "300, 48";
        position = "0, -80";
        halign = "center";
        valign = "center";
        outline_thickness = 2;
        dots_size = 0.33;
        "col.outer" = "rgba(00d4ffcc)";
        "col.inner" = "rgba(0a0e1aee)";
        "col.font" = "rgba(00d4ffff)";
        fade_on_empty = false;
        placeholder_text = "<span foreground='##00d4ff'>Enter passphrase</span>";
        rounding = 6;
      }];
      label = [{
        monitor = "";
        text = "cmd[update:1000] echo -e \"<b><big>$(date +%H:%M)</big></b>\"";
        color = "rgba(00d4ffee)";
        font_size = 64;
        font_family = "JetBrainsMono Nerd Font";
        position = "0, 80";
        halign = "center";
        valign = "center";
      }];
    };
  };

  # ---------------------------------------------------------------------------
  # HYPRIDLE (auto-lock after inactivity)
  # ---------------------------------------------------------------------------
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        after_sleep_cmd = "hyprlock";
        ignore_dbus_inhibit = false;
        lock_cmd = "hyprlock";
      };
      listener = [
        { timeout = 300;  on-timeout = "hyprlock"; }            # 5min → lock
        { timeout = 600;  on-timeout = "hyprctl dispatch dpms off"; # 10min → screen off
          on-resume = "hyprctl dispatch dpms on"; }
      ];
    };
  };

  # ---------------------------------------------------------------------------
  # WAYBAR
  # ---------------------------------------------------------------------------
  programs.waybar = {
    enable = true;
    style = ''
      /* Faraday Waybar — deep blue/black with cyan accents */

      * {
        font-family: "JetBrainsMono Nerd Font", "Inter", sans-serif;
        font-size: 13px;
        border: none;
        border-radius: 0;
        min-height: 0;
        padding: 0;
        margin: 0;
      }

      window#waybar {
        background: rgba(10, 14, 26, 0.92);
        color: #e0f0ff;
        border-bottom: 1px solid rgba(0, 212, 255, 0.2);
      }

      .modules-left { padding-left: 8px; }
      .modules-right { padding-right: 8px; }

      #workspaces button {
        padding: 0 8px;
        color: #4a6fa5;
        background: transparent;
      }
      #workspaces button.active {
        color: #00d4ff;
        background: rgba(0, 212, 255, 0.1);
        border-bottom: 2px solid #00d4ff;
      }
      #workspaces button:hover {
        color: #00d4ff;
        background: rgba(0, 212, 255, 0.08);
      }

      #clock {
        color: #00d4ff;
        font-weight: bold;
        padding: 0 12px;
      }

      #network {
        color: #00d4ff;
        padding: 0 10px;
      }
      #network.disconnected { color: #ff4444; }

      #pulseaudio {
        color: #4a9eff;
        padding: 0 10px;
      }
      #pulseaudio.muted { color: #666; }

      #battery {
        color: #00d4ff;
        padding: 0 10px;
      }
      #battery.warning { color: #ffaa00; }
      #battery.critical { color: #ff4444; }

      #cpu, #memory {
        color: #4a9eff;
        padding: 0 8px;
      }

      #custom-tor {
        color: #a78bfa;
        padding: 0 10px;
        font-weight: bold;
      }
      #custom-tor.connected { color: #7c3aed; }

      #tray {
        padding: 0 8px;
      }

      tooltip {
        background: rgba(10, 14, 26, 0.95);
        border: 1px solid rgba(0, 212, 255, 0.3);
        border-radius: 6px;
        color: #e0f0ff;
      }
    '';

    settings = [{
      layer = "top";
      position = "top";
      height = 32;
      spacing = 4;

      modules-left = [ "hyprland/workspaces" "hyprland/window" ];
      modules-center = [ "clock" ];
      modules-right = [
        "custom/tor"
        "network"
        "pulseaudio"
        "cpu"
        "memory"
        "battery"
        "tray"
      ];

      "hyprland/workspaces" = {
        disable-scroll = true;
        all-outputs = true;
        format = "{icon}";
        format-icons = {
          "1" = "󰋜";
          "2" = "󰈹";
          "3" = "󰭹";
          "4" = "󰌆";
          "5" = "󰉋";
          active = "󰊠";
          default = "󰊠";
        };
      };

      "hyprland/window" = {
        max-length = 40;
        separate-outputs = true;
      };

      clock = {
        format = "  {:%H:%M}";
        format-alt = "  {:%A, %B %d, %Y}";
        tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
      };

      "custom/tor" = {
        exec = ''
          if systemctl is-active --quiet tor; then
            echo "󰦝  Tor"
          else
            echo "󰦞  Tor OFF"
          fi
        '';
        interval = 30;
        return-type = "";
        on-click = "kitty --title 'Faraday Status' faraday-status";
      };

      network = {
        format-wifi = "  {essid}";
        format-ethernet = "󰈀  {ipaddr}";
        format-disconnected = "󰤮  Offline";
        tooltip-format = "{ifname}: {ipaddr}\nStrength: {signalStrength}%";
        on-click = "nm-connection-editor";
      };

      pulseaudio = {
        format = "{icon}  {volume}%";
        format-muted = "󰝟  Muted";
        format-icons = { default = [ "󰕿" "󰖀" "󰕾" ]; };
        on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        scroll-step = 5;
      };

      cpu = {
        format = "  {usage}%";
        interval = 5;
        tooltip = false;
      };

      memory = {
        format = "  {used:.1f}G";
        interval = 10;
      };

      battery = {
        states = { warning = 30; critical = 15; };
        format = "{icon}  {capacity}%";
        format-charging = "󰂄  {capacity}%";
        format-icons = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
        interval = 60;
      };

      tray = {
        spacing = 8;
        icon-size = 16;
      };
    }];
  };

  # ---------------------------------------------------------------------------
  # DUNST (notifications)
  # ---------------------------------------------------------------------------
  services.dunst = {
    enable = true;
    settings = {
      global = {
        width = 320;
        height = 100;
        offset = "12x48";
        origin = "top-right";
        transparency = 8;
        corner_radius = 8;
        font = "JetBrainsMono Nerd Font 11";
        format = "<b>%s</b>\n%b";
        frame_width = 1;
        frame_color = "#00d4ff44";
        separator_color = "frame";
      };
      urgency_low = {
        background = "#0a0e1aee";
        foreground = "#7ecfff";
        timeout = 5;
      };
      urgency_normal = {
        background = "#0a1228ee";
        foreground = "#e0f0ff";
        timeout = 8;
      };
      urgency_critical = {
        background = "#1a0a1aee";
        foreground = "#ff6b6b";
        frame_color = "#ff4444";
        timeout = 0;
      };
    };
  };

  # ---------------------------------------------------------------------------
  # WOFI (launcher)
  # ---------------------------------------------------------------------------
  programs.wofi = {
    enable = true;
    style = ''
      /* Faraday Wofi launcher */
      window {
        background-color: rgba(10, 14, 26, 0.96);
        border: 1px solid rgba(0, 212, 255, 0.3);
        border-radius: 12px;
        font-family: "JetBrainsMono Nerd Font", sans-serif;
      }
      #input {
        background: rgba(0, 212, 255, 0.05);
        border: 1px solid rgba(0, 212, 255, 0.2);
        border-radius: 8px;
        color: #e0f0ff;
        padding: 8px 12px;
        margin: 8px;
        font-size: 14px;
      }
      #input:focus {
        border-color: #00d4ff;
        outline: none;
      }
      #scroll {
        margin: 4px;
      }
      #entry {
        padding: 6px 12px;
        border-radius: 6px;
        color: #b0c8e8;
      }
      #entry:selected {
        background: rgba(0, 212, 255, 0.12);
        color: #00d4ff;
      }
      #text { padding: 4px; }
      #img { margin-right: 8px; }
    '';
    settings = {
      width = 500;
      height = 400;
      location = "center";
      show = "drun";
      prompt = "  Launch";
      filter_rate = 100;
      allow_markup = true;
      no_actions = true;
      halign = "fill";
      orientation = "vertical";
      content-halign = "fill";
      insensitive = true;
      allow_images = true;
      image_size = 24;
      gtk_dark = true;
    };
  };

  # ---------------------------------------------------------------------------
  # KITTY TERMINAL
  # Source of truth: assets/kitty/kitty.conf
  # home-manager reads the asset file directly — so editing that file and
  # running nixos-rebuild is all you need to update the terminal config.
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
      color0  = "#0d1117"; color8  = "#1a2035";   # Black
      color1  = "#f7768e"; color9  = "#ff9e9e";   # Red
      color2  = "#9ece6a"; color10 = "#b9e083";   # Green
      color3  = "#e0af68"; color11 = "#ffd28f";   # Yellow
      color4  = "#4a9eff"; color12 = "#7dcfff";   # Blue → cyan accent
      color5  = "#bb9af7"; color13 = "#caa9fa";   # Magenta
      color6  = "#7dcfff"; color14 = "#a9daff";   # Cyan
      color7  = "#c0caf5"; color15 = "#e0f0ff";   # White

      # --- Window ---
      window_padding_width     = 12;
      # 0.95 opacity — Hyprland applies blur to the window via windowrulev2
      background_opacity       = "0.95";
      dynamic_background_color = false;

      # --- Tab bar: minimal — only index and title ---
      tab_bar_edge              = "top";
      tab_bar_style             = "powerline";
      tab_powerline_style       = "slanted";
      tab_bar_min_tabs          = 1;
      active_tab_title_template = " {index}: {title[:20]} ";
      inactive_tab_title_template = " {index}: {title[:20]} ";
      active_tab_background     = "#7dcfff";
      active_tab_foreground     = "#0a0d14";
      inactive_tab_background   = "#1a1f2e";
      inactive_tab_foreground   = "#4a6fa5";
      tab_bar_background        = "#0a0d14";

      # --- Behavior ---
      scrollback_lines        = 10000;
      enable_audio_bell       = false;
      confirm_os_window_close = 0;

      # --- Ligatures ---
      disable_ligatures = "never";
      adjust_line_height = 2;

      # --- Wayland ---
      linux_display_server = "wayland";
    };

    # Keybindings — Ctrl+T/W for tabs, Ctrl+\\ and Ctrl+- for splits
    keybindings = {
      "ctrl+t"           = "new_tab_with_cwd";
      "ctrl+w"           = "close_tab";
      "ctrl+tab"         = "next_tab";
      "ctrl+shift+tab"   = "previous_tab";
      # Vertical split (side by side)
      "ctrl+backslash"   = "launch --location=vsplit --cwd=current";
      # Horizontal split (top / bottom)
      "ctrl+minus"       = "launch --location=hsplit --cwd=current";
      # Navigate splits
      "ctrl+left"        = "neighboring_window left";
      "ctrl+right"       = "neighboring_window right";
      "ctrl+up"          = "neighboring_window up";
      "ctrl+down"        = "neighboring_window down";
      # Font size
      "ctrl+equal"       = "change_font_size all +1.0";
      "ctrl+0"           = "change_font_size all 0";
    };
  };

  # ---------------------------------------------------------------------------
  # STARSHIP PROMPT
  # Config is loaded from /etc/faraday/starship.toml (deployed by shell.nix).
  # We still enable the home-manager module so starship is wired into the
  # shell init scripts, but override the config path to our system file.
  # ---------------------------------------------------------------------------
  programs.starship = {
    enable = true;
    # Don't let home-manager write ~/.config/starship.toml —
    # we point STARSHIP_CONFIG at /etc/faraday/starship.toml instead.
    # This is set in the session env by shell.nix.
    settings = {
      # Two-line prompt — matching assets/shell/starship.toml
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
        show_always  = true;
        format       = "[$user]($style)";
        style_user   = "bold #7dcfff";
        style_root   = "bold red";
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
  # GTK THEME (dark, matching our scheme)
  # ---------------------------------------------------------------------------
  gtk = {
    enable = true;
    theme = { name = "adw-gtk3-dark"; package = pkgs.adw-gtk3; };
    iconTheme = { name = "Papirus-Dark"; package = pkgs.papirus-icon-theme; };
    cursorTheme = { name = "Bibata-Modern-Ice"; package = pkgs.bibata-cursors; };
    font = { name = "Inter"; size = 11; };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    gtk4.theme = null; # Use new default (suppress stateVersion warning)
  };

  # ---------------------------------------------------------------------------
  # QT THEME
  # ---------------------------------------------------------------------------
  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style = { name = "adwaita-dark"; package = pkgs.adwaita-qt; };
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
        "text/html"                = "firefox.desktop";
        "x-scheme-handler/http"   = "firefox.desktop";
        "x-scheme-handler/https"  = "firefox.desktop";
        "application/pdf"         = "org.gnome.Evince.desktop";
        "image/*"                 = "imv.desktop";
        "video/*"                 = "mpv.desktop";
        "irc"                     = "element-desktop.desktop";
      };
    };
  };

  # ---------------------------------------------------------------------------
  # CONFIG FILE SYMLINKS
  # Point ~/.config/ entries at /etc/faraday/ so nixos-rebuild updates them
  # automatically. The source is the Nix store path of the deployed system file.
  #
  # Why symlinks to /etc/faraday/ rather than direct store paths?
  # → /etc/faraday/ files are updated by nixos-rebuild via environment.etc.
  #   If we pointed home.file directly at the flake's asset paths, a user who
  #   only does `nixos-rebuild` (not home-manager rebuild) would get stale
  #   links. Pointing at /etc/faraday/ means rebuild-once-updates-all.
  # ---------------------------------------------------------------------------

  # Fastfetch
  home.file.".config/fastfetch/config.jsonc" = {
    source  = /etc/faraday/fastfetch.jsonc;
    # onChange: fastfetch reads config at runtime, no restart needed
  };

  # Kitty (home-manager programs.kitty writes ~/.config/kitty/kitty.conf;
  # we ALSO drop the asset file alongside it as kitty.faraday.conf for reference)
  home.file.".config/kitty/kitty.faraday.conf".source = /etc/faraday/kitty.conf;

  # Fish — drop our config as a conf.d snippet so it's sourced on top of
  # any system fish config without overwriting ~/.config/fish/config.fish
  home.file.".config/fish/conf.d/faraday.fish".source = /etc/faraday/config.fish;
}
