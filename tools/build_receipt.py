"""Record source and artifact identities without inferring test success."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as source:
        for block in iter(lambda: source.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()


def git(*args):
    p = subprocess.run(['git', *args], cwd=ROOT, text=True, capture_output=True)
    return p.stdout.strip() if p.returncode == 0 else None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('artifacts', type=Path, nargs='+')
    args = parser.parse_args()
    sources = {}
    for folder in ['game', 'scenes', 'platform', 'assets', 'addons']:
        for path in sorted((ROOT / folder).rglob('*')):
            if path.is_file() and path.suffix not in ('.import', '.uid') and '/tests/' not in path.as_posix():
                sources[path.relative_to(ROOT).as_posix()] = digest(path)
    for name in ('project.godot', 'export_presets.cfg'):
        if (ROOT / name).is_file():
            sources[name] = digest(ROOT / name)
    fingerprint = hashlib.sha256(json.dumps(sources, sort_keys=True, separators=(',', ':')).encode()).hexdigest()
    artifacts = []
    for requested in args.artifacts:
        path = (ROOT / requested).resolve()
        relative = path.relative_to(ROOT).as_posix()
        artifacts.append({'path': relative, 'bytes': path.stat().st_size, 'sha256': digest(path)})
    result = {'source_commit': git('rev-parse', 'HEAD'),
              'worktree_changes_at_receipt': (git('status', '--porcelain') or '').splitlines(),
              'runtime_source_sha256': fingerprint, 'runtime_source_file_count': len(sources),
              'runtime_source_hash_method': 'SHA256 of canonical sorted path-to-file-SHA256 JSON; excludes import/UID caches and tests',
              'artifacts': artifacts,
              'scope': 'Identity receipt only. Runtime tests, emulator results and hosted CI are recorded separately.'}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'output': str(args.output), 'runtime_source_sha256': fingerprint, 'artifacts': len(artifacts)}, indent=2))


if __name__ == '__main__':
    main()
