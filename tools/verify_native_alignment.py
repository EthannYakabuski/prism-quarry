"""Inspect actual 64-bit ELF LOAD alignment in an APK/AAB; no extraction required.

This static check does not establish 16KB-device execution or Play eligibility.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import sys
import zipfile


def inspect(path):
    libraries = []
    problems = []
    with zipfile.ZipFile(path) as archive:
        for entry in archive.infolist():
            if not entry.filename.endswith('.so') or not any('/' + abi + '/' in entry.filename for abi in ('arm64-v8a', 'x86_64')):
                continue
            data = archive.read(entry)
            if len(data) < 64 or data[:5] != b'\x7fELF\x02' or data[5] not in (1, 2):
                problems.append(entry.filename + ': not a valid 64-bit ELF')
                continue
            byteorder = '<' if data[5] == 1 else '>'
            offset = struct.unpack_from(byteorder + 'Q', data, 32)[0]
            size, count = struct.unpack_from(byteorder + 'HH', data, 54)
            alignments = []
            if size < 56 or offset + size * count > len(data):
                problems.append(entry.filename + ': invalid program header table')
                continue
            for index in range(count):
                fields = struct.unpack_from(byteorder + 'IIQQQQQQ', data, offset + index * size)
                if fields[0] != 1:
                    continue
                alignment = fields[7]
                alignments.append(alignment)
                if alignment < 16384 or alignment & (alignment - 1):
                    problems.append(entry.filename + ': LOAD segment alignment below 16384 or not power of two')
                if fields[2] % 16384 != fields[3] % 16384:
                    problems.append(entry.filename + ': LOAD offset and virtual address incongruent modulo 16384')
            if not alignments:
                problems.append(entry.filename + ': no LOAD segments')
            libraries.append({'path': entry.filename, 'load_alignments': alignments, 'sha256': hashlib.sha256(data).hexdigest()})
    if not libraries:
        problems.append('No 64-bit native libraries found')
    return {'artifact': str(path), 'sha256': hashlib.sha256(Path(path).read_bytes()).hexdigest(),
            'check': '64-bit ELF LOAD segment alignment', 'libraries': libraries,
            'passed': not problems, 'problems': problems, 'device_16kb_execution_tested': False,
            'zip_alignment_or_bundleconfig_verified': False, 'play_submission_verified': False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('artifact', type=Path)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    result = inspect(args.artifact)
    rendered = json.dumps(result, indent=2) + '\n'
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered, encoding='utf-8')
    print(rendered)
    return 0 if result['passed'] else 1


if __name__ == '__main__':
    sys.exit(main())
