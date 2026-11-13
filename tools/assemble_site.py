"""Assemble the review and an existing Web export, with honest source identity."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def git(*arguments: str) -> str:
    return subprocess.check_output(["git", *arguments], cwd=ROOT, text=True).strip()


def source_identity(require_clean: bool, expected_sha: str | None) -> dict:
    try:
        commit = git("rev-parse", "HEAD")
        dirty = bool(git("status", "--porcelain", "--untracked-files=all"))
    except (OSError, subprocess.CalledProcessError):
        if require_clean or expected_sha:
            raise SystemExit("A committed Git checkout is required for verified assembly.")
        commit, dirty = None, True
    if expected_sha and commit != expected_sha:
        raise SystemExit(f"Checkout mismatch: expected {expected_sha}, found {commit}")
    if require_clean and dirty:
        raise SystemExit("Refusing verified assembly: tracked or untracked source changes exist after import/export.")
    runtime = {}
    runtime_extensions = {".gd", ".uid", ".json", ".tscn", ".tres", ".res", ".glb", ".gltf", ".bin", ".obj", ".mtl", ".png", ".jpg", ".jpeg", ".webp", ".svg", ".ogg", ".wav", ".mp3", ".aar", ".cfg", ".gdextension", ".gdshader", ".shader", ".ttf", ".otf", ".fnt", ".translation"}
    for folder in ("game", "platform", "assets", "addons", "scenes", "marketing/achievements", "marketing/leaderboards"):
        for file in sorted((ROOT / folder).rglob("*")):
            if file.is_file() and not any(part.startswith(".") for part in file.relative_to(ROOT).parts):
                if file.suffix.lower() in runtime_extensions and "__pycache__" not in file.parts:
                    runtime[file.relative_to(ROOT).as_posix()] = hashlib.sha256(file.read_bytes()).hexdigest()
    for name in ("project.godot", "export_presets.cfg"):
        file = ROOT / name
        if not file.is_file():
            raise SystemExit(f"Missing runtime source: {name}")
        runtime[name] = hashlib.sha256(file.read_bytes()).hexdigest()
    digest = hashlib.sha256(json.dumps(runtime, sort_keys=True).encode()).hexdigest()
    return {
        "game": "Prism Quarry", "source_commit": commit,
        "uncommitted_changes": dirty, "runtime_tree_sha256": digest,
        "runtime_hash_scope": "Runtime-format files in game/platform/assets/addons/scenes plus catalog artwork; excludes import caches and documentation.",
        "source_identity": f"local-uncommitted/{digest}" if dirty else commit,
        "engine": "4.5.1.stable", "web_threads": False,
        "assembly_is_deployment": False,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target", nargs="?", default=str(ROOT / "build/site"))
    parser.add_argument("--require-clean", action="store_true", help="Reject any dirty or untracked source files.")
    parser.add_argument("--expected-sha", help="Require the exact Git source revision (CI passes GITHUB_SHA).")
    args = parser.parse_args()
    target = Path(args.target).resolve()
    if not target.is_relative_to(ROOT / "build"):
        raise SystemExit("Site output must be inside this project's build/ directory.")
    if not (target / "play/index.html").is_file():
        raise SystemExit("Export Web to <site>/play/index.html first.")
    # An old receipt must not survive a new export or a failed assembly.
    (target / "build.json").unlink(missing_ok=True)
    identity = source_identity(args.require_clean, args.expected_sha)
    web_html = target / "play/index.html"
    html = web_html.read_text(encoding="utf-8")
    marker = "const engine = new Engine(GODOT_CONFIG);"
    if marker not in html:
        raise SystemExit("Cannot locate official Web shell engine startup for compatibility diagnostic.")
    guard = '''// PRISM_ENGINE_GUARD: the official engine JavaScript remains unmodified.
if (typeof Engine !== 'function') {
  document.body.innerHTML = '<main style="max-width:640px;margin:12vh auto;padding:28px;color:#f7f4e9;background:#102830;font:18px/1.6 system-ui;border-radius:16px"><h1>Update your browser to play</h1><p>This browser could not load the Godot game engine. Please try a current browser with WebGL 2 support.</p><p><a style="color:#9df6cf" href="../review/">Open the game review and screenshots</a></p></main>';
  throw new Error('Prism Quarry: game engine unavailable; update the browser.');
}
'''
    if "// PRISM_ENGINE_GUARD" in html:
        start = html.index("// PRISM_ENGINE_GUARD")
        end = html.index(marker, start)
        updated_html = html[:start] + guard + html[end:]
    else:
        updated_html = html.replace(marker, guard + marker)
    if updated_html != html:
        web_html.write_text(updated_html, encoding="utf-8")
    target.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / "public/index.html", target / "index.html")
    ignore = shutil.ignore_patterns("*.import", "*.private.*", "*.log", "__pycache__", ".DS_Store")
    for folder in ("review", "marketing", "docs", "LICENSES"):
        source = ROOT / folder
        destination = target / folder
        if not destination.resolve().is_relative_to(target):
            raise SystemExit(f"Managed output escapes site directory: {destination}")
        if destination.exists():
            shutil.rmtree(destination)
        if source.is_dir():
            shutil.copytree(source, destination, ignore=ignore)
    for name in ("LICENSE", "NOTICE"):
        shutil.copy2(ROOT / name, target / name)
    shutil.copy2(ROOT / "game/catalog.json", target / "catalog.json")
    if not (target / "game").resolve().is_relative_to(target):
        raise SystemExit("Managed game output escapes site directory")
    if (target / "game").exists():
        shutil.rmtree(target / "game")
    (target / "game").mkdir()
    shutil.copy2(ROOT / "game/catalog.json", target / "game/catalog.json")
    identity["web_export_sha256"] = {
        file.relative_to(target).as_posix(): hashlib.sha256(file.read_bytes()).hexdigest()
        for file in sorted((target / "play").rglob("*")) if file.is_file()
    }
    # Recheck after assembly as well. No source file is restored or hidden by this tool.
    if args.require_clean and git("status", "--porcelain", "--untracked-files=all"):
        raise SystemExit("Source became dirty during assembly; refusing verified build metadata.")
    (target / "build.json").write_text(json.dumps(identity, indent=2) + "\n", encoding="utf-8")
    print(f"Assembled {target} from {identity['source_identity']}; this does not deploy it.")


if __name__ == "__main__":
    main()
