"""Validate capture provenance from Git-only files, without local SDK installations.

This is a static fixture, not an engine launch or a new gameplay/capture pass.
"""
from __future__ import annotations

from contextlib import contextmanager, redirect_stdout
import hashlib
import io
import json
from pathlib import Path
import runpy
import shutil
import subprocess
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SCOPE = "marketing/screenshots/capture-validation-scope.json"
SOURCE = "marketing/screenshots/capture-source.json"
FIX_FILES = ("tools/validate_store.py", SCOPE)


def main() -> None:
    build = (ROOT / "build").resolve()
    build.mkdir(exist_ok=True)
    (build / ".gdignore").touch(exist_ok=True)
    checkout = Path(tempfile.mkdtemp(prefix="capture-portability-", dir=build)).resolve()
    assert checkout.is_relative_to(build) and checkout != build
    manifest_bytes = (ROOT / SOURCE).read_bytes()
    results = []
    revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    try:
        # Git archive supplies canonical committed bytes, not ignored SDK files,
        # user saves, imported caches, or the host's line-ending conversion.
        archive = subprocess.check_output(["git", "archive", "--format=tar", "HEAD"], cwd=ROOT)
        with tarfile.open(fileobj=io.BytesIO(archive)) as files:
            files.extractall(checkout, filter="data")
        (checkout / ".gdignore").touch()
        # Supports reviewing this fix before commit as well as its committed CI.
        # No other working-tree content is copied over the fresh Git-only tree.
        for name in FIX_FILES:
            shutil.copyfile(ROOT / name, checkout / name)
        source = json.loads((checkout / SOURCE).read_bytes())
        scope = json.loads((checkout / SCOPE).read_bytes())
        optional = scope["archival_local_sdk_paths"]
        assert len(optional) == 131 and all(not (checkout / name).exists() for name in optional)
        assert (checkout / SOURCE).read_bytes() == manifest_bytes
        module = runpy.run_path(str(checkout / "tools/validate_store.py"), run_name="capture_portability_fixture")

        def verify():
            with redirect_stdout(io.StringIO()):
                module["verify_capture_sources"](checkout / SOURCE)

        def success(name, action):
            action()
            results.append({"check": name, "pass": True})

        def rejected(name, message):
            try:
                verify()
            except SystemExit as error:
                assert message in str(error), (name, str(error))
                results.append({"check": name, "pass": True})
                return
            raise AssertionError("Incorrectly accepted: " + name)

        @contextmanager
        def edited(name, content):
            path = (checkout / name).resolve()
            assert path.is_relative_to(checkout)
            before = path.read_bytes() if path.is_file() else None
            if content is None:
                path.unlink()
            else:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(content)
            try:
                yield
            finally:
                if before is None:
                    path.unlink(missing_ok=True)
                else:
                    path.write_bytes(before)

        def as_json(value):
            return (json.dumps(value, indent=2) + "\n").encode("utf-8")

        with redirect_stdout(io.StringIO()):
            success("Full store validation passes from fresh Git-only files with all 131 archival SDK inputs absent", module["main"])
        mandatory = [
            ("game/run.gd", "Missing game source fails"),
            ("assets/brand/icon.png", "Missing asset fails"),
            ("addons/admob/android/bin/ads/libs/poing-godot-admob-ads-debug.aar", "Missing committed Android AAR inside SDK directory fails"),
        ]
        for name, description in mandatory:
            with edited(name, None):
                rejected(description, "Capture source drift: " + name)
        with edited("game/chambers.gd", (checkout / "game/chambers.gd").read_bytes() + b"\n# unexpected drift\n"):
            rejected("Changed game source fails", "Capture source drift: game/chambers.gd")
        for replacement, description in [
            ("game/run.gd", "Game source cannot be classified as optional"),
            ("assets/brand/icon.png", "Asset cannot be classified as optional"),
            (mandatory[2][0], "Tracked Android AAR cannot be classified as optional"),
        ]:
            altered = json.loads(json.dumps(scope))
            altered["archival_local_sdk_paths"][0] = replacement
            with edited(SCOPE, as_json(altered)):
                rejected(description, "Archival classification is limited")
        altered = json.loads(json.dumps(scope))
        altered["archival_local_sdk_paths"][-1] = "addons/admob/ios/bin/unlisted/extra.gd"
        with edited(SCOPE, as_json(altered)):
            rejected("Even an SDK-directory path cannot broaden pinned membership", "Archival SDK membership changed")
        altered = json.loads(json.dumps(scope))
        altered["archival_local_sdk_paths"].pop()
        with edited(SCOPE, as_json(altered)):
            rejected("Archival membership cannot silently shrink", "exactly 131 unique paths")
        # The generated package descriptor is only 63 bytes. Keeping this exact
        # textual fixture avoids downloading or committing any native SDK binary.
        package = "addons/admob/android/bin/package.gd"
        descriptor = b'# This file is dynamically generated.\nconst VERSION := "5.1.0"\n'
        expected = next(entry["sha256"] for entry in source["runtime_files"] if entry["path"] == package)
        assert hashlib.sha256(descriptor).hexdigest() == expected
        with edited(package, descriptor):
            success("Present archival SDK input with the original hash passes", verify)
        with edited(package, descriptor + b"# changed"):
            rejected("Present archival SDK drift fails", "Capture source drift: " + package)
        script = source["capture_script"]
        with edited(script, (checkout / script).read_bytes() + b"\n# fixture drift\n"):
            rejected("Capture fixture remains strictly bound", "Capture fixture changed after capture")
        altered_source = json.loads(json.dumps(source))
        altered_source["state"] = "changed"
        with edited(SOURCE, as_json(altered_source)):
            rejected("Original capture manifest remains bound to the scope", "Capture scope does not match")
        # An attempted stronger attestation must not authorize unrelated main.gd
        # edits: the exact reverse-label hash still has to reproduce the capture.
        main_bytes = (checkout / "game/main.gd").read_bytes() + b"\n# unrelated edit\n"
        altered_source = json.loads(json.dumps(source))
        altered_source["post_capture_label_patch"]["current_sha256"] = hashlib.sha256(main_bytes).hexdigest()
        altered_source_bytes = as_json(altered_source)
        altered_scope = json.loads(json.dumps(scope))
        altered_scope["capture_source_sha256"] = hashlib.sha256(altered_source_bytes).hexdigest()
        with edited("game/main.gd", main_bytes), edited(SOURCE, altered_source_bytes), edited(SCOPE, as_json(altered_scope)):
            rejected("Updated attestation cannot hide an unrelated runtime edit", "Post-capture change is not limited")
        success("Restored fresh checkout passes after every negative control", verify)
        assert (ROOT / SOURCE).read_bytes() == manifest_bytes
        evidence = {"passed": True, "checks": len(results), "failures": [], "source_commit": revision,
                    "method": "Git archive fresh tracked-only tree; validator and scope overlaid for precommit review; no engine launches",
                    "required_repository_inputs": 295, "absent_archival_sdk_inputs": 131,
                    "unchanged_capture_manifest_sha256": hashlib.sha256(manifest_bytes).hexdigest(),
                    "assertions": results}
        (build / "evidence").mkdir(exist_ok=True)
        (build / "evidence/capture-portability.json").write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
        print(f"CAPTURE PORTABILITY: {len(results)} checks passed; fresh Git-only validation and negative controls.")
    finally:
        # Delete only this verified task-owned temporary checkout.
        target = checkout.resolve()
        assert target.is_relative_to(build) and target != build and target.name.startswith("capture-portability-")
        shutil.rmtree(target)


if __name__ == "__main__":
    main()
