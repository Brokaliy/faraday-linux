#!/usr/bin/env bash
# =============================================================================
# FARADAY LINUX — BUILD SCRIPT
# Produces a bootable ISO using nixos-generators.
#
# Prerequisites:
#   - Nix with flakes enabled: ~/.config/nix/nix.conf → "experimental-features = nix-command flakes"
#   - nixos-generators (fetched automatically via flake.nix)
#   - ~8GB free disk space (NixOS ISO build)
#   - ~4GB RAM minimum
#
# Usage:
#   ./build.sh          → build ISO (default)
#   ./build.sh vm       → build QEMU VM for testing
#   ./build.sh run      → build VM and launch it immediately
#   ./build.sh clean    → clean build artifacts
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/result"
LOG_FILE="$SCRIPT_DIR/build.log"

# --- Colors ---
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${CYAN}[faraday]${NC} $*"; }
ok()   { echo -e "${GREEN}[  ok  ]${NC} $*"; }
err()  { echo -e "${RED}[ err  ]${NC} $*" >&2; }
warn() { echo -e "${YELLOW}[ warn ]${NC} $*"; }

print_banner() {
  echo -e "${CYAN}"
  echo "╔══════════════════════════════════════════════════╗"
  echo "║           FARADAY LINUX  —  BUILD SYSTEM         ║"
  echo "║        Privacy-first NixOS ISO Generator         ║"
  echo "╚══════════════════════════════════════════════════╝"
  echo -e "${NC}"
}

check_prereqs() {
  log "Checking prerequisites..."

  if ! command -v nix &>/dev/null; then
    err "Nix is not installed. Install from https://nixos.org/download"
    exit 1
  fi

  # Check flakes are enabled
  if ! nix flake --help &>/dev/null 2>&1; then
    err "Nix flakes are not enabled."
    echo "Add this to ~/.config/nix/nix.conf or /etc/nix/nix.conf:"
    echo "  experimental-features = nix-command flakes"
    exit 1
  fi

  # Check assets exist
  if [ ! -f "$SCRIPT_DIR/assets/wallpaper.png" ]; then
    warn "assets/wallpaper.png not found — using placeholder"
    # Create a placeholder so the build doesn't fail
    mkdir -p "$SCRIPT_DIR/assets"
    # Generate a simple blue PNG placeholder using ImageMagick if available
    if command -v convert &>/dev/null; then
      convert -size 1920x1080 \
        gradient:'#0a0e1a-#0d1f3c' \
        -fill none -stroke '#00d4ff22' \
        -draw "rectangle 0,0 1920,1080" \
        "$SCRIPT_DIR/assets/wallpaper.png"
      ok "Generated placeholder wallpaper"
    else
      # Tiny 1x1 blue PNG (base64 encoded)
      echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==" \
        | base64 -d > "$SCRIPT_DIR/assets/wallpaper.png"
      warn "Created minimal placeholder wallpaper (replace with real design)"
    fi
  fi

  if [ ! -f "$SCRIPT_DIR/assets/logo.svg" ]; then
    warn "assets/logo.svg not found — creating placeholder"
    mkdir -p "$SCRIPT_DIR/assets"
    cat > "$SCRIPT_DIR/assets/logo.svg" << 'SVGEOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">
  <!-- Faraday cage pattern -->
  <rect width="200" height="200" fill="#0a0e1a"/>
  <!-- Cage grid lines (cyan) -->
  <g stroke="#00d4ff" stroke-width="1.5" fill="none" opacity="0.6">
    <line x1="40" y1="20" x2="40" y2="180"/>
    <line x1="80" y1="20" x2="80" y2="180"/>
    <line x1="120" y1="20" x2="120" y2="180"/>
    <line x1="160" y1="20" x2="160" y2="180"/>
    <line x1="20" y1="40" x2="180" y2="40"/>
    <line x1="20" y1="80" x2="180" y2="80"/>
    <line x1="20" y1="120" x2="180" y2="120"/>
    <line x1="20" y1="160" x2="180" y2="160"/>
  </g>
  <!-- F letterform -->
  <text x="65" y="130" font-family="monospace" font-size="80"
        font-weight="bold" fill="#00d4ff">F</text>
</svg>
SVGEOF
    ok "Created placeholder logo.svg"
  fi

  # Create calamares assets dir if missing
  mkdir -p "$SCRIPT_DIR/assets/calamares"
  if [ ! -f "$SCRIPT_DIR/assets/calamares/branding.desc" ]; then
    generate_calamares_branding
  fi

  ok "Prerequisites OK"
}

