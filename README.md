# akeyx Enigma2 OPKG Package Repository

This repository serves as a native **OPKG package feed** for Enigma2 set-top boxes (OpenATV, OpenPLi, Egami, PurE2, BlackHole, etc.). It hosts packages installable directly via `opkg` on Vu+, Octagon, GigaBlue, and other Enigma2 hardware.

---

## 🚀 Quick Setup on Enigma2 Box

Connect to your Enigma2 box via SSH / Telnet and run:

```bash
curl -sSL https://raw.githubusercontent.com/akeyx/enigma2-packages/main/scripts/install_feed.sh | sh
```

This automatically configures the feed and refreshes your package cache.

---

## 🛠️ Manual Feed Configuration

If you prefer to configure the feed manually:

1. Create `/etc/opkg/akeyx-feed.conf` on your box:
   ```bash
   echo "src/gz akeyx-packages https://raw.githubusercontent.com/akeyx/enigma2-packages/main/all" > /etc/opkg/akeyx-feed.conf
   ```

2. Refresh your package index:
   ```bash
   opkg update
   ```

3. Install packages:
   ```bash
   opkg install enigma2-plugin-extensions-canalplus-connect
   ```

---

## 📦 Available Packages

| Package | Architecture | Description |
| :--- | :--- | :--- |
| **`enigma2-plugin-extensions-canalplus-connect`** | `all` | Canal+ Online Native Enigma2 Plugin and Streaming Gateway with Hardware DRM |

---

## ⚙️ Repository Automation & Indexing

The feed index is structured in standard OPKG format:
* **`all/Packages`**: Plaintext index containing package control metadata, sizes, MD5, and SHA256 hashes.
* **`all/Packages.gz`**: Gzip-compressed index fetched by `opkg update`.

### Re-indexing Packages Locally:
To add an `.ipk` and rebuild the feed index locally:
```bash
# 1. Copy your .ipk into the architecture directory:
cp my-package_1.0.0_all.ipk all/

# 2. Run the indexer:
python3 scripts/update_index.py

# 3. Commit and push:
git add all/
git commit -m "feat(feed): add my-package v1.0.0"
git push origin main
```

### GitHub Actions Automation:
This repository includes a GitHub Actions workflow ([`.github/workflows/update-feed.yml`](.github/workflows/update-feed.yml)):
* **Automatic Re-indexing:** Automatically regenerates `Packages` and `Packages.gz` whenever a new `.ipk` is committed or pushed.
* **Remote Dispatch:** Supports manual workflow dispatch with a direct `.ipk` download URL to automatically fetch, place, and re-index releases from other repositories.
