#!/usr/bin/env bash
set -euo pipefail

# Scripts to remove packages from OPKG feed directories and update the index
# Usage: ./scripts/remove_package.sh <pattern_or_filename> [arch] [--commit] [--dry-run]

PATTERN=""
ARCH=""
DO_COMMIT=false
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        --commit|-c)
            DO_COMMIT=true
            ;;
        --dry-run|-n)
            DRY_RUN=true
            ;;
        *)
            if [ -z "$PATTERN" ]; then
                PATTERN="$arg"
            elif [ -z "$ARCH" ]; then
                ARCH="$arg"
            fi
            ;;
    esac
done

if [ -z "$PATTERN" ]; then
    echo "Usage: $0 <pattern_or_filename> [arch] [--commit] [--dry-run]"
    echo ""
    echo "Examples:"
    echo "  $0 '*1.0.0*' cortexa15hf-neon-vfpv4"
    echo "  $0 'enigma2-plugin-extensions-canalplus-connect_1.0.0-atv76_cortexa15hf-neon-vfpv4.ipk'"
    echo "  $0 '*1.0.0*' cortexa15hf-neon-vfpv4 --commit"
    exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Search scope
if [ -n "$ARCH" ]; then
    SEARCH_DIR="${REPO_ROOT}/${ARCH}"
    if [ ! -d "$SEARCH_DIR" ]; then
        echo "[ERROR] Architecture directory not found: ${SEARCH_DIR}"
        exit 1
    fi
else
    SEARCH_DIR="${REPO_ROOT}"
fi

echo "=== Searching for packages matching: '${PATTERN}' in ${SEARCH_DIR} ==="

MATCHES=()
while IFS= read -r -d '' file; do
    MATCHES+=("$file")
done < <(find "$SEARCH_DIR" -maxdepth 2 -name "$PATTERN" -name "*.ipk" -print0)

if [ ${#MATCHES[@]} -eq 0 ]; then
    echo "[INFO] No matching .ipk packages found."
    exit 0
fi

echo "Found ${#MATCHES[@]} matching package(s):"
for m in "${MATCHES[@]}"; do
    echo "  - $(basename "$m") (${m#$REPO_ROOT/})"
done

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "[DRY-RUN] No files were removed."
    exit 0
fi

echo ""
echo "--> Removing packages..."
AFFECTED_ARCHES=()
for m in "${MATCHES[@]}"; do
    arch_dir="$(dirname "$m")"
    arch_name="$(basename "$arch_dir")"
    rm -f "$m"
    echo "  ✓ Removed: ${m#$REPO_ROOT/}"
    if [[ ! " ${AFFECTED_ARCHES[*]} " =~ " ${arch_name} " ]]; then
        AFFECTED_ARCHES+=("$arch_name")
    fi
done

echo ""
echo "--> Rebuilding feed index..."
for arch in "${AFFECTED_ARCHES[@]}"; do
    python3 "${REPO_ROOT}/scripts/update_index.py" "$arch"
done

if [ "$DO_COMMIT" = true ]; then
    echo ""
    echo "--> Committing and pushing changes..."
    cd "$REPO_ROOT"
    git add -A
    if git diff --staged --quiet; then
        echo "No changes to commit."
    else
        git commit -m "chore(feed): remove package(s) matching '${PATTERN}'"
        git push origin main
        echo "  ✓ Changes committed and pushed to main."
    fi
else
    echo ""
    echo "Done! To commit and push changes, run:"
    echo "  git add -A"
    echo "  git commit -m \"chore(feed): remove package(s) matching '${PATTERN}'\""
    echo "  git push origin main"
fi
