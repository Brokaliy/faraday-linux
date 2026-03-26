{ config, pkgs, lib, ... }:

# =============================================================================
# FARADAY NETWORKING MODULE
# All traffic routed through Tor. MAC randomization. DNS over Tor.
# Mullvad VPN available as an opt-in layer on top of Tor.
# Firewall blocks all inbound by default.
# =============================================================================

{
  # ---------------------------------------------------------------------------
  # DISABLE IPV6 (belt-and-suspenders — also done in hardening.nix sysctl)
  # IPv6 does not route through Tor by default — any v6 traffic leaks identity.
  # We disable it at the network stack level to prevent accidental leaks.
  # ---------------------------------------------------------------------------
  networking.enableIPv6 = false;

  # ---------------------------------------------------------------------------
  # HOSTNAME — generic, non-identifying
  # ---------------------------------------------------------------------------
  networking.hostName = "faraday";
  networking.domain = "local";

  # ---------------------------------------------------------------------------
  # NETWORKMANAGER + MAC RANDOMIZATION
  # Random MAC address on every new connection prevents tracking across
  # different networks (coffee shops, hotels, airports).
  # ---------------------------------------------------------------------------
  networking.networkmanager = {
    enable = true;

    ethernet.macAddress = "random";
    wifi = {
      macAddress = "random";
      # Randomize MAC even during scan probes — prevents pre-association tracking
      scanRandMacAddress = true;
    };

    # Use dnscrypt-proxy for DNS resolution (see below)
    dns = "none"; # NM won't manage DNS; we handle it ourselves
  };

  # Additional MAC randomization via macchanger at service start
  # (belt-and-suspenders for interfaces NM might miss)
  systemd.services.macchanger = {
    description = "Randomize MAC address on boot";
    wantedBy = [ "multi-user.target" ];
    before = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.macchanger}/bin/macchanger -r %i";
    };
  };

  # ---------------------------------------------------------------------------
  # TOR — transparent proxy for ALL traffic
  #
  # How it works:
  #   1. Tor opens a TransparentPort (9040) for TCP and DNSPort (5353) for DNS
  #   2. nftables redirects ALL outbound TCP → 9040 (except Tor's own traffic)
  #   3. DNS queries redirected → 5353 (answered by Tor, so DNS never leaks)
  #   4. UDP (non-DNS) is blocked — Tor doesn't support UDP (except DNS)
  #
  # This is the "TransProxy" setup used by Tails and Whonix.
  # ---------------------------------------------------------------------------
  services.tor = {
    enable = true;

    client = {
      enable = true;
      # SOCKS5 proxy for apps that support it natively (curl, Firefox, etc.)
      socksListenAddress = {
        addr = "127.0.0.1";
        port = 9050;
      };
    };

    settings = {
      # Transparent proxy port — nftables sends all TCP here
      TransPort = [ { addr = "127.0.0.1"; port = 9040; } ];

      # DNS port — nftables sends all DNS here; Tor resolves via exit node
      DNSPort = [ { addr = "127.0.0.1"; port = 5353; } ];

      # Map .onion hostnames without needing a real DNS lookup
      AutomapHostsOnResolve = true;
      AutomapHostsSuffixes = [ ".onion" ".exit" ];

      # Isolate streams by destination port (better anonymity)
      IsolateDestPort = true;

      # Use only high-bandwidth, high-stability relays for guard nodes
      StrictNodes = true;

      # Avoid certain countries as exit nodes (optional — comment out to remove)
      # ExcludeExitNodes = "{us},{uk},{au},{ca},{nz}"; # Five Eyes

      # Reduce latency — use 3 hops (default, don't go lower)
      # NumEntryGuards = 3;

      # Log minimally — don't write anything identifying to disk
      SafeLogging = true;
      Log = "notice stdout";
    };
  };

  # ---------------------------------------------------------------------------
  # NFTABLES — force all traffic through Tor
  #
  # Rules:
  #   - OUTPUT chain intercepts all traffic from non-tor processes
  #   - DNS (UDP/TCP 53) → Tor DNSPort 5353
  #   - All TCP → Tor TransPort 9040
  #   - All UDP (non-DNS) → DROP (Tor can't proxy UDP, better to drop than leak)
  #   - INPUT chain blocks all inbound by default
  # ---------------------------------------------------------------------------
  networking.nftables = {
    enable = true;
    ruleset = ''
      # =========================================================
      # FARADAY FIREWALL — Tor transparent proxy + inbound block
      # =========================================================

      table inet faraday {

        # ---------------------------------------------------------
        # INBOUND — block everything, allow established/loopback
        # ---------------------------------------------------------
        chain input {
          type filter hook input priority 0; policy drop;

          # Allow established/related connections
          ct state { established, related } accept

          # Allow loopback
          iif lo accept

          # Drop invalid packets
          ct state invalid drop

          # Allow ICMP (within the machine) but not from outside
          # Comment this out for full ICMP silence
          # icmp type echo-request drop
        }

        # ---------------------------------------------------------
        # FORWARD — this is a workstation, not a router
        # ---------------------------------------------------------
        chain forward {
          type filter hook forward priority 0; policy drop;
        }

        # ---------------------------------------------------------
        # OUTPUT — NAT redirect to Tor (transparent proxy)
        # ---------------------------------------------------------
        chain output_nat {
          type nat hook output priority -100;

          # Exempt Tor process itself (uid 'tor') from redirection
          # — otherwise it would loop back into itself
          meta skuid tor return

          # Loopback traffic doesn't need to go through Tor
          oif lo return

          # Redirect DNS (UDP + TCP port 53) to Tor's DNSPort
          udp dport 53 redirect to :5353
          tcp dport 53 redirect to :5353

          # Redirect all TCP to Tor's TransPort
          tcp redirect to :9040
        }

        chain output_filter {
          type filter hook output priority 0; policy accept;

          # Allow Tor process to reach the internet directly
          meta skuid tor accept

          # Allow loopback
          oif lo accept

          # Drop UDP (non-DNS) — Tor can't proxy it, so it must not leak
          # This blocks WebRTC, NTP (we use systemd-timesyncd over TCP), etc.
          udp drop

          # Allow established TCP
          ct state { established, related } accept

          # Allow new TCP (will be caught by NAT chain above and redirected to Tor)
          tcp ct state new accept
        }
      }
    '';
  };

  # ---------------------------------------------------------------------------
  # DNSCRYPT-PROXY
  # Handles DNS-over-HTTPS for any DNS that might not go through Tor
  # (e.g. during boot before Tor starts, or for Tor's own lookups).
  # Also provides a fallback encrypted DNS layer.
  # ---------------------------------------------------------------------------
  services.dnscrypt-proxy = {
    enable = true;
    settings = {
      # Listen on a non-standard port to not conflict with Tor's DNSPort
      listen_addresses = [ "127.0.0.1:5300" ];

      # Only use DNS servers that:
      # - Support DNS-over-HTTPS (doh)
      # - Have no-logs policy
      # - Don't filter content
      require_dnssec = true;
      require_nolog = true;
      require_nofilter = true;

      # Preferred privacy-respecting DoH servers
      server_names = [
        "mullvad-doh"           # Mullvad's no-log DoH
        "quad9-doh-ip4-port443-filter-pri" # Quad9 (malware blocking, no logs)
        "cloudflare"            # Fallback
      ];

      # Randomize which server answers each query — harder to correlate
      lb_strategy = "random";

      # Cache responses to reduce DNS query volume (less to correlate)
      cache = true;
      cache_size = 512;
      cache_min_ttl = 600;
      cache_max_ttl = 86400;

    };
  };

  # Point resolv.conf at dnscrypt-proxy for pre-Tor fallback
  networking.nameservers = [ "127.0.0.1" ];
  services.resolved = {
    enable = false; # We manage DNS manually
  };

  environment.etc."resolv.conf" = {
    text = ''
      # Faraday: DNS handled by dnscrypt-proxy → Tor
      nameserver 127.0.0.1
      options ndots:0
    '';
    mode = "0444";
  };

  # ---------------------------------------------------------------------------
  # MULLVAD VPN
  # Optional second layer: Tor over Mullvad or Mullvad over Tor.
  # Default: off in live session. User enables it manually.
  # ---------------------------------------------------------------------------
  services.mullvad-vpn = {
    enable = true;
    # enableExcludeApp = true; # Allow split-tunneling if needed
  };

  # ---------------------------------------------------------------------------
  # FIREWALL (fallback — nftables above is primary)
  # NixOS's simple firewall module as belt-and-suspenders
  # ---------------------------------------------------------------------------
  networking.firewall = {
    enable = true;
    allowedTCPPorts = []; # No inbound ports open
    allowedUDPPorts = [];
    logRefusedConnections = true;
    logRefusedPackets = true;
    rejectPackets = false; # DROP (not REJECT) — don't reveal we're here
    # Deny ping from outside
    allowPing = false;
  };

  # ---------------------------------------------------------------------------
  # NETWORK WAIT — don't start user services until Tor is connected
  # ---------------------------------------------------------------------------
  systemd.services.tor-wait = {
    description = "Wait for Tor to build a circuit";
    after = [ "tor.service" ];
    requires = [ "tor.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "tor-wait" ''
        echo "Waiting for Tor circuit..."
        for i in $(seq 1 60); do
          if ${pkgs.tor}/bin/torify ${pkgs.curl}/bin/curl -s --max-time 5 https://check.torproject.org/api/ip | grep -q '"IsTor":true'; then
            echo "Tor circuit established."
            exit 0
          fi
          sleep 2
        done
        echo "WARNING: Could not confirm Tor circuit after 120s"
        exit 0  # Don't block boot — Tor might still be working
      '';
    };
  };
}
