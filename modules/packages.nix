{ config, pkgs, lib, ... }:

# =============================================================================
# FARADAY PACKAGES MODULE
# Privacy-first app selection. Every app chosen because it:
# 1. Has no mandatory cloud account / telemetry
# 2. Works well with Tor
# 3. Supports end-to-end encryption
# =============================================================================

{
  environment.systemPackages = with pkgs; [

    # -------------------------------------------------------------------------
    # BROWSER — Firefox with hardening baked in
    # Better than Tor Browser for everyday use; Tor Browser for max anonymity.
    # -------------------------------------------------------------------------
    firefox-esr          # Extended Support Release — less fingerprinting surface
    tor-browser          # For maximum anonymity (pre-configured, Tor built-in)
    mullvad-browser      # Very secure mullvad browser with their VPN built in

    # -------------------------------------------------------------------------
    # COMMUNICATIONS
    # -------------------------------------------------------------------------
    signal-desktop       # E2E encrypted messaging — zero metadata stored on server
    # element-desktop   # Matrix client — decentralized, E2E with Olm/Megolm
    # Session            # Signal fork, no phone number required

    # -------------------------------------------------------------------------
    # PASSWORD MANAGER
    # -------------------------------------------------------------------------
    keepassxc            # Local, never-cloud password vault. KeePass-compatible.
                         # Use with TOTP, SSH agent integration.

    # -------------------------------------------------------------------------
    # VPN CLIENT
    # -------------------------------------------------------------------------
    mullvad-vpn          # Mullvad: no-logs, accepts cash/Monero, RAM-only servers

    # -------------------------------------------------------------------------
    # TERMINAL
    # -------------------------------------------------------------------------
    kitty                # GPU-accelerated, highly configurable, Wayland-native
    zsh                  # Shell
    oh-my-zsh            # ZSH framework
    starship             # Cross-shell prompt with status info

    # -------------------------------------------------------------------------
    # CLI UTILITIES
    # -------------------------------------------------------------------------
    fastfetch            # System info (replaces neofetch) — Faraday branded
    bat                  # Better cat with syntax highlighting
    eza                  # Better ls with icons
    fd                   # Better find
    ripgrep              # Better grep
    fzf                  # Fuzzy finder
    jq                   # JSON processor
    curl                 # HTTP client (use via torify)
    wget
    htop                 # Process monitor
    btop                 # Better process monitor
    ncdu                 # Disk usage explorer

    # -------------------------------------------------------------------------
    # PRIVACY / SECURITY TOOLS
    # -------------------------------------------------------------------------
    tor                  # Tor daemon (also pulled in by services.tor)
    torsocks             # Wrapper to torify any application
    torctl               # Tor control script
    macchanger           # MAC address randomization
    nmap                 # Network scanner (for your own network auditing)
    wireshark            # Network analyzer (for local traffic inspection)
    aircrack-ng          # WiFi security auditing
    openssl              # Crypto primitives, cert inspection
    gnupg                # PGP encryption/signing
    age                  # Modern file encryption (simpler than GPG)
    veracrypt            # Encrypted containers / full-disk encryption GUI
    mat2                 # Metadata stripping from files (images, PDFs, docs)

    # -------------------------------------------------------------------------
    # FILE MANAGEMENT
    # -------------------------------------------------------------------------
    kdePackages.dolphin   # KDE file manager
    grim                  # Screenshot (Wayland)
    slurp                 # Region selector for screenshots
    kdePackages.spectacle # KDE screenshot tool

    # -------------------------------------------------------------------------
    # MEDIA (minimal — only what's needed)
    # -------------------------------------------------------------------------
    mpv                  # Video player — no telemetry, highly sandboxable
    imv                  # Image viewer (Wayland)

    # -------------------------------------------------------------------------
    # OFFICE / DOCUMENTS
    # -------------------------------------------------------------------------
    libreoffice-fresh       # Office suite — open formats, no cloud
    kdePackages.okular      # KDE PDF/document viewer

    # -------------------------------------------------------------------------
    # KDE UTILITIES
    # -------------------------------------------------------------------------
    kdePackages.ark          # Archive manager (zip/tar/7z)
    kdePackages.kleopatra    # GPG/certificate manager
    kdePackages.gwenview     # Image viewer
    kdePackages.kalarm       # Alarm/reminder app

    # -------------------------------------------------------------------------
    # SYSTEM TOOLS
    # -------------------------------------------------------------------------
    usbguard             # USB device control (also in services)
    udiskie              # Automount removable media
    gparted              # Partition editor

    # -------------------------------------------------------------------------
    # COMMUNICATIONS
    # -------------------------------------------------------------------------
    thunderbird          # Email — configure with Tor SOCKS5 proxy
    onionshare           # Secure file sharing over Tor hidden service
    element-desktop      # Matrix client — E2E encrypted, decentralized
    vesktop              # Discord client for Linux — no broken self-updater
    telegram-desktop     # Telegram — E2E secret chats

    # -------------------------------------------------------------------------
    # SECURITY & PENTESTING
    # -------------------------------------------------------------------------
    john                 # Password cracker (John the Ripper)
    hashcat              # GPU password cracker
    thc-hydra            # Network login brute-forcer
    sqlmap               # SQL injection scanner
    nikto                # Web server vulnerability scanner
    netcat-openbsd       # TCP/UDP network tool
    tcpdump              # Packet capture
    proxychains-ng       # Proxy chaining for any app
    steghide             # Steganography tool
    binwalk              # Firmware / binary analysis
    yara                 # Malware pattern matching
    clamav               # Antivirus scanner
    lynis                # Security auditing

    firejail             # App sandboxing
    i2pd                 # I2P anonymous network
    masscan              # Fast port scanner
    gobuster             # Directory / DNS brute-forcer
    ffuf                 # Web fuzzer
    electrum             # Bitcoin wallet

    # -------------------------------------------------------------------------
    # DEVELOPMENT
    # -------------------------------------------------------------------------
    vscodium             # VSCode without Microsoft telemetry
    git
    vim
    neovim

  ];

  # ---------------------------------------------------------------------------
  # FIREFOX HARDENING
  # Deploy a hardened user.js (arkenfox-based) for the system Firefox profile.
  # This configures Firefox to:
  # - Route all traffic through Tor SOCKS proxy
  # - Disable WebRTC (leaks real IP even with proxy)
  # - Disable telemetry, pocket, sync
  # - Enable strict tracking protection
  # ---------------------------------------------------------------------------
  programs.firefox = {
    enable = true;
    # Policies apply to all profiles system-wide
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableFirefoxAccounts = true;
      DisableFormHistory = true;
      DisablePasswordReveal = true;

      # Force HTTPS everywhere
      HttpsOnlyMode = "force_enabled";

      # Disable crash reporter (sends data to Mozilla)
      DisableFeedbackCommands = true;

      # Search engine — use DuckDuckGo (or configure Tor hidden search)
      SearchEngines = {
        Default = "DuckDuckGo";
        Remove = [ "Google" "Bing" "Amazon" "eBay" ];
      };

      # Extensions — install hardening extensions by default
      ExtensionSettings = {
        # uBlock Origin
        "uBlock0@raymondhill.net" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };
        # Privacy Badger
        "jid1-MnnxcxisBPnSXQ@jetpack" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
        };
        # ClearURLs — strips tracking parameters from URLs
        "{74145f27-f039-47ce-a470-a662b129930a}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/clearurls/latest.xpi";
        };
      };

      # Preferences (user.js equivalent via policy)
      Preferences = {
        # Route all Firefox traffic through Tor SOCKS5 proxy
        "network.proxy.type" = { Value = 1; Status = "locked"; };
        "network.proxy.socks" = { Value = "127.0.0.1"; Status = "locked"; };
        "network.proxy.socks_port" = { Value = 9050; Status = "locked"; };
        "network.proxy.socks_version" = { Value = 5; Status = "locked"; };
        "network.proxy.socks_remote_dns" = { Value = true; Status = "locked"; };

        # Disable WebRTC — CRITICAL: WebRTC bypasses proxies and leaks real IP
        "media.peerconnection.enabled" = { Value = false; Status = "locked"; };
        "media.peerconnection.ice.no_host" = { Value = true; Status = "locked"; };

        # Disable Geolocation
        "geo.enabled" = { Value = false; Status = "locked"; };
        "geo.provider.use_gpsd" = { Value = false; Status = "locked"; };

        # Disable telemetry
        "datareporting.healthreport.uploadEnabled" = { Value = false; Status = "locked"; };
        "datareporting.policy.dataSubmissionEnabled" = { Value = false; Status = "locked"; };
        "toolkit.telemetry.enabled" = { Value = false; Status = "locked"; };
        "toolkit.telemetry.unified" = { Value = false; Status = "locked"; };

        # Disable prefetch (pre-loads pages you haven't visited — leaks browsing intent)
        "network.prefetch-next" = { Value = false; Status = "locked"; };
        "network.dns.disablePrefetch" = { Value = true; Status = "locked"; };
        "network.predictor.enabled" = { Value = false; Status = "locked"; };

        # Resist fingerprinting
        "privacy.resistFingerprinting" = { Value = true; Status = "locked"; };
        "privacy.resistFingerprinting.letterboxing" = { Value = true; Status = "locked"; };

        # Tracking protection
        "privacy.trackingprotection.enabled" = { Value = true; Status = "locked"; };
        "privacy.trackingprotection.socialtracking.enabled" = { Value = true; Status = "locked"; };

        # First-party isolation — prevents cross-site cookie tracking
        "privacy.firstparty.isolate" = { Value = true; Status = "locked"; };

        # Clear history/cookies on close
        "privacy.sanitize.sanitizeOnShutdown" = { Value = true; Status = "locked"; };
        "privacy.clearOnShutdown.cookies" = { Value = true; Status = "locked"; };
        "privacy.clearOnShutdown.cache" = { Value = true; Status = "locked"; };
      };
    };
  };

  # ---------------------------------------------------------------------------
  # DEFAULT SHELL
  # Fish is the default interactive shell (friendly, fast, good completions).
  # Bash remains the system shell (/bin/sh) for scripts.
  # Shell configs, aliases, and no-history policy are all in modules/shell.nix.
  # ---------------------------------------------------------------------------
  users.defaultUserShell = pkgs.fish;

  # ---------------------------------------------------------------------------
  # GPG + SSH AGENT
  # ---------------------------------------------------------------------------
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    # Store keys in RAM only when possible
    pinentryPackage = pkgs.pinentry-gtk2;
  };
}
