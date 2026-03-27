{ config, pkgs, lib, ... }:

# =============================================================================
# FARADAY DESKTOP MODULE
# KDE Plasma 6 (Wayland) + SDDM
# Color scheme applied via KDE global theme / kvantum
# =============================================================================

{
  # ---------------------------------------------------------------------------
  # KDE PLASMA 6
  # ---------------------------------------------------------------------------
  services.desktopManager.plasma6.enable = true;

  # SDDM display manager — KDE's native, supports Wayland session
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # ---------------------------------------------------------------------------
  # SOUND (PipeWire)
  # ---------------------------------------------------------------------------
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = false;
  };

  # ---------------------------------------------------------------------------
  # FONTS
  # ---------------------------------------------------------------------------
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      inter
      noto-fonts
      noto-fonts-color-emoji
    ];
    fontconfig = {
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" ];
        sansSerif = [ "Inter" ];
        serif     = [ "Noto Serif" ];
      };
      subpixel.rgba = "rgb";
    };
  };

  # ---------------------------------------------------------------------------
  # POLKIT (KDE provides its own agent — just needs the service enabled)
  # ---------------------------------------------------------------------------
  security.polkit.enable = true;

  # ---------------------------------------------------------------------------
  # EXTRA PACKAGES
  # KDE provides most UI tooling; these fill in the gaps
  # ---------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    bibata-cursors
    papirus-icon-theme
    wl-clipboard
    brightnessctl
    networkmanagerapplet
  ];

  # ---------------------------------------------------------------------------
  # ENVIRONMENT VARIABLES
  # ---------------------------------------------------------------------------
  environment.sessionVariables = {
    NIXOS_OZONE_WL           = "1";              # Electron apps use Wayland
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    QT_QPA_PLATFORM          = "wayland";
    SDL_VIDEODRIVER          = "wayland";
    XCURSOR_THEME            = "Bibata-Modern-Ice";
    XCURSOR_SIZE             = "24";
  };
}
