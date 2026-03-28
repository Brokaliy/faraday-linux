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
  # KDE SECURITY MENU CATEGORY
  # Adds a "Security" section to KDE's app launcher sidebar
  # ---------------------------------------------------------------------------
  environment.etc."xdg/menus/applications-merged/faraday-security.menu".text = ''
    <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
      "http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd">
    <Menu>
      <Name>Applications</Name>
      <Menu>
        <Name>Security</Name>
        <Directory>faraday-security.directory</Directory>
        <Include>
          <Category>Security</Category>
        </Include>
      </Menu>
    </Menu>
  '';

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

    # Security menu directory entry + desktop items for CLI security tools
    (runCommand "faraday-security-menu-entries" {} ''
      mkdir -p $out/share/desktop-directories
      cat > $out/share/desktop-directories/faraday-security.directory << 'DIREOF'
      [Desktop Entry]
      Name=Security
      Comment=Security and Privacy Tools
      Icon=security-high
      Type=Directory
      DIREOF

      mkdir -p $out/share/applications
      # Nmap
      cat > $out/share/applications/faraday-nmap.desktop << 'EOF'
      [Desktop Entry]
      Name=Nmap
      Comment=Network scanner
      Exec=kitty --title Nmap nmap
      Icon=utilities-terminal
      Terminal=false
      Type=Application
      Categories=Security;Network;
      EOF
      # Wireshark (already has its own .desktop with Network category, add Security)
      cat > $out/share/applications/faraday-wireshark.desktop << 'EOF'
      [Desktop Entry]
      Name=Wireshark
      Comment=Network protocol analyser
      Exec=wireshark
      Icon=wireshark
      Terminal=false
      Type=Application
      Categories=Security;Network;
      EOF
      # John the Ripper
      cat > $out/share/applications/faraday-john.desktop << 'EOF'
      [Desktop Entry]
      Name=John the Ripper
      Comment=Password cracker
      Exec=kitty --title "John the Ripper" john
      Icon=utilities-terminal
      Terminal=false
      Type=Application
      Categories=Security;
      EOF
      # Hashcat
      cat > $out/share/applications/faraday-hashcat.desktop << 'EOF'
      [Desktop Entry]
      Name=Hashcat
      Comment=GPU password cracker
      Exec=kitty --title Hashcat hashcat
      Icon=utilities-terminal
      Terminal=false
      Type=Application
      Categories=Security;
      EOF
      # Hydra
      cat > $out/share/applications/faraday-hydra.desktop << 'EOF'
      [Desktop Entry]
      Name=Hydra
      Comment=Network login brute-forcer
      Exec=kitty --title Hydra hydra
      Icon=utilities-terminal
      Terminal=false
      Type=Application
      Categories=Security;Network;
      EOF
      # sqlmap
      cat > $out/share/applications/faraday-sqlmap.desktop << 'EOF'
      [Desktop Entry]
      Name=sqlmap
      Comment=SQL injection scanner
      Exec=kitty --title sqlmap sqlmap
      Icon=utilities-terminal
      Terminal=false
      Type=Application
      Categories=Security;
      EOF
      # Nikto
      cat > $out/share/applications/faraday-nikto.desktop << 'EOF'
      [Desktop Entry]
      Name=Nikto
      Comment=Web server vulnerability scanner
      Exec=kitty --title Nikto nikto
      Icon=utilities-terminal
      Terminal=false
      Type=Application
      Categories=Security;Network;
      EOF
      # Masscan
      cat > $out/share/applications/faraday-masscan.desktop << 'EOF'
      [Desktop Entry]
      Name=Masscan
      Comment=High-speed port scanner
      Exec=kitty --title Masscan masscan
      Icon=utilities-terminal
      Terminal=false
      Type=Application
      Categories=Security;Network;
      EOF
      # Lynis
      cat > $out/share/applications/faraday-lynis.desktop << 'EOF'
      [Desktop Entry]
      Name=Lynis
      Comment=Security auditing tool
      Exec=kitty --title Lynis sudo lynis audit system
      Icon=utilities-terminal
      Terminal=false
      Type=Application
      Categories=Security;System;
      EOF
      # ClamAV
      cat > $out/share/applications/faraday-clamav.desktop << 'EOF'
      [Desktop Entry]
      Name=ClamAV Scan
      Comment=Antivirus scanner
      Exec=kitty --title ClamAV clamscan --recursive --infected /home
      Icon=utilities-terminal
      Terminal=false
      Type=Application
      Categories=Security;
      EOF
      # Tor status
      cat > $out/share/applications/faraday-tor-status.desktop << 'EOF'
      [Desktop Entry]
      Name=Faraday Status
      Comment=Security services dashboard
      Exec=kitty --title "Faraday Status" faraday-status
      Icon=security-high
      Terminal=false
      Type=Application
      Categories=Security;System;
      EOF
      # OnionShare
      cat > $out/share/applications/faraday-onionshare.desktop << 'EOF'
      [Desktop Entry]
      Name=OnionShare
      Comment=Secure file sharing over Tor
      Exec=onionshare-gui
      Icon=onionshare
      Terminal=false
      Type=Application
      Categories=Security;Network;
      EOF
    '')
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
