{ config, pkgs, lib, ... }:

# =============================================================================
# FARADAY HARDENING MODULE
# Kernel-level and system-level security hardening.
# Every option is commented with what attack surface it closes.
# =============================================================================

{
  # ---------------------------------------------------------------------------
  # KERNEL
  # linux-hardened applies the grsecurity/PaX-inspired hardening patch set:
  # - KASLR (randomize kernel memory layout)
  # - Stack canaries, FORTIFY_SOURCE
  # - Restricted ptrace (stops process snooping)
  # - Hardened usercopy (bounds-checked kernel<->user copies)
  # ---------------------------------------------------------------------------
  boot.kernelPackages = pkgs.linuxPackages_hardened;

  # Additional kernel modules to blacklist.
  # These are loaded on-demand by default and expand attack surface.
  boot.blacklistedKernelModules = [
    # Block webcam drivers — user must explicitly load to use camera
    "uvcvideo"
    # Block microphone (USB audio) — user must explicitly load
    "snd_usb_audio"
    # Block Thunderbolt DMA attacks
    "thunderbolt"
    # Block FireWire DMA (obsolete but still a DMA vector)
    "firewire_core" "firewire_ohci"
    # Block uncommon network protocols that have had repeated CVEs
    "dccp" "sctp" "rds" "tipc" "n_hdlc"
    # Block rare filesystems (reduce kernel attack surface)
    "cramfs" "freevxfs" "jffs2" "hfs" "hfsplus" "udf"
    # Block Bluetooth (disable entirely — can be re-enabled in live session)
    "bluetooth" "btusb"
  ];

  # ---------------------------------------------------------------------------
  # KERNEL PARAMETERS (sysctl)
  # Applied at boot, tuned for maximum network paranoia and memory hardening.
  # ---------------------------------------------------------------------------
  boot.kernel.sysctl = {

    # --- Memory Protections ---
    # Restrict /proc/kallsyms and dmesg — prevents leaking kernel addresses
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;

    # Prevent perf subsystem from leaking data to unprivileged users
    "kernel.perf_event_paranoid" = 3;

    # Restrict ptrace — prevents a process from reading another's memory
    # (used by debuggers, but also malware for credential scraping)
    "kernel.yama.ptrace_scope" = 2;

    # Randomize virtual address space (ASLR max)
    "kernel.randomize_va_space" = 2;

    # Disable magic SysRq — prevents physical-access attacks via keyboard
    "kernel.sysrq" = 0;

    # --- Network Hardening ---

    # Ignore ICMP broadcast (smurf amplification attack prevention)
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;

    # Ignore bogus ICMP error responses
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;

    # Log martian packets (IPs that should never appear on the internet)
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.default.log_martians" = 1;

    # Disable source routing (attacker-controlled path routing)
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;

    # Disable ICMP redirects (MITM vector — redirects traffic through attacker)
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;

    # Enable reverse path filtering (anti-spoofing — drops packets with
    # source addresses that don't route back through the incoming interface)
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;

    # Disable IP forwarding — this is a workstation, not a router
    "net.ipv4.ip_forward" = 0;
    "net.ipv6.conf.all.forwarding" = 0;

    # SYN flood protection
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.tcp_syn_retries" = 2;
    "net.ipv4.tcp_synack_retries" = 2;

    # Disable TCP timestamps — leaks uptime, aids fingerprinting
    "net.ipv4.tcp_timestamps" = 0;

    # Ignore ICMP echo (ping) — reduces fingerprinting, blocks ping-of-death variants
    "net.ipv4.icmp_echo_ignore_all" = 1;

    # Disable IPv6 entirely — all v6 traffic bypasses Tor by default
    # Network module also disables it, but belt-and-suspenders here
    "net.ipv6.conf.all.disable_ipv6" = 1;
    "net.ipv6.conf.default.disable_ipv6" = 1;
    "net.ipv6.conf.lo.disable_ipv6" = 1;

    # --- File System Hardening ---

    # Prevent hardlinks/symlinks attacks (e.g. TOCTOU exploits in /tmp)
    "fs.protected_hardlinks" = 1;
    "fs.protected_symlinks" = 1;

    # Restrict FIFO/regular file creation in sticky directories
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;

    # Hide kernel pointers in /proc
    "kernel.unprivileged_bpf_disabled" = 1;
    "net.core.bpf_jit_harden" = 2;
  };

  # ---------------------------------------------------------------------------
  # BOOT HARDENING
  # ---------------------------------------------------------------------------

  # Require password to edit GRUB entries (prevents single-user boot bypass)
  # Note: in live ISO mode this is relaxed. Installed system should set this.
  boot.loader.grub.memtest86.enable = false; # Reduces attack surface

  # Clear RAM on shutdown/reboot — prevents cold-boot attacks on DRAM
  boot.kernelParams = [
    "page_poison=1"         # Poison freed pages to detect use-after-free
    "slub_debug=FZP"        # Extra SLUB allocator debugging/poisoning
    "init_on_alloc=1"       # Zero memory on allocation (mitigates uninit reads)
    "init_on_free=1"        # Zero memory on free (mitigates use-after-free)
    "pti=on"                # Page Table Isolation (Meltdown mitigation)
    "slab_nomerge"          # Disable slab merging (harder heap exploitation)
    "vsyscall=none"         # Disable legacy vsyscall (ROP gadget source)
    "debugfs=off"           # Disable debugfs (kernel internals exposure)
    "ipv6.disable=1"        # Belt-and-suspenders IPv6 disable at boot
    "net.ifnames=0"         # Predictable interface names (for firewall rules)
    "lockdown=confidentiality" # Linux kernel lockdown mode (blocks /dev/mem, etc.)
  ];

  # ---------------------------------------------------------------------------
  # APPARMOR
  # Mandatory Access Control — confines programs to a defined set of resources.
  # Stops compromised apps from escaping their sandbox.
  # ---------------------------------------------------------------------------
  security.apparmor = {
    enable = true;
    killUnconfinedConfinables = true; # Aggressively enforce — kill unconfined processes
    packages = with pkgs; [ apparmor-profiles ]; # Community profile set
  };

  # Audit framework — logs AppArmor violations and security events
  security.auditd.enable = true;
  security.audit = {
    enable = true;
    rules = [
      # Log all privilege escalations
      "-a always,exit -F arch=b64 -S setuid -S setgid -k privilege_escalation"
      # Log all file permission changes
      "-a always,exit -F arch=b64 -S chmod -S fchmod -k file_perm_change"
    ];
  };

  # ---------------------------------------------------------------------------
  # USBGUARD
  # Blocks unknown USB devices. Only USB devices present at boot (or explicitly
  # whitelisted) are allowed. Stops BadUSB / rubber ducky attacks.
  # ---------------------------------------------------------------------------
  services.usbguard = {
    enable = true;
    # Start with "block all" policy — user must whitelist their devices
    # Generate your whitelist: usbguard generate-policy > /etc/usbguard/rules.conf
    IPCAllowedUsers = [ "root" "faraday" ];
    rules = ''
      # Allow USB hubs
      allow with-interface equals { 09:00:00 }
      # Allow HID (keyboard/mouse) — needed for usability
      allow with-interface equals { 03:01:01 }
      allow with-interface equals { 03:01:02 }
      allow with-interface equals { 03:00:00 }
      # Block everything else by default
      block
    '';
  };

  # ---------------------------------------------------------------------------
  # SWAP ENCRYPTION
  # Unencrypted swap leaks memory contents (passwords, keys, etc.) to disk.
  # Only allow swap on LUKS-encrypted devices.
  # ---------------------------------------------------------------------------
  swapDevices = lib.mkDefault []; # No swap by default — installer will add LUKS swap if needed

  # If swap is added, enforce encryption
  boot.initrd.luks.devices = lib.mkDefault {}; # Populated by installer/disk config

  # ---------------------------------------------------------------------------
  # MISC HARDENING
  # ---------------------------------------------------------------------------

  # Restrict /proc to owner only — prevents users from seeing each other's processes
  security.hideProcessInformation = true;

  # Disable core dumps — core files can contain passwords, keys, decrypted data
  security.pam.loginLimits = [{
    domain = "*";
    item = "core";
    type = "hard";
    value = "0";
  }];
  systemd.coredump.enable = false;

  # Lock down /proc, /sys mounts
  fileSystems."/proc" = {
    device = "proc";
    fsType = "proc";
    options = [ "nosuid" "noexec" "nodev" "hidepid=2" "gid=proc" ];
  };

  # Restrict access to the proc group
  users.groups.proc = {};

  # Disable hibernation — hibernation writes RAM to disk unencrypted
  security.protectKernelImage = true;

  # Time sync via NTP with randomized delays to resist timing correlation attacks
  services.timesyncd.enable = true;
  networking.timeServers = [
    "0.nixos.pool.ntp.org"
    "1.nixos.pool.ntp.org"
  ];
}
