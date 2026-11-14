"""Require a fresh completed game-test report, not just the engine exit status."""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SUITES = {
    "game_model_test.gd": ("game-model.json", "GAME MODEL:"),
    "game_ui_test.gd": ("game-ui.json", "GAME UI:"),
    "profile_expansion_test.gd": ("profile-expansion.json", "PROFILE EXPANSION:"),
    "campaign_expansion_test.gd": ("campaign-expansion.json", "CAMPAIGN EXPANSION:"),
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("suite")
    parser.add_argument("--log", type=Path, required=True)
    parser.add_argument("--since", type=float, required=True)
    args = parser.parse_args()
    filename, marker = SUITES[Path(args.suite).name]
    path = ROOT / "build/evidence" / filename
    if not path.is_file() or path.stat().st_mtime < args.since - 1:
        raise SystemExit("Missing or stale game evidence: " + filename)
    data = json.loads(path.read_text(encoding="utf-8"))
    log = args.log.read_text(encoding="utf-8", errors="replace")
    if data.get("failures") != [] or not isinstance(data.get("checks"), int) or data["checks"] <= 0:
        raise SystemExit("Game report contains failures or no assertions: " + filename)
    if marker not in log or "SCRIPT ERROR" in log or "Parse Error" in log:
        raise SystemExit("Game log lacks completion or contains a script error: " + filename)
    if filename == "campaign-expansion.json":
        levels = data.get("levels", [])
        if data.get("complete") is not True or data.get("timed_out") is not False or len(levels) != 200:
            raise SystemExit("Campaign evidence did not complete all 200 chambers")
        if {entry.get("chamber") for entry in levels} != set(range(1, 201)):
            raise SystemExit("Campaign evidence has duplicate or missing chambers")
        for entry in levels:
            for mode in ("solution", "seeded_daily"):
                result = entry.get(mode, {})
                if result.get("won") is not True or result.get("stars") != 3 or result.get("snapshot_valid") is not True:
                    raise SystemExit("Campaign solution/replay did not pass: " + str(entry.get("chamber")))
    print(f"Verified fresh {filename}: {data['checks']} checks, zero failures, completed engine log.")


if __name__ == "__main__":
    main()
