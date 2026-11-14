"""Check actual Web export bytes and Godot 4.5.1 PCK v3 entries, not browser play.

Format reference: Godot 4.5.1 core/io/file_access_pack.cpp (official source).
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct


def check(folder: Path) -> dict:
    html = (folder / "index.html").read_text(encoding="utf-8")
    if not re.search(r"const GODOT_THREADS_ENABLED\s*=\s*false\s*;", html):
        raise ValueError("Export is not marked single-threaded")
    wasm = (folder / "index.wasm").read_bytes()
    if wasm[:8] != b"\0asm\x01\0\0\0":
        raise ValueError("Invalid WebAssembly header")
    blob = (folder / "index.pck").read_bytes()
    if blob[:4] != b"GDPC" or struct.unpack_from("<4I", blob, 4) != (3, 4, 5, 1):
        raise ValueError("Expected standalone PCK v3 from Godot 4.5.1")
    flags, file_base, directory = struct.unpack_from("<IQQ", blob, 20)
    if flags != 2 or not 112 <= file_base <= directory < len(blob) - 4:
        raise ValueError("Unexpected encrypted/sparse pack or invalid offsets")
    count = struct.unpack_from("<I", blob, directory)[0]
    position = directory + 4
    files = {}
    for _ in range(count):
        length = struct.unpack_from("<I", blob, position)[0]
        position += 4
        if not 0 < length <= 16384 or position + length + 36 > len(blob):
            raise ValueError("Invalid PCK directory entry")
        path = blob[position:position + length].rstrip(b"\0").decode("utf-8").removeprefix("res://")
        position += length
        offset, size = struct.unpack_from("<QQ", blob, position)
        position += 16
        expected = blob[position:position + 16]
        position += 16
        entry_flags = struct.unpack_from("<I", blob, position)[0]
        position += 4
        if path in files or ".." in Path(path).parts or entry_flags or file_base + offset + size > directory:
            raise ValueError(f"Invalid or duplicate pack path: {path}")
        data = blob[file_base + offset:file_base + offset + size]
        if hashlib.md5(data).digest() != expected:
            raise ValueError(f"PCK content checksum mismatch: {path}")
        files[path] = size
    required = [
        "project.binary", "game/catalog.json", "assets/audio/manifest.json", "platform/config.json",
        "scenes/main.tscn.remap", "game/main.gdc", "game/run.gdc", "game/profile.gdc",
        "game/chambers.gdc", "game/chambers_legacy.gdc", "game/chamber_expansion_data.gdc",
        "game/cavern.gdc", "game/upgrades.gdc", "platform/services.gdc", "LICENSE", "NOTICE",
    ]
    for path in required:
        if path not in files:
            raise ValueError(f"Missing runtime pack entry: {path}")
    unwanted = [path for path in files if path.startswith(("build/", "tests/", "platform/tests/", "marketing/", "docs/", ".git/")) or ".private." in path or path.endswith((".apk", ".aab", ".keystore", ".jks", ".pfx", ".p12"))]
    if unwanted:
        raise ValueError("Non-runtime/private payload in game pack: " + ", ".join(unwanted))
    return {
        "result": "PASS - static exported-byte validation only", "godot": "4.5.1", "pck_version": 3,
        "pck_entries": count, "all_entry_checksums_verified": True, "web_threads": False,
        "required_entries": required, "unwanted_entries": unwanted, "browser_load_or_gameplay_tested": False,
        "files": {path.name: {"bytes": path.stat().st_size, "sha256": hashlib.sha256(path.read_bytes()).hexdigest()} for path in sorted(folder.iterdir()) if path.is_file()},
        "format_reference": "https://github.com/godotengine/godot/blob/4.5.1-stable/core/io/file_access_pack.cpp",
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("folder", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    result = check(args.folder)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
