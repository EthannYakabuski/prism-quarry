"""Unpack an already-installed Godot 4.5.1 Android source template; no downloads."""
from pathlib import Path
import argparse, os, zipfile


def ensure_gradle_executable(destination: Path) -> None:
    # zipfile does not restore Unix executable bits; Godot invokes this directly.
    if os.name == 'posix':
        (destination / 'gradlew').chmod(0o755)


parser = argparse.ArgumentParser()
parser.add_argument('--template', type=Path, required=True)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
destination = root / 'android' / 'build'
(root / 'android').mkdir(parents=True, exist_ok=True)
(root / 'android' / '.gdignore').touch()
destination.mkdir(parents=True, exist_ok=True)
(destination / '.gdignore').touch()
if (destination / 'AndroidManifest.xml').exists():
    ensure_gradle_executable(destination)
    print('Android template already prepared:', destination)
    raise SystemExit(0)
with zipfile.ZipFile(args.template) as archive:
    names = archive.namelist()
    if 'AndroidManifest.xml' not in names or 'config.gradle' not in names:
        raise SystemExit('Not a Godot Android source template.')
    for item in names:
        target = (destination / item).resolve()
        if not target.is_relative_to(destination.resolve()):
            raise SystemExit('Unsafe archive path: ' + item)
    archive.extractall(destination)
ensure_gradle_executable(destination)
(root / 'android' / '.build_version').write_text('4.5.1.stable', encoding='utf-8')
print('Prepared Godot 4.5.1 Android source at', destination)
