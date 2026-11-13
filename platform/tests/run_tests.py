"""Run callback fixtures in a fresh project and user-data sandbox, without owner saves."""
from pathlib import Path
import argparse, json, os, re, shutil, subprocess, uuid

parser = argparse.ArgumentParser()
parser.add_argument('--godot', required=True)
args = parser.parse_args()
root = Path(__file__).resolve().parents[2]
work = root / 'build' / ('platform-tests-' + uuid.uuid4().hex[:12])
work.mkdir(parents=True)
for folder in ('addons', 'platform'):
    shutil.copytree(root / folder, work / folder, ignore=shutil.ignore_patterns('*.aar', '*.import', '__pycache__'))
(work / 'project.godot').write_text('''config_version=5
[application]
config/name="Prism Quarry Platform Fixtures"
run/main_scene="res://platform/tests/test_services.tscn"
[autoload]
GodotPlayGameServices="*res://addons/GodotPlayGameServices/scripts/autoloads/godot_play_game_services.gd"
[rendering]
renderer/rendering_method="gl_compatibility"
''', encoding='utf-8')
env = os.environ.copy()
env['APPDATA'] = str(work / 'userdata')
env['XDG_DATA_HOME'] = str(work / 'userdata')
env['XDG_CONFIG_HOME'] = str(work / 'config')
commands = [
    [args.godot, '--headless', '--path', str(work), '--editor', '--import', '--quit'],
    [args.godot, '--headless', '--path', str(work), '--quit-after', '600'],
]
results = []
for index, command in enumerate(commands):
    run = subprocess.run(command, env=env, text=True, capture_output=True, timeout=180)
    (work / f'{index}.stdout.txt').write_text(run.stdout, encoding='utf-8')
    (work / f'{index}.stderr.txt').write_text(run.stderr, encoding='utf-8')
    results.append({'command': command, 'returncode': run.returncode, 'stdout': run.stdout, 'stderr': run.stderr})
    print(run.stdout[-2000:])
    print(run.stderr[-10000:])
    known_host_warning = 'ERROR: Failed to read the root certificate store.'
    errors = [line for line in run.stderr.splitlines() if ('ERROR:' in line or 'SCRIPT ERROR' in line) and line != known_host_warning]
    if run.returncode or errors:
        raise SystemExit(run.returncode or 1)
    if index == 1:
        marker = re.search(r'PLATFORM_FIXTURES (\{[^\n]+\})', run.stdout)
        if not marker or json.loads(marker.group(1))['failures']:
            raise SystemExit('Missing or failing fixture receipt')
(work / 'result.json').write_text(json.dumps(results, indent=2), encoding='utf-8')
print(f'Platform fixture evidence: {work}')
