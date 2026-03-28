{ config, pkgs, lib, ... }:

# =============================================================================
# FARADAY BRANDING MODULE
# Custom OS identity, boot splash, and visual identity.
# =============================================================================

{
  # ---------------------------------------------------------------------------
  # OS IDENTITY
  # Sets what shows in neofetch, uname -a, lsb_release, etc.
  # ---------------------------------------------------------------------------
  networking.hostName = lib.mkDefault "faraday";

  system.nixos.distroName = "Faraday Linux";
  system.nixos.distroId   = "faraday";

  environment.etc."os-release".text = lib.mkForce ''
    NAME="Faraday Linux"
    VERSION="1.0"
    ID=faraday
    ID_LIKE=nixos
    VERSION_ID="1.0"
    PRETTY_NAME="Faraday Linux 1.0 (Cage)"
    HOME_URL="https://faradaylinux.org"
    DOCUMENTATION_URL="https://faradaylinux.org/docs"
    SUPPORT_URL="https://faradaylinux.org/support"
    BUG_REPORT_URL="https://github.com/yourusername/faraday-linux/issues"
    LOGO="faraday"
    ANSI_COLOR="1;36"
  '';

  # ---------------------------------------------------------------------------
  # PLYMOUTH BOOT SPLASH
  # Shows a Faraday cage animation while the system boots.
  # The "fade-in" theme is minimal — replace with custom theme if desired.
  # ---------------------------------------------------------------------------
  boot.plymouth = {
    enable = true;
    theme = "spinner"; # Clean minimal spinner — replace with custom theme later
    themePackages = [ pkgs.plymouth ];
  };

  # Clean boot — hide kernel messages, show only Plymouth splash
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
  boot.kernelParams = [
    "quiet"
    "splash"
    "rd.udev.log_level=3"
    "udev.log_priority=3"
  ];

  # ---------------------------------------------------------------------------
  # FASTFETCH BRANDING
  # Custom neofetch-style display with Faraday logo in ASCII art.
  # ---------------------------------------------------------------------------
  environment.etc."fastfetch/config.jsonc".text = ''
    {
      "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
      "logo": {
        "type": "builtin",
        "source": "nixos",
        "color": {
          "1": "cyan",
          "2": "blue"
        }
      },
      "display": {
        "separator": "  ",
        "color": "cyan"
      },
      "modules": [
        {
          "type": "custom",
          "format": "\u001b[1;36m ╔═══════════════════════════════╗\u001b[0m"
        },
        {
          "type": "custom",
          "format": "\u001b[1;36m ║   FARADAY LINUX  — CAGE v1.0  ║\u001b[0m"
        },
        {
          "type": "custom",
          "format": "\u001b[1;36m ╚═══════════════════════════════╝\u001b[0m"
        },
        "break",
        { "type": "os",       "key": "\u001b[36m  OS\u001b[0m"       },
        { "type": "kernel",   "key": "\u001b[36m  Kernel\u001b[0m"   },
        { "type": "uptime",   "key": "\u001b[36m  Uptime\u001b[0m"   },
        { "type": "packages", "key": "\u001b[36m  Packages\u001b[0m" },
        { "type": "shell",    "key": "\u001b[36m  Shell\u001b[0m"     },
        { "type": "wm",       "key": "\u001b[36m  WM\u001b[0m"       },
        { "type": "terminal", "key": "\u001b[36m  Terminal\u001b[0m" },
        { "type": "cpu",      "key": "\u001b[36m  CPU\u001b[0m"       },
        { "type": "memory",   "key": "\u001b[36m  RAM\u001b[0m"       },
        { "type": "disk",     "key": "\u001b[36m  Disk\u001b[0m"      },
        "break",
        {
          "type": "custom",
          "format": "\u001b[36m  Tor:\u001b[0m \u001b[32m● Active\u001b[0m  \u001b[36mMAC:\u001b[0m \u001b[33m⟳ Random\u001b[0m  \u001b[36mDNS:\u001b[0m \u001b[32m● Encrypted\u001b[0m"
        },
        "break",
        { "type": "colors", "paddingLeft": 2, "symbol": "circle" }
      ]
    }
  '';

  # neofetch alias points at our branded fastfetch config
  environment.shellAliases = {
    neofetch = "fastfetch --config /etc/faraday/fastfetch.jsonc";
  };

  # ---------------------------------------------------------------------------
  # GRUB BRANDING
  # Custom GRUB theme with Faraday cage style.
  # ---------------------------------------------------------------------------
  boot.loader.grub = {
    enable = lib.mkDefault false; # ISO uses isolinux; installed system may use GRUB
    theme = null; # Set to a custom theme package if building installed system
    splashImage = null;
    backgroundColor = "#0a0e1a";
    font = "${pkgs.terminus_font}/share/fonts/terminus/ter-v16n.pcf.gz";
  };

  # ---------------------------------------------------------------------------
  # WALLPAPER (deployed to default user location)
  # The actual PNG is in assets/wallpaper.png
  # Hyprpaper picks it up via config/hyprland.conf
  # ---------------------------------------------------------------------------
  environment.etc."faraday/wallpaper.png".source = ../assets/logo.png;
  environment.etc."faraday/logo.png".source = ../assets/logo.png;

  # ---------------------------------------------------------------------------
  # MOTD (message of the day) — shown in terminal on login
  # ---------------------------------------------------------------------------
  users.motd = ''
    ╔══════════════════════════════════════════════════════╗
    ║              FARADAY LINUX  —  CAGE v1.0             ║
    ║          Privacy-first. Tor-routed. Hardened.        ║
    ╠══════════════════════════════════════════════════════╣
    ║  All traffic → Tor     DNS → Encrypted               ║
    ║  MAC → Randomized      Firewall → Inbound blocked    ║
    ║  Kernel → Hardened     USB → Guarded                 ║
    ╠══════════════════════════════════════════════════════╣
    ║  Type 'faraday-status' to check security services   ║
    ╚══════════════════════════════════════════════════════╝

  '';

  # ---------------------------------------------------------------------------
  # FARADAY STATUS COMMAND
  # Quick security dashboard — shows what's running/not
  # ---------------------------------------------------------------------------
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "faraday-status" ''
      echo ""
      echo "╔══════════════════════════════════════╗"
      echo "║       FARADAY SECURITY STATUS        ║"
      echo "╚══════════════════════════════════════╝"
      echo ""

      check() {
        local name="$1"
        local cmd="$2"
        if eval "$cmd" > /dev/null 2>&1; then
          printf "  \033[32m●\033[0m %-20s \033[32mACTIVE\033[0m\n" "$name"
        else
          printf "  \033[31m●\033[0m %-20s \033[31mINACTIVE\033[0m\n" "$name"
        fi
      }

      check "Tor"          "systemctl is-active tor"
      check "Firewall"     "systemctl is-active nftables"
      check "AppArmor"     "systemctl is-active apparmor"
      check "USBGuard"     "systemctl is-active usbguard"
      check "DNSCrypt"     "systemctl is-active dnscrypt-proxy"
      check "Mullvad VPN"  "systemctl is-active mullvad-daemon"

      echo ""
      echo "  Tor IP:"
      torify curl -s https://api.ipify.org 2>/dev/null || echo "    (unavailable)"
      echo ""

      echo "  MAC (wlan0):"
      ip link show wlan0 2>/dev/null | grep "link/ether" | awk '{print "    "$2}' || echo "    (no wifi)"
      echo ""
    '')
  ];
}