generate_calamares_branding() {
  log "Generating Calamares branding assets..."
  cat > "$SCRIPT_DIR/assets/calamares/branding.desc" << 'EOF'
---
componentName: faraday

welcomeStyleCalamares: true
welcomeExpandingLogo: true

strings:
  productName:         Faraday Linux
  shortProductName:    Faraday
  version:             1.0
  shortVersion:        1.0
  versionedName:       Faraday Linux 1.0
  shortVersionedName:  Faraday 1.0
  bootloaderEntryName: Faraday
  productUrl:          https://faradaylinux.org
  supportUrl:          https://faradaylinux.org/support
  knownIssuesUrl:      https://github.com/yourusername/faraday-linux/issues
  releaseNotesUrl:     https://faradaylinux.org/changelog

images:
  productLogo:        "logo.svg"
  productIcon:        "logo.svg"
  productWelcome:     "wallpaper.png"

slideshow: "show.qml"
EOF

  # Minimal QML slideshow
  cat > "$SCRIPT_DIR/assets/calamares/show.qml" << 'EOF'
/* Faraday Linux installer slideshow */
import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
  id: presentation

  function onActivate() { timer.running = true }
  function onLeave()    { timer.running = false }

  Timer {
    id: timer
    interval: 5000
    repeat: true
    onTriggered: presentation.goToNextSlide()
  }

  Slide {
    Image { source: "slide1.png"; anchors.fill: parent; fillMode: Image.PreserveAspectFit }
    Text {
      anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 40 }
      text: "All your traffic is routed through Tor.\nYour identity stays hidden."
      color: "#00d4ff"; font.pixelSize: 20; horizontalAlignment: Text.AlignHCenter
    }
  }

  Slide {
    Text {
      anchors.centerIn: parent
      text: "Full disk encryption enforced with LUKS2.\nYour data is safe at rest."
      color: "#00d4ff"; font.pixelSize: 20; horizontalAlignment: Text.AlignHCenter
    }
  }

  Slide {
    Text {
      anchors.centerIn: parent
      text: "MAC address randomized on every connection.\nYou can't be tracked across networks."
      color: "#00d4ff"; font.pixelSize: 20; horizontalAlignment: Text.AlignHCenter
    }
  }

  Slide {
    Text {
      anchors.centerIn: parent
      text: "Hardened kernel. AppArmor. USBGuard.\nFaraday keeps attackers out at every level."
      color: "#00d4ff"; font.pixelSize: 20; horizontalAlignment: Text.AlignHCenter
    }
  }
}
EOF

  ok "Calamares branding generated"
}

build_iso() {
  log "Building Faraday Linux ISO..."
  log "This will take 20-60 minutes on first build (compiling packages)"
  log "Subsequent builds are fast (Nix cache)"
  echo ""

  nix build ".#iso" \
    --log-format bar-with-logs \
    -j auto \
    2>&1 | tee "$LOG_FILE"

  if [ -L "$SCRIPT_DIR/result" ]; then
    ISO_PATH=$(readlink -f "$SCRIPT_DIR/result/iso/"*.iso 2>/dev/null || echo "")
    if [ -n "$ISO_PATH" ] && [ -f "$ISO_PATH" ]; then
      ISO_SIZE=$(du -h "$ISO_PATH" | cut -f1)
      echo ""
      ok "ISO built successfully!"
      echo ""
      echo -e "  ${CYAN}Path:${NC} $ISO_PATH"
      echo -e "  ${CYAN}Size:${NC} $ISO_SIZE"
      echo ""
      echo "Write to USB:"
      echo "  sudo dd if=\"$ISO_PATH\" of=/dev/sdX bs=4M status=progress oflag=sync"
      echo ""
      echo "Or test in QEMU:"
      echo "  ./build.sh run"
    fi
  else
    err "Build failed — check $LOG_FILE"
    exit 1
  fi
}

build_vm() {
  log "Building Faraday Linux VM image..."
  nix build ".#vm" \
    --log-format bar-with-logs \
    -j auto \
    2>&1 | tee "$LOG_FILE"
  ok "VM image built"
}

run_vm() {
  build_vm

  VM_SCRIPT=$(find "$SCRIPT_DIR/result/bin" -name "run-*-vm" 2>/dev/null | head -1)
  if [ -n "$VM_SCRIPT" ]; then
    log "Launching VM (close window to exit)..."
    QEMU_OPTS="-m 4096 -smp 2" "$VM_SCRIPT"
  else
    # Manual QEMU launch
    VM_DISK=$(find "$SCRIPT_DIR/result" -name "*.qcow2" 2>/dev/null | head -1)
    if [ -n "$VM_DISK" ]; then
      qemu-system-x86_64 \
        -enable-kvm \
        -m 4096 \
        -smp 2 \
        -vga virtio \
        -display gtk,gl=on \
        -drive "file=$VM_DISK,if=virtio" \
        -net nic -net user \
        -boot d
    else
      err "No VM image found"
      exit 1
    fi
  fi
}

clean() {
  log "Cleaning build artifacts..."
  rm -f "$SCRIPT_DIR/result"
  rm -f "$LOG_FILE"
  nix store gc 2>/dev/null || true
  ok "Cleaned"
}

# --- Main ---
print_banner
check_prereqs

case "${1:-iso}" in
  iso)   build_iso ;;
  vm)    build_vm  ;;
  run)   run_vm    ;;
  clean) clean     ;;
  *)
    echo "Usage: $0 [iso|vm|run|clean]"
    exit 1
    ;;
esac
