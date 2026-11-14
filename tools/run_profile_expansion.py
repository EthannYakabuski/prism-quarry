"""Run profile migration/economy fixtures with isolated user data and fresh evidence."""
from pathlib import Path
import argparse
import json
import os
import shutil
import subprocess
import tempfile
import time
import uuid


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    (root / 'build').mkdir(exist_ok=True)
    (root / 'build/.gdignore').touch(exist_ok=True)
    out = Path(tempfile.mkdtemp(prefix='profile-expansion-', dir=root / 'build'))
    env = os.environ.copy()
    env['PRISM_TEST_ROOT'] = str(out)
    if os.name == 'nt':
        env['APPDATA'] = str(out / 'roaming')
        env['LOCALAPPDATA'] = str(out / 'local')
    else:
        env['XDG_DATA_HOME'] = str(out / 'userdata')
    report = root / 'build/evidence/profile-expansion.json'
    if report.exists():
        shutil.copy2(report, out / 'previous-report.json')
    command = [args.godot, '--headless', '--path', str(root), '--script', 'res://tests/profile_expansion_test.gd',
               '--log-file', str(out / 'engine.log'), '--', '--qa-profile=user://qa-expansion-' + uuid.uuid4().hex + '.json']
    started = time.time()
    process = subprocess.run(command, cwd=root, env=env, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=180)
    (out / 'stdout.log').write_text(process.stdout, encoding='utf-8')
    (out / 'stderr.log').write_text(process.stderr, encoding='utf-8')
    fresh = report.is_file() and report.stat().st_mtime >= started - 1
    result = json.loads(report.read_text(encoding='utf-8')) if fresh else {}
    log = (out / 'engine.log').read_text(encoding='utf-8', errors='replace') if (out / 'engine.log').exists() else ''
    errors = [line for line in log.splitlines() if 'SCRIPT ERROR' in line or 'Parse Error' in line]
    completion = [line for line in log.splitlines() if 'PROFILE EXPANSION:' in line]
    passed = process.returncode == 0 and fresh and result.get('failures') == [] and bool(completion) and not errors
    receipt = {'passed': passed, 'directory': out.relative_to(root).as_posix(), 'returncode': process.returncode,
               'fresh_report': fresh, 'checks': result.get('checks'), 'failures': result.get('failures'),
               'script_errors': errors, 'completion': completion}
    if fresh:
        shutil.copy2(report, out / 'report.json')
    (out / 'result.json').write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(receipt, indent=2))
    return int(not passed)


if __name__ == '__main__':
    raise SystemExit(main())
