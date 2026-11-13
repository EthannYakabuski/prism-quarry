"""Exercise template preparation in isolation, including real POSIX launcher execution."""
from pathlib import Path
import os
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest
import zipfile


class PrepareAndroidTests(unittest.TestCase):
    def test_fresh_and_existing_templates_keep_a_runnable_launcher(self) -> None:
        with tempfile.TemporaryDirectory(prefix='prism-android-prepare-') as temporary:
            root = Path(temporary)
            platform = root / 'platform'
            platform.mkdir()
            helper = platform / 'prepare_android.py'
            shutil.copyfile(Path(__file__).resolve().parents[1] / 'prepare_android.py', helper)
            template = root / 'android_source.zip'
            launcher = '#!/bin/sh\nprintf "launcher-ready\\n"\n'
            with zipfile.ZipFile(template, 'w') as archive:
                archive.writestr('AndroidManifest.xml', '<manifest />')
                archive.writestr('config.gradle', '// fixture')
                archive.writestr('gradlew', launcher)

            command = [sys.executable, str(helper), '--template', str(template)]
            subprocess.run(command, check=True, capture_output=True, text=True)
            destination = root / 'android' / 'build'
            self.assertTrue((root / 'android' / '.gdignore').is_file())
            self.assertTrue((destination / '.gdignore').is_file())
            self.assertEqual((root / 'android' / '.build_version').read_text(), '4.5.1.stable')
            self.assertEqual((destination / 'gradlew').read_text(), launcher)
            self.assert_launcher_runs(destination / 'gradlew')

            # A repeated bootstrap must repair lost permission without re-extracting.
            (destination / 'config.gradle').write_text('// existing custom configuration')
            if os.name == 'posix':
                (destination / 'gradlew').chmod(0o644)
            template.unlink()
            subprocess.run(command, check=True, capture_output=True, text=True)
            self.assertEqual((destination / 'config.gradle').read_text(), '// existing custom configuration')
            self.assert_launcher_runs(destination / 'gradlew')

    def assert_launcher_runs(self, launcher: Path) -> None:
        if os.name == 'posix':
            self.assertEqual(stat.S_IMODE(launcher.stat().st_mode), 0o755)
            result = subprocess.run([str(launcher)], check=True, capture_output=True, text=True)
            self.assertEqual(result.stdout, 'launcher-ready\n')


if __name__ == '__main__':
    unittest.main()
