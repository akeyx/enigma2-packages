#!/bin/sh
set -e

# ==============================================================================
# akeyx Enigma2 Package Feed Installer for OpenATV / OpenPLi / Egami / PurE2
# One-line install:
# curl -sSL https://raw.githubusercontent.com/akeyx/enigma2-packages/main/scripts/install_feed.sh | sh
# ==============================================================================

FEED_CONF="/etc/opkg/akeyx-feed.conf"
BASE_URL="https://raw.githubusercontent.com/akeyx/enigma2-packages/main"

echo "=== Installing akeyx Enigma2 Package Feed ==="

if [ ! -d "/etc/opkg" ]; then
    echo "[ERROR] /etc/opkg directory not found. Is this an Enigma2 / OPKG system?"
    exit 1
fi

echo "--> Detecting system architecture from /etc/opkg/arch.conf..."
ARCH_CONF="/etc/opkg/arch.conf"

# Base feed config
cat <<EOF > "${FEED_CONF}"
# akeyx Enigma2 Package Feed (Auto-generated)
EOF

# Detect cortexa15hf-neon-vfpv4 (Vu+ 4K, Octagon SF8008, GigaBlue 4K)
if [ -f "${ARCH_CONF}" ] && grep -q "cortexa15hf-neon-vfpv4" "${ARCH_CONF}"; then
    echo "  + Detected ARM cortex-a15 hardware (cortexa15hf-neon-vfpv4)"
    echo "src/gz akeyx-cortexa15hf ${BASE_URL}/cortexa15hf-neon-vfpv4" >> "${FEED_CONF}"
elif [ -f "${ARCH_CONF}" ] && grep -q "armv7ahf-neon" "${ARCH_CONF}"; then
    echo "  + Detected generic ARMv7 hardware (armv7ahf-neon)"
    echo "src/gz akeyx-armv7a ${BASE_URL}/armv7ahf-neon" >> "${FEED_CONF}"
else
    echo "src/gz akeyx-all ${BASE_URL}/all" >> "${FEED_CONF}"
fi

echo "--> Updated ${FEED_CONF}:"
cat "${FEED_CONF}"

echo "--> Updating OPKG package cache..."
opkg update

echo ""
echo "=== Success! Feed Installed ==="
echo "You can now install packages directly from this repository:"
echo "  opkg install enigma2-plugin-extensions-canalplus-connect"
echo ""
