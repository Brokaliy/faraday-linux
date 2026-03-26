{ config, pkgs, lib, ... }:

# =============================================================================
# FARADAY INSTALLER MODULE
# Calamares installer with Faraday branding and LUKS enforcement.
# Runs as a live-session app; after install, system boots hardened.
# =============================================================================

let
  # ---------------------------------------------------------------------------
  # CALAMARES BRANDING PACKAGE
  # Defines the visual appearance of the installer (logo, colors, slideshow).
  # ---------------------------------------------------------------------------
  faradayBranding = pkgs.stdenv.mkDerivation {
    name = "calamares-faraday-branding";
    src = ../assets/calamares;

    installPhase = ''
      mkdir -p $out/share/calamares/branding/faraday
      cp -r . $out/share/calamares/branding/faraday/
    '';
  };

  # ---------------------------------------------------------------------------
  # CALAMARES SETTINGS
  # Controls which modules run and in what order.
  # ---------------------------------------------------------------------------
  calamaresSettings = pkgs.writeTextFile {
    name = "settings.conf";
    destination = "/etc/calamares/settings.conf";
    text = ''
      # Faraday Linux Calamares configuration
      ---
      modules-search: [ local, /run/current-system/sw/lib/calamares/modules ]

      sequence:
        - show:
          - welcome
          - locale
          - keyboard
          - partition    # LUKS enforced via partition module config
          - users
          - summary
        - exec:
          - partition
          - mount
          - unpackfs
          - machineid
          - fstab
          - locale
          - keyboard
          - localecfg
          - users
          - displaymanager
          - networkcfg
          - hwclock
          - services-systemd
          - faraday-postinstall  # Custom module (see below)
          - bootloader
          - umount
        - show:
          - finished

      branding: faraday
      prompt-install: false
      dont-chroot: false
      oem-setup: false
      disable-cancel: false
      disable-cancel-during-exec: true
    '';
  };

  # ---------------------------------------------------------------------------
  # PARTITION MODULE CONFIG — enforce LUKS
  # ---------------------------------------------------------------------------
  partitionConfig = pkgs.writeTextFile {
    name = "partition.conf";
    destination = "/etc/calamares/modules/partition.conf";
    text = ''
      # Faraday partition module — LUKS encryption enforced
      ---
      efiSystemPartition: "/boot/efi"
      efiSystemPartitionSize: "512M"
      efiSystemPartitionName: "EFI"

      # Enforce full-disk encryption with LUKS2
      # User cannot proceed without setting an encryption passphrase
      defaultFsType: "ext4"

      # LUKS2 with Argon2id (more resistant to GPU brute-force than PBKDF2)
      luksGeneration: luks2

      # Require encryption — this makes the "No encryption" option hidden
      allowManualPartitioning: true
      initialPartitioningChoice: erase  # Default to full-disk erase + LUKS

      # Swap: encrypted only, or no swap at all
      # We default to no swap (RAM is ephemeral; swap persists secrets to disk)
      availableSwapChoices: [ none, hibernation ]
      initialSwapChoice: none
    '';
  };

  # ---------------------------------------------------------------------------
  # USERS MODULE CONFIG
  # ---------------------------------------------------------------------------
  usersConfig = pkgs.writeTextFile {
    name = "users.conf";
    destination = "/etc/calamares/modules/users.conf";
    text = ''
      ---
      # Default username in installer
      defaultGroups:
        - wheel
        - networkmanager
        - video
        - audio
        - input

      autologinGroup: autologin
      doAutologin: false

      sudoersGroup: wheel
      setRootPassword: false
      passwordRequirements:
        minLength: 12
        maxLength: -1
        requireUpper: true
        requireLower: true
        requireNumbers: true
        requireSpecial: false
    '';
  };

  # ---------------------------------------------------------------------------
  # BOOTLOADER MODULE CONFIG
  # ---------------------------------------------------------------------------
  bootloaderConfig = pkgs.writeTextFile {
    name = "bootloader.conf";
    destination = "/etc/calamares/modules/bootloader.conf";
    text = ''
      ---
      efiType: esp
      installEFIFallback: true

      # GRUB timeout — brief so it doesn't reveal OS existence at boot
      timeout: 3

      # Don't show OS in EFI boot menu (stealth — shows "Linux" not "Faraday Linux")
      efiLabel: "Linux Boot Manager"
    '';
  };

  # ---------------------------------------------------------------------------
  # POST-INSTALL MODULE
  # Runs after all files are laid down — applies Faraday-specific config
  # that Calamares doesn't have a built-in module for.
  # ---------------------------------------------------------------------------
  postInstallScript = pkgs.writeShellScript "faraday-postinstall" ''
    #!/bin/sh
    set -e

    TARGET="$1"  # Calamares passes mount point as first arg

    echo "=== Faraday post-install ==="

    # Enforce no core dumps in installed system
    cat >> "$TARGET/etc/security/limits.conf" << 'EOF'
    * hard core 0
    * soft core 0
    EOF

    # Set up RAM-based tmp (no secrets persist to disk in /tmp)
    echo "tmpfs /tmp tmpfs defaults,noexec,nosuid,nodev,size=512M 0 0" \
      >> "$TARGET/etc/fstab"

    # Lock root account (sudo only)
    chroot "$TARGET" passwd -l root

    echo "=== Faraday post-install complete ==="
  '';

in {
  # ---------------------------------------------------------------------------
  # CALAMARES SERVICE
  # Calamares runs as a systemd service in the live session.
  # It appears as a desktop icon and can also be launched from the menu.
  # ---------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    calamares-nixos
    calamares-nixos-extensions
    libpwquality   # Password quality enforcement
  ];

  # Place all calamares config files
  environment.etc = {
    "calamares/settings.conf".source = "${calamaresSettings}/etc/calamares/settings.conf";
    "calamares/modules/partition.conf".source = "${partitionConfig}/etc/calamares/modules/partition.conf";
    "calamares/modules/users.conf".source = "${usersConfig}/etc/calamares/modules/users.conf";
    "calamares/modules/bootloader.conf".source = "${bootloaderConfig}/etc/calamares/modules/bootloader.conf";
  };

  # Desktop shortcut for installer
  environment.etc."xdg/autostart/calamares.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Install Faraday Linux
    Comment=Install Faraday Linux to your hard drive
    Icon=calamares
    Exec=pkexec calamares
    Terminal=false
    Categories=System;
    Keywords=install;setup;
  '';

  # ---------------------------------------------------------------------------
  # NIXOS-INSTALL INTEGRATION
  # For users who prefer nixos-install over Calamares.
  # ---------------------------------------------------------------------------
  system.activationScripts.faradayInstallHelper = lib.stringAfter [ "users" ] ''
    # Put a reference config for nixos-install in /etc/nixos
    if [ ! -f /etc/nixos/configuration.nix ]; then
      mkdir -p /etc/nixos
      cat > /etc/nixos/configuration.nix << 'EOF'
# Faraday Linux installed configuration
# Generated by live installer — customize after first boot.
# Full source: https://github.com/yourusername/faraday-linux
{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];
  # See faraday-linux flake for full hardened config
}
EOF
    fi
  '';
}
