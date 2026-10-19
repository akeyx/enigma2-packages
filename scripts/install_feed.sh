#!/bin/sh
set -e

# ==============================================================================
# akeyx Enigma2 Package Feed Installer for OpenATV / OpenPLi / Egami / PurE2
# One-line install:
# curl -sSL https://raw.githubusercontent.com/akeyx/enigma2-packages/main/scripts/install_feed.sh | sh
# ==============================================================================

FEED_CONF="/etc/opkg/akeyx-feed.conf"
FEED_URL="https://raw.githubusercontent.com/akeyx/enigma2-packages/main/all"

echo "=== Installing akeyx Enigma2 Package Feed ==="

if [ ! -d "/etc/opkg" ]; then
    echo "[ERROR] /etc/opkg directory not found. Is this an Enigma2 / OPKG system?"
    exit 1
fi

echo "--> Writing feed configuration to ${FEED_CONF}..."
cat <<EOF > "${FEED_CONF}"
# akeyx Enigma2 Package Feed
src/gz akeyx-packages ${FEED_URL}
EOF

echo "--> Updating OPKG package cache..."
opkg update

echo ""
echo "=== Success! Feed Installed ==="
echo "You can now install packages directly from this repository:"
echo "  opkg install enigma2-plugin-extensions-canalplus-connect"
echo ""
