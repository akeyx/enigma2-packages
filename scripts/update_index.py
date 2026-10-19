#!/usr/bin/env python3
"""
Enigma2 / OPKG Repository Indexer
Generates standard 'Packages' and 'Packages.gz' index files for OPKG feeds
by parsing control metadata and calculating hashes for all .ipk archives.
"""

import os
import sys
import io
import gzip
import tarfile
import hashlib
import argparse
from pathlib import Path
from typing import Optional, Dict, List


def parse_control_from_ipk(ipk_path: Path) -> Optional[str]:
    """Extracts the control file content from an .ipk (ar archive) using pure Python."""
    try:
        with open(ipk_path, "rb") as f:
            magic = f.read(8)
            if magic != b"!<arch>\n":
                print(f"[WARN] Not a valid ar archive: {ipk_path}")
                return None

            while True:
                header = f.read(60)
                if len(header) < 60:
                    break

                filename = header[0:16].decode("latin1", errors="replace").strip().rstrip("/")
                size_str = header[48:58].decode("latin1", errors="replace").strip()
                try:
                    file_size = int(size_str)
                except ValueError:
                    break

                file_data = f.read(file_size)
                if file_size % 2 == 1:
                    f.read(1)  # ar archives align headers to 2-byte boundaries

                if filename == "control.tar.gz":
                    with tarfile.open(fileobj=io.BytesIO(file_data), mode="r:gz") as tar:
                        for member in tar.getmembers():
                            if member.name.endswith("control") and not member.isdir():
                                extracted = tar.extractfile(member)
                                if extracted:
                                    return extracted.read().decode("utf-8", errors="replace").strip()
    except Exception as e:
        print(f"[ERROR] Failed to read {ipk_path}: {e}")
    return None


def calculate_hashes(file_path: Path) -> Dict[str, str]:
    """Computes MD5, SHA256 and file size."""
    md5 = hashlib.md5()
    sha256 = hashlib.sha256()
    size = 0

    with open(file_path, "rb") as f:
        while chunk := f.read(65536):
            md5.update(chunk)
            sha256.update(chunk)
            size += len(chunk)

    return {
        "Size": str(size),
        "MD5Sum": md5.hexdigest(),
        "SHA256": sha256.hexdigest(),
    }


def process_directory(feed_dir: Path) -> int:
    """Processes all .ipk files in a directory and creates Packages and Packages.gz."""
    ipk_files = sorted(feed_dir.glob("*.ipk"))
    if not ipk_files:
        print(f"[SKIP] No .ipk files found in {feed_dir}")
        return 0

    print(f"[INDEX] Processing {len(ipk_files)} packages in {feed_dir}...")
    stanzas: List[str] = []

    for ipk in ipk_files:
        control_text = parse_control_from_ipk(ipk)
        if not control_text:
            print(f"[WARN] Skipping {ipk.name} (failed to parse control file)")
            continue

        hashes = calculate_hashes(ipk)

        # Standard OPKG stanza format
        lines = [line.strip() for line in control_text.splitlines() if line.strip()]
        lines.append(f"Filename: {ipk.name}")
        lines.append(f"Size: {hashes['Size']}")
        lines.append(f"MD5Sum: {hashes['MD5Sum']}")
        lines.append(f"SHA256: {hashes['SHA256']}")

        stanza = "\n".join(lines)
        stanzas.append(stanza)
        print(f"  + Added {ipk.name} ({hashes['Size']} bytes)")

    if not stanzas:
        print(f"[WARN] No valid stanzas generated for {feed_dir}")
        return 0

    # Write Packages (plain text)
    packages_content = "\n\n".join(stanzas) + "\n"
    packages_file = feed_dir / "Packages"
    with open(packages_file, "w", encoding="utf-8") as f:
        f.write(packages_content)

    # Write Packages.gz (compressed)
    packages_gz_file = feed_dir / "Packages.gz"
    with gzip.open(packages_gz_file, "wb", compresslevel=9) as f:
        f.write(packages_content.encode("utf-8"))

    print(f"[SUCCESS] Generated {packages_file.name} ({len(packages_content)} bytes)")
    print(f"[SUCCESS] Generated {packages_gz_file.name} ({packages_gz_file.stat().st_size} bytes)")
    return len(stanzas)


def main():
    parser = argparse.ArgumentParser(description="Generate Enigma2 OPKG feed index (Packages / Packages.gz)")
    parser.add_argument("directories", nargs="*", default=["all"], help="Feed directories to index (default: 'all')")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parent.parent
    total = 0

    for target in args.directories:
        target_path = repo_root / target if not Path(target).is_absolute() else Path(target)
        if target_path.exists() and target_path.is_dir():
            total += process_directory(target_path)
        else:
            print(f"[INFO] Directory {target_path} does not exist, skipping.")

    print(f"\nFinished indexing. Total packages processed: {total}")


if __name__ == "__main__":
    main()
