{ config, pkgs, lib, ... }:

# =============================================================================
# FARADAY DESKTOP MODULE
# Hyprland + Waybar + Wofi + Hyprpaper
# Color scheme: deep blue/black (#0a0e1a base) with cyan (#00d4ff) accents
# =============================================================================

{
  # ---------------------------------------------------------------------------
  # HYPRLAND
  # Wayland compositor — no X11, so no X11 side-channel attacks
  # (X11 allows any app to read keystrokes from other apps via XSpy etc.)
  # ---------------------------------------------------------------------------
  programs.hyprland = {
    enable = true;
    xwayland.enable = false; # Disable XWayland — closes X11 attack surface
    # Set to true only if you need legacy X11 apps
  };

  # XDG portals — needed for screen sharing, file pickers under Wayland
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
    config.common.default = "*";
  };

  # ---------------------------------------------------------------------------
  # DISPLAY / GREETER
  # greetd + tuigreet for a minimal, no-data-leaking login screen
  # ---------------------------------------------------------------------------
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --greeting 'Faraday Linux' --cmd Hyprland";
        user = "greeter";
      };
    };
  };
  users.users.greeter = {
    isSystemUser = true;
    group = "greeter";
  };
  users.groups.greeter = {};

  # ---------------------------------------------------------------------------
  # SOUND (PipeWire)
  # Wayland-native audio. Microphone is available but blocked by default
  # via kernel module blacklist in hardening.nix.
  # User can enable mic by running: sudo modprobe snd_usb_audio (or relevant driver)
  # ---------------------------------------------------------------------------
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true; # PulseAudio compatibility for legacy apps
    jack.enable = false;
  };

  # ---------------------------------------------------------------------------
  # FONTS — clean, modern monospace + UI fonts
  # ---------------------------------------------------------------------------
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono   # Terminal / code
      nerd-fonts.fira-code        # Ligature support
      inter                        # UI sans-serif
      noto-fonts                   # Unicode coverage
      noto-fonts-color-emoji
    ];
    fontconfig = {
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" ];
        sansSerif = [ "Inter" ];
        serif = [ "Noto Serif" ];
      };
      # Subpixel rendering
      subpixel.rgba = "rgb";
    };
  };

  # ---------------------------------------------------------------------------
  # CURSOR & ICON THEME
  # ---------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    # Cursor
    bibata-cursors

    # Icons
    papirus-icon-theme

    # GTK theme (dark, matches our color scheme)
    adw-gtk3

    # Hyprland tooling
    hyprpaper         # Wallpaper daemon
    hyprlock          # Screen locker
    hypridle          # Idle daemon (auto-lock)
    hyprpicker        # Color picker
    hyprshot          # Screenshot tool

    # Waybar (status bar)
    waybar

    # Launcher
    wofi

    # Notifications
    dunst
    libnotify

    # Clipboard (Wayland)
    wl-clipboard
    cliphist

    # Polkit agent (for privilege escalation dialogs)
    polkit_gnome

    # Screen brightness (if on laptop)
    brightnessctl

    # Network applet
    networkmanagerapplet

    # GTK settings
    nwg-look
    gtk3
    gtk4
  ];

  # ---------------------------------------------------------------------------
  # POLKIT — needed for GUI privilege escalation
  # ---------------------------------------------------------------------------
  security.polkit.enable = true;
  systemd.user.services.polkit-gnome = {
    description = "GNOME polkit agent";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
    };
  };

  # ---------------------------------------------------------------------------
  # ENVIRONMENT VARIABLES (Wayland/Hyprland)
  # ---------------------------------------------------------------------------
  environment.sessionVariables = {
    # Force all Qt apps to use Wayland (no XWayland fallback)
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

    # Electron apps — Wayland native
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    NIXOS_OZONE_WL = "1";

    # Java apps — Wayland
    _JAVA_AWT_WM_NONREPARENTING = "1";

    # SDL
    SDL_VIDEODRIVER = "wayland";

    # Theme
    GTK_THEME = "adw-gtk3-dark";
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";

    # Disable hardware acceleration in risky apps (sandboxing)
    # LIBGL_ALWAYS_SOFTWARE = "1"; # Uncomment for max isolation
  };
}
