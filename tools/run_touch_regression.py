"""Run the native-style touch fixture and verify its report plus actual engine log.

The Windows GUI engine can hide a script's failing exit code, so the report and
log are mandatory. This is a fixture, not Android device-input evidence.
"""
from __future__ import annotations
import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile
import uuid

ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True)
    args = parser.parse_args()
    build = ROOT / "build"
    build.mkdir(exist_ok=True)
    (build / ".gdignore").touch(exist_ok=True)
    profile = Path(tempfile.mkdtemp(prefix="touch-test-", dir=build))
    report_path = build / "evidence/game-touch-teardown.json"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.unlink(missing_ok=True)
    log_path = profile / "engine.log"
    env = os.environ.copy()
    env["PRISM_TEST_ROOT"] = str(profile)
    if os.name == "nt":
        env["APPDATA"] = str(profile / "roaming")
        env["LOCALAPPDATA"] = str(profile / "local")
    else:
        env["XDG_DATA_HOME"] = str(profile / "userdata")
    command = [args.godot, "--headless", "--path", str(ROOT), "--script", "res://tests/game_touch_teardown_test.gd", "--log-file", str(log_path), "--", "--qa-profile=user://qa-ui-touch-" + uuid.uuid4().hex + ".json"]
    result = subprocess.run(command, cwd=ROOT, env=env, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=120)
    (profile / "stdout.log").write_text(result.stdout, encoding="utf-8")
    (profile / "stderr.log").write_text(result.stderr, encoding="utf-8")
    problems = []
    if result.returncode:
        problems.append(f"Engine returned {result.returncode}")
    try:
        report = json.loads(report_path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        report = {}
        problems.append("Fresh fixture report missing or invalid")
    if report.get("checks") != 10 or len(report.get("steps", [])) != 10 or report.get("failures") != []:
        problems.append("Expected ten successful screen-transition assertions")
    if "ScreenTouch" not in report.get("method", ""):
        problems.append("Fixture did not use native-style ScreenTouch input")
    if not log_path.is_file():
        problems.append("Actual engine log missing")
    log = log_path.read_text(encoding="utf-8", errors="replace") if log_path.is_file() else ""
    if "TEARDOWN TEST COMPLETE 10 GUI transitions" not in log:
        problems.append("Engine log does not confirm the full transition sequence completed")
    errors = log.count("at: can_process (")
    if errors or "at: can_process (" in result.stdout + result.stderr:
        problems.append("Detached controls reached can_process during input dispatch")
    validation = {"passed": not problems, "transitions": len(report.get("steps", [])), "can_process_errors": errors, "problems": problems, "engine_returncode": result.returncode, "engine_log": log_path.relative_to(ROOT).as_posix(), "fixture_report": report_path.relative_to(ROOT).as_posix(), "evidence_class": "headless ScreenTouch dispatch fixture; not physical or Android device input"}
    (build / "evidence/touch-regression-validation.json").write_text(json.dumps(validation, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(validation, indent=2))
    return int(bool(problems))


if __name__ == "__main__":
    raise SystemExit(main())
