"""Static store/capture validation. This does not prove runtime or Console acceptance."""
from __future__ import annotations

import json
import hashlib
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[1]


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def png_size(path: Path) -> tuple[int, int]:
    require(path.is_file(), f"Missing PNG: {path.relative_to(ROOT)}")
    data = path.read_bytes()
    require(data[:8] == b"\x89PNG\r\n\x1a\n" and data[12:16] == b"IHDR", f"Invalid PNG header: {path}")
    return struct.unpack(">II", data[16:24])


def main() -> None:
    listing = json.loads((ROOT / "marketing/store/store-listing.json").read_text(encoding="utf-8"))
    for key, limit in (("title", 30), ("short_description", 80), ("full_description", 4000)):
        require(isinstance(listing[key], str) and 0 < len(listing[key]) <= limit, f"Invalid {key} length")
    require(listing["package_name"] == "com.ethannyakabuski.prismquarry", "Wrong package name")
    require(listing["release_ready"] is False, "This draft must not assert release readiness")
    for filename, expected in (("app-icon-512.png", (512, 512)), ("feature-graphic-1024x500.png", (1024, 500)), ("splash-1080x1920.png", (1080, 1920))):
        require(png_size(ROOT / "marketing" / filename) == expected, f"Wrong dimensions: {filename}")
    for filename in ("privacy-draft.html", "support.html", "data-safety-draft.json"):
        require((ROOT / "marketing/store" / filename).is_file(), f"Missing store draft: {filename}")
    safety = json.loads((ROOT / "marketing/store/data-safety-draft.json").read_text(encoding="utf-8"))
    require(safety["no_data_collected_claim"] is False, "Native SDK collection cannot be declared absent from local storage alone")
    manifest = json.loads((ROOT / "marketing/screenshots/provenance.json").read_text(encoding="utf-8"))
    captures = manifest["captures"]
    capture_root = (ROOT / "marketing/screenshots").resolve()
    for capture in captures:
        relative = Path(capture["path"])
        resolved = (capture_root / relative).resolve()
        require(not relative.is_absolute() and resolved.is_relative_to(capture_root), "Capture path leaves screenshot directory")
        require(png_size(resolved) == (capture["width"], capture["height"]), f"Capture size mismatch: {relative}")
        require(hashlib.sha256(resolved.read_bytes()).hexdigest() == capture.get("sha256"), f"Capture hash mismatch: {relative}")
        for key in ("profile", "description", "method", "device_class"):
            require(bool(capture.get(key)), f"Capture lacks {key}: {relative}")
    if captures:
        source = json.loads((capture_root / manifest["capture_source"]).read_text(encoding="utf-8"))
        for entry in source["runtime_files"]:
            path = (ROOT / entry["path"]).resolve()
            require(path.is_relative_to(ROOT), "Capture source path leaves repository")
            require(path.is_file() and hashlib.sha256(path.read_bytes()).hexdigest() == entry["sha256"], f"Capture source drift: {entry['path']}")
    for name in ("LICENSE", "NOTICE", "review/index.html", "review/style.css", "review/review.js", "public/index.html", "docs/STORE_AND_RELEASE.md"):
        require((ROOT / name).is_file(), f"Missing review/release file: {name}")
    print(f"Store draft validated; lengths {len(listing['title'])}/{len(listing['short_description'])}/{len(listing['full_description'])}; {len(captures)} genuine capture records present.")
    if not captures:
        print("Runtime screenshot evidence remains PENDING; this static pass is not a gameplay pass.")


if __name__ == "__main__":
    main()
