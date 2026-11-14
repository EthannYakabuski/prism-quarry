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


def verify_capture_label_patch(source: dict) -> set[str]:
    """Allow only the documented, unpictured final-chamber button text change.

    Reverse that exact statement and require the original capture hash. A new
    expected hash alone cannot authorize unrelated runtime drift.
    """
    patch = source.get("post_capture_label_patch")
    if not patch:
        return set()
    require(patch.get("kind") == "final_chamber_button_text_only", "Unknown post-capture change")
    require(patch.get("path") == "game/main.gd", "Unexpected post-capture path")
    records = [entry for entry in source["runtime_files"] if entry["path"] == "game/main.gd"]
    require(len(records) == 1, "Missing or duplicate captured main script")
    original_sha = records[0]["sha256"]
    require(patch.get("captured_sha256") == original_sha, "Post-capture original hash mismatch")
    old = b'else:card.add_child(button("Back to the workshop",func():_preview_run();home();_interstitial()))'
    new = b'else:card.add_child(button("Return home",func():_preview_run();home();_interstitial()))'
    current = (ROOT / "game/main.gd").read_bytes()
    require(current.count(new) == 1 and old not in current, "Post-capture label statement differs")
    require(hashlib.sha256(current).hexdigest() == patch.get("current_sha256"), "Post-capture current hash mismatch")
    require(hashlib.sha256(current.replace(new, old, 1)).hexdigest() == original_sha, "Post-capture change is not limited to the approved label")
    script = ROOT / source.get("capture_script", "")
    require(script.is_file() and script.resolve().is_relative_to(ROOT), "Capture script is missing")
    require(hashlib.sha256(script.read_bytes()).hexdigest() == source.get("capture_script_sha256"), "Capture fixture changed after capture")
    return {"game/main.gd"}


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
        label_patch_paths = verify_capture_label_patch(source)
        for entry in source["runtime_files"]:
            path = (ROOT / entry["path"]).resolve()
            require(path.is_relative_to(ROOT), "Capture source path leaves repository")
            require(path.is_file() and (hashlib.sha256(path.read_bytes()).hexdigest() == entry["sha256"] or entry["path"] in label_patch_paths), f"Capture source drift: {entry['path']}")
    native_path = capture_root / "android-provenance.json"
    native_captures = []
    if native_path.is_file():
        native_captures = json.loads(native_path.read_text(encoding="utf-8")).get("captures", [])
        for capture in native_captures:
            path = (capture_root / capture["path"]).resolve()
            require(path.is_relative_to(capture_root), "Native capture path leaves screenshot directory")
            require(png_size(path) == (capture["width"], capture["height"]), "Native capture dimensions differ")
            require(hashlib.sha256(path.read_bytes()).hexdigest() == capture["sha256"], "Native capture hash differs")
            metadata_path = (capture_root / capture["metadata"]).resolve()
            require(metadata_path.is_relative_to(capture_root), "Native metadata path leaves screenshot directory")
            metadata = json.loads(metadata_path.read_text(encoding="utf-8-sig"))
            require(metadata["image_sha256"] == capture["sha256"] and metadata["apk_sha256"] == capture["apk_sha256"], "Native capture provenance mismatch")
            require(capture["physical_device"] is False and capture["device_class"] == "actual Android emulator", "Native device class must be explicit")
    for name in ("LICENSE", "NOTICE", "review/index.html", "review/style.css", "review/review.js", "public/index.html", "docs/STORE_AND_RELEASE.md"):
        require((ROOT / name).is_file(), f"Missing review/release file: {name}")
    print(f"Store draft validated; lengths {len(listing['title'])}/{len(listing['short_description'])}/{len(listing['full_description'])}; {len(captures)} genuine capture records present.")
    if not captures:
        print("Runtime screenshot evidence remains PENDING; this static pass is not a gameplay pass.")
    print(f"Native Android emulator capture records validated: {len(native_captures)} (separate from desktop fixtures).")


if __name__ == "__main__":
    main()
