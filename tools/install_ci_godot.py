"""Install official checksummed Godot 4.5.1 into isolated CI directories."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import urllib.request
import zipfile

VERSION = "4.5.1-stable"
BASE = f"https://github.com/godotengine/godot-builds/releases/download/{VERSION}/"
ENGINE = f"Godot_v{VERSION}_linux.x86_64"


def digest(path: Path, algorithm: str) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, algorithm).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    parser.add_argument("--android", action="store_true")
    args = parser.parse_args()
    directory = args.directory.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    templates = Path.home() / ".local/share/godot/export_templates/4.5.1.stable"
    templates.mkdir(parents=True, exist_ok=True)
    sums = urllib.request.urlopen(BASE + "SHA512-SUMS.txt", timeout=90).read().decode()
    checksums = {line.split()[-1].lstrip("*"): line.split()[0] for line in sums.splitlines() if line.strip()}
    archives = (ENGINE + ".zip", f"Godot_v{VERSION}_export_templates.tpz")
    wanted = ["web_nothreads_debug.zip", "web_nothreads_release.zip"]
    if args.android:
        wanted += ["android_debug.apk", "android_release.apk", "android_source.zip"]
    installed = {"engine/" + ENGINE: directory / ENGINE}
    installed.update({"templates/" + name: templates / name for name in wanted})
    receipt_path = directory / "verified-install.json"
    try:
        receipt = json.loads(receipt_path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        receipt = {}
    sources = {name: checksums[name] for name in archives}
    if receipt.get("official_archive_sha512") == sources and all(
        path.is_file() and digest(path, "sha256") == receipt.get("installed_sha256", {}).get(key)
        for key, path in installed.items()
    ):
        print(directory / ENGINE)
        return
    for filename in archives:
        archive = directory / filename
        if not archive.is_file() or digest(archive, "sha512") != checksums[filename]:
            with urllib.request.urlopen(BASE + filename, timeout=180) as response, archive.open("wb") as output:
                shutil.copyfileobj(response, output)
        if digest(archive, "sha512") != checksums[filename]:
            raise SystemExit(f"Official SHA-512 mismatch: {filename}")
        with zipfile.ZipFile(archive) as source:
            if filename.endswith(".zip"):
                with source.open(ENGINE) as stream, (directory / ENGINE).open("wb") as output:
                    shutil.copyfileobj(stream, output)
                (directory / ENGINE).chmod(0o755)
            else:
                for name in wanted:
                    with source.open("templates/" + name) as stream, (templates / name).open("wb") as output:
                        shutil.copyfileobj(stream, output)
                (templates / "version.txt").write_text("4.5.1.stable\n", encoding="utf-8")
        # Cache only the verified engine and selected templates, not the large all-platform archive.
        archive.unlink()
    receipt_path.write_text(json.dumps({
        "official_archive_sha512": sources,
        "installed_sha256": {key: digest(path, "sha256") for key, path in installed.items()},
    }, indent=2) + "\n", encoding="utf-8")
    print(directory / ENGINE)


if __name__ == "__main__":
    main()
