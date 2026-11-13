#!/usr/bin/env python3
"""Build/recheck Prism Quarry's Play achievement import. Python standard library only.

No network or Play Console access. All reports distinguish local checks from import.
Run from any working directory; paths default to this script's parent project.
"""
from __future__ import annotations

import argparse
import binascii
import copy
import csv
import hashlib
import io
import json
import re
import struct
import sys
import tempfile
import zipfile
import zlib
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
META = "AchievementsMetadata.csv"
MAPS = "AchievementsIconsMappings.csv"  # plural Icons: owner-confirmed Beacon import
LOCALES = "AchievementsLocalizations.csv"
ZIP_NAME = "prism-quarry-achievements-google-play.zip"
MAX_FILE_BYTES = 1_000_000
MAX_ZIP_BYTES = 200_000_000  # conservative intersection of conflicting Google pages
MAX_FILES = 202
MAX_POINTS = 2_000
SOURCES = [
    "https://developer.android.com/games/pgs/integrate-achievements#zip-file-guidelines",
    "https://developer.android.com/games/pgs/achievements#points_and_experience_points",
    "https://support.google.com/googleplay/android-developer/answer/2990418?hl=en",
]
KEY = re.compile(r"[a-z][a-z0-9_]*\Z")
INTEGER = re.compile(r"[0-9]+\Z")


class ValidationError(ValueError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValidationError(message)


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def text_value(value: object, limit: int, label: str, required: bool = True) -> str:
    require(isinstance(value, str), f"{label}: expected text")
    require(not required or bool(value.strip()), f"{label}: empty text")
    require(value == value.strip(), f"{label}: surrounding whitespace")
    require(len(value) <= limit, f"{label}: exceeds {limit} characters")
    require(not any(c in value for c in ",\r\n\x00"), f"{label}: comma/newline/NUL forbidden")
    return value


def integer(value: str, label: str, minimum: int, maximum: int | None = None) -> int:
    require(bool(INTEGER.fullmatch(value)), f"{label}: expected whole nonnegative number")
    number = int(value)
    require(number >= minimum, f"{label}: below {minimum}")
    require(maximum is None or number <= maximum, f"{label}: above {maximum}")
    return number


def csv_bytes(rows: list[list[object]]) -> bytes:
    output = io.StringIO(newline="")
    csv.writer(output, lineterminator="\r\n").writerows(rows)
    return output.getvalue().encode("utf-8")


def csv_rows(data: bytes, filename: str, columns: int) -> list[list[str]]:
    require(not data.startswith(b"\xef\xbb\xbf"), f"{filename}: BOM forbidden by package convention")
    try:
        value = data.decode("utf-8", errors="strict")
        rows = list(csv.reader(io.StringIO(value, newline=""), strict=True))
    except (UnicodeDecodeError, csv.Error) as exc:
        raise ValidationError(f"{filename}: invalid UTF-8/CSV: {exc}") from exc
    require(bool(rows), f"{filename}: no rows")
    for index, row in enumerate(rows, 1):
        require(len(row) == columns, f"{filename}:{index}: expected {columns} fields")
    require(rows[0][0] != "Name", f"{filename}: header row forbidden")
    return rows


def validate_png(data: bytes, label: str) -> dict[str, int]:
    """Check the actual PNG structure, every chunk CRC, dimensions, and scanline data."""
    require(data.startswith(b"\x89PNG\r\n\x1a\n"), f"{label}: invalid PNG signature")
    position = 8
    chunks = []
    image_data = bytearray()
    header = None
    palette_size = None
    idat_finished = False
    while position < len(data):
        require(position + 12 <= len(data), f"{label}: truncated PNG chunk")
        size = struct.unpack_from(">I", data, position)[0]
        kind = data[position + 4:position + 8]
        end = position + 12 + size
        require(end <= len(data), f"{label}: truncated PNG payload")
        body = data[position + 8:position + 8 + size]
        crc = struct.unpack_from(">I", data, position + 8 + size)[0]
        require((binascii.crc32(kind + body) & 0xffffffff) == crc, f"{label}: PNG CRC mismatch")
        chunks.append(kind)
        require(len(kind) == 4 and all(65 <= value <= 90 or 97 <= value <= 122 for value in kind),
                f"{label}: invalid PNG chunk type")
        if kind not in (b"IHDR", b"PLTE", b"IDAT", b"IEND"):
            require(bool(kind[0] & 32), f"{label}: unknown critical PNG chunk")
        if image_data and kind != b"IDAT":
            idat_finished = True
        if kind == b"IHDR":
            require(header is None and len(chunks) == 1 and size == 13, f"{label}: invalid IHDR")
            header = struct.unpack(">IIBBBBB", body)
        elif kind == b"IDAT":
            require(header is not None and not idat_finished, f"{label}: misplaced IDAT")
            image_data.extend(body)
        elif kind == b"PLTE":
            require(header is not None and palette_size is None and not image_data,
                    f"{label}: misplaced/repeated PNG palette")
            require(size > 0 and size % 3 == 0 and size <= 768, f"{label}: invalid palette size")
            palette_size = size // 3
        elif kind == b"IEND":
            require(size == 0 and end == len(data), f"{label}: invalid IEND/trailing bytes")
            position = end
            break
        position = end
    require(header is not None and chunks[-1:] == [b"IEND"], f"{label}: incomplete PNG")
    width, height, depth, color, compression, filtering, interlace = header
    require((width, height) == (512, 512), f"{label}: icon must be 512x512")
    depths = {0: (1, 2, 4, 8, 16), 2: (8, 16), 3: (1, 2, 4, 8), 4: (8, 16), 6: (8, 16)}
    require(color in depths and depth in depths[color], f"{label}: invalid PNG color/depth")
    require(compression == 0 and filtering == 0 and interlace in (0, 1), f"{label}: invalid PNG format")
    require(bool(image_data), f"{label}: missing pixel data")
    if color == 3:
        require(palette_size is not None and palette_size <= 2 ** depth, f"{label}: invalid indexed palette")
    if color in (0, 4):
        require(palette_size is None, f"{label}: grayscale PNG cannot have a palette")
    try:
        decoder = zlib.decompressobj()
        raw = decoder.decompress(bytes(image_data), 3_000_000)
        require(decoder.eof and not decoder.unused_data and not decoder.unconsumed_tail,
                f"{label}: invalid/oversized compressed PNG data")
    except zlib.error as exc:
        raise ValidationError(f"{label}: invalid compressed PNG data") from exc
    channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[color]
    passes = [(0, 0, 1, 1)] if interlace == 0 else [
        (0, 0, 8, 8), (4, 0, 8, 8), (0, 4, 4, 8), (2, 0, 4, 4),
        (0, 2, 2, 4), (1, 0, 2, 2), (0, 1, 1, 2),
    ]
    consumed = 0
    for start_x, start_y, step_x, step_y in passes:
        columns = max(0, (width - start_x + step_x - 1) // step_x)
        row_count = max(0, (height - start_y + step_y - 1) // step_y)
        if not columns or not row_count:
            continue
        stride = (columns * channels * depth + 7) // 8 + 1
        end = consumed + stride * row_count
        require(end <= len(raw), f"{label}: truncated PNG scanlines")
        require(all(raw[consumed + y * stride] <= 4 for y in range(row_count)), f"{label}: invalid row filter")
        consumed = end
    require(consumed == len(raw), f"{label}: incorrect PNG pixel byte count")
    return {"width": width, "height": height}


def validate_catalog(catalog: dict) -> None:
    require(catalog.get("schema_version") == 1, "catalog: unsupported schema version")
    require(catalog.get("default_locale") == "en-US", "catalog: expected English en-US default")
    achievements = catalog.get("achievements", [])
    require(len(achievements) == 20, "catalog: Prism Quarry requires 20 achievements")
    boards = catalog.get("leaderboards", [])
    require(len(boards) == 3, "catalog: Prism Quarry requires three leaderboards")
    for kind, items in (("achievement", achievements), ("leaderboard", boards)):
        keys, names, descriptions, icons = set(), set(), set(), set()
        for item in items:
            key = item.get("key", "")
            require(isinstance(key, str) and bool(KEY.fullmatch(key)), f"{kind}: invalid key")
            require(key not in keys, f"{kind}: duplicate key {key}")
            keys.add(key)
            for field, limit, seen in (("name", 100, names), ("description", 500, descriptions)):
                text = text_value(item.get(field), limit, f"{key}.{field}")
                require(text.casefold() not in seen, f"{key}: duplicate {field}")
                seen.add(text.casefold())
            require(isinstance(item.get("metric"), str) and bool(KEY.fullmatch(item["metric"])),
                    f"{key}: invalid metric")
            expected = f"res://marketing/{'achievements' if kind == 'achievement' else 'leaderboards'}/{key}.png"
            require(item.get("icon") == expected, f"{key}: unexpected icon path")
            require(expected not in icons, f"{key}: repeated icon")
            icons.add(expected)
            if kind == "achievement":
                require(item.get("incremental") is False, f"{key}: runtime uses standard unlocks")
                require(item.get("initial_state") == "Revealed", f"{key}: expected proposed Revealed state")
                require(type(item.get("threshold")) is int and item["threshold"] > 0, f"{key}: invalid threshold")
                points = item.get("points")
                require(type(points) is int and 5 <= points <= 100 and points % 5 == 0, f"{key}: invalid proposed points")
            else:
                require(item.get("score_order") == "LARGER_IS_BETTER", f"{key}: incorrect score order")
    require(sum(row["points"] for row in achievements) <= MAX_POINTS, "catalog: exceeds game point budget")


def metadata_files(catalog: dict) -> dict[str, bytes]:
    validate_catalog(catalog)
    metadata, mappings = [], []
    for order, item in enumerate(catalog["achievements"], 1):
        metadata.append([item["name"], item["description"], "False", "", item["initial_state"], item["points"], order])
        mappings.append([item["name"], f"{item['key']}.png"])
    return {META: csv_bytes(metadata), MAPS: csv_bytes(mappings)}


def source_files(catalog: dict) -> dict[str, bytes]:
    files = metadata_files(catalog)
    for item in catalog["achievements"]:
        path = (ROOT / item["icon"].removeprefix("res://")).resolve()
        require(path.is_relative_to(ROOT), f"{item['key']}: icon escapes project")
        require(path.is_file(), f"{item['key']}: missing icon {path.relative_to(ROOT)}")
        files[path.name] = path.read_bytes()
    return files


def archive_bytes(files: dict[str, bytes]) -> bytes:
    output = io.BytesIO()
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, contents in sorted(files.items()):
            info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            archive.writestr(info, contents)
    return output.getvalue()


def validate_archive(data: bytes, expected: dict[str, bytes] | None = None,
                     default_locale: str = "en-US", configured_locales: tuple[str, ...] = ("en-US",)) -> dict:
    require(len(data) < MAX_ZIP_BYTES, "archive: exceeds conservative ZIP size limit")
    try:
        with zipfile.ZipFile(io.BytesIO(data), "r") as archive:
            entries = archive.infolist()
            require(0 < len(entries) <= MAX_FILES, "archive: exceeds conservative entry count")
            filenames = [entry.filename for entry in entries]
            require(len(set(name.casefold() for name in filenames)) == len(filenames), "archive: duplicate filenames")
            files = {}
            for entry in entries:
                name = entry.filename
                require(name and not any(c in name for c in "/\\\x00") and not name.startswith("."),
                        f"archive: invalid flat path {name!r}")
                require(0 < entry.file_size < MAX_FILE_BYTES, f"{name}: empty/oversized file")
                require(not entry.flag_bits & 1, f"{name}: encrypted files unsupported")
                require(name in (META, MAPS, LOCALES) or bool(re.fullmatch(r"[a-z][a-z0-9_]*\.png", name)),
                        f"{name}: unexpected file in import package")
                files[name] = archive.read(entry)  # CRC checked by zipfile
    except (zipfile.BadZipFile, RuntimeError, EOFError) as exc:
        raise ValidationError(f"archive: unreadable ZIP: {exc}") from exc
    require(META in files and MAPS in files, "archive: metadata and plural IconsMappings required by package")
    rows = csv_rows(files[META], META, 7)
    require(0 < len(rows) <= 400, "metadata: invalid achievement count")
    names, folded, orders = set(), set(), set()
    total = 0
    for index, row in enumerate(rows, 1):
        name, description, incremental, steps, state, points, order = row
        text_value(name, 100, f"metadata:{index}.name")
        text_value(description, 500, f"metadata:{index}.description", False)
        require(name.casefold() not in folded, f"metadata: duplicate achievement {name}")
        names.add(name)
        folded.add(name.casefold())
        require(incremental in ("True", "False"), f"{name}: invalid incremental flag")
        if incremental == "True":
            integer(steps, f"{name}.steps", 1, 10000)
        else:
            require(steps == "", f"{name}: standard achievement must leave steps blank")
        require(state in ("Hidden", "Revealed"), f"{name}: invalid initial state")
        point_value = integer(points, f"{name}.points", 5, 200)
        require(point_value % 5 == 0, f"{name}: points must be divisible by five")
        total += point_value
        if order:
            order_value = integer(order, f"{name}.order", 1)
            require(order_value not in orders, f"{name}: duplicate list order")
            orders.add(order_value)
    require(total <= MAX_POINTS, "metadata: exceeds 2000-point game budget")
    mappings = csv_rows(files[MAPS], MAPS, 2)
    mapped_names, mapped_icons, icon_hashes = set(), set(), set()
    image_reports = {}
    for name, filename in mappings:
        require(name in names, f"mapping: unknown achievement {name}")
        require(name not in mapped_names, f"mapping: duplicate achievement {name}")
        require(filename in files and filename.endswith(".png"), f"mapping: missing PNG {filename}")
        require(filename not in mapped_icons, f"mapping: repeated icon {filename}")
        mapped_names.add(name)
        mapped_icons.add(filename)
        image_reports[filename] = validate_png(files[filename], filename)
        icon_hash = digest(files[filename])
        require(icon_hash not in icon_hashes, f"{filename}: duplicate icon image bytes")
        icon_hashes.add(icon_hash)
    require(mapped_names == names, "mapping: every achievement needs exactly one icon")
    allowed_files = mapped_icons | {META, MAPS}
    localization_count = 0
    if LOCALES in files:
        allowed_files.add(LOCALES)
        pairs, localized_names = set(), set()
        for name, localized, description, locale in csv_rows(files[LOCALES], LOCALES, 4):
            require(name in names, f"localization: unknown achievement {name}")
            text_value(localized, 100, f"{name}.{locale}.name")
            text_value(description, 500, f"{name}.{locale}.description", False)
            require(locale != default_locale, "localization: default locale must stay in metadata")
            require(locale in configured_locales, f"localization: locale not configured: {locale}")
            require((name, locale) not in pairs, "localization: duplicate achievement/locale pair")
            require((localized.casefold(), locale) not in localized_names, "localization: duplicate localized name")
            pairs.add((name, locale))
            localized_names.add((localized.casefold(), locale))
            localization_count += 1
    require(set(files) == allowed_files, "archive: unexpected or unreferenced files")
    if expected is not None:
        require(set(files) == set(expected), "archive: file set differs from current source catalog/icons")
        for name in files:
            require(files[name] == expected[name], f"{name}: bytes differ from current catalog/source icon")
    return {
        "result": "PASS - local static validation only",
        "achievement_count": len(rows), "entry_count": len(files), "total_points": total,
        "points_reserved": MAX_POINTS - total, "default_locale": default_locale,
        "localization_rows": localization_count, "zip_bytes": len(data), "zip_sha256": digest(data),
        "console_upload_performed": False, "console_acceptance_verified": False,
        "files": [{"name": name, "bytes": len(contents), "sha256": digest(contents),
                   **image_reports.get(name, {})} for name, contents in sorted(files.items())],
    }


def atomic_write(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(prefix=path.name + ".", suffix=".tmp", dir=path.parent, delete=False) as temp:
        temp.write(data)
        temporary = Path(temp.name)
    temporary.replace(path)


def worksheet(catalog: dict) -> bytes:
    rows = [["CatalogKey", "Name", "Description", "Metric", "Threshold", "IncrementalValue",
             "StepsNeeded", "InitialState", "Points", "ListOrder", "IconFilename", "PlayGamesAchievementId"]]
    for order, item in enumerate(catalog["achievements"], 1):
        rows.append([item["key"], item["name"], item["description"], item["metric"], item["threshold"],
                     "False", "", item["initial_state"], item["points"], order, f"{item['key']}.png", ""])
    return csv_bytes(rows)


def write_metadata(catalog: dict, output: Path) -> None:
    for name, contents in metadata_files(catalog).items():
        atomic_write(output / "import-files" / name, contents)
    worksheet_path = output / "achievement-id-mapping-and-points.csv"
    desired = worksheet(catalog)
    if worksheet_path.exists() and worksheet_path.read_bytes() != desired:
        old_rows = list(csv.DictReader(io.StringIO(worksheet_path.read_text(encoding="utf-8-sig"))))
        require(not any(row.get("PlayGamesAchievementId", "").strip() for row in old_rows),
                "worksheet contains owner-entered IDs; refusing to overwrite")
    atomic_write(worksheet_path, desired)


def self_test() -> dict:
    # Small in-memory fixtures exercise rejected bad archives; no game/source files written.
    def png(seed: int, width: int = 512, height: int = 512) -> bytes:
        def chunk(kind: bytes, body: bytes) -> bytes:
            return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", binascii.crc32(kind + body) & 0xffffffff)
        raw = (b"\x00" + bytes((seed, 80, 120, 255)) * width) * height
        return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b"")
    valid = {META: csv_bytes([["Sample", "Break a crystal.", "False", "", "Revealed", 10, 1]]),
             MAPS: csv_bytes([["Sample", "sample.png"]]), "sample.png": png(20)}
    validate_archive(archive_bytes(valid), valid)
    passed = ["valid archive and exact source bytes"]
    def bad(label: str, mutate) -> None:
        candidate = copy.deepcopy(valid)
        mutate(candidate)
        try:
            validate_archive(archive_bytes(candidate), configured_locales=("en-US", "fr-FR"))
        except ValidationError:
            passed.append(label)
            return
        raise AssertionError(f"Expected rejection: {label}")
    def row_change(index: int, value: str):
        def mutate(files):
            row = csv_rows(files[META], META, 7)[0]
            row[index] = value
            files[META] = csv_bytes([row])
        return mutate
    bad("wrong boolean case", row_change(2, "false"))
    bad("standard achievement with steps", row_change(3, "1"))
    bad("unlocked initial state", row_change(4, "Unlocked"))
    bad("nonmultiple points", row_change(5, "12"))
    bad("oversized achievement points", row_change(5, "205"))
    bad("noninteger list order", row_change(6, "1.5"))
    bad("comma in quoted description", row_change(1, "Break one, then two."))
    bad("overlength name", row_change(0, "X" * 101))
    bad("bad column count", lambda f: f.__setitem__(META, b"Sample,broken\r\n"))
    bad("header row", lambda f: f.__setitem__(MAPS, b"Name,icon filename\r\n" + f[MAPS]))
    bad("BOM", lambda f: f.__setitem__(META, b"\xef\xbb\xbf" + f[META]))
    bad("singular mapping filename", lambda f: f.__setitem__("AchievementsIconMappings.csv", f.pop(MAPS)))
    bad("missing mapped PNG", lambda f: f.pop("sample.png"))
    bad("unknown achievement mapping", lambda f: f.__setitem__(MAPS, b"Other,sample.png\r\n"))
    bad("archive traversal", lambda f: f.__setitem__("../sample.png", f.pop("sample.png")))
    bad("unexpected companion file", lambda f: f.__setitem__("README.txt", b"must stay outside ZIP"))
    bad("invalid PNG CRC", lambda f: f.__setitem__("sample.png", f["sample.png"][:-1] + b"X"))
    bad("wrong PNG dimensions with valid CRC", lambda f: f.__setitem__("sample.png", png(20, 256, 512)))
    bad("duplicate metadata name", lambda f: f.__setitem__(META, f[META] * 2))
    bad("duplicate mapping", lambda f: f.__setitem__(MAPS, f[MAPS] * 2))
    bad("unreferenced PNG", lambda f: f.__setitem__("extra.png", png(30)))
    bad("entry exactly at forbidden size limit", lambda f: f.__setitem__("sample.png", b"X" * MAX_FILE_BYTES))
    bad("default-locale localization", lambda f: f.__setitem__(LOCALES, b"Sample,Sample,Description,en-US\r\n"))
    bad("unconfigured localization", lambda f: f.__setitem__(LOCALES, b"Sample,Beispiel,Beschreibung,de-DE\r\n"))
    bad("incremental steps above 10000", lambda f: f.__setitem__(META, b"Sample,Break crystals.,True,10001,Revealed,10,1\r\n"))
    bad("incremental zero steps", lambda f: f.__setitem__(META, b"Sample,Break crystals.,True,0,Revealed,10,1\r\n"))
    def over_budget(files):
        files.clear()
        files[META] = csv_bytes([[f"Sample {n}", f"Break {n + 1} crystals.", "False", "", "Revealed", 200, n + 1]
                                 for n in range(11)])
        files[MAPS] = csv_bytes([[f"Sample {n}", f"sample{n}.png"] for n in range(11)])
        files.update({f"sample{n}.png": png(n) for n in range(11)})
    bad("whole-game point budget", over_budget)
    mismatch = copy.deepcopy(valid)
    mismatch["sample.png"] = png(21)
    try:
        validate_archive(archive_bytes(valid), mismatch)
    except ValidationError:
        passed.append("source icon drift")
    else:
        raise AssertionError("Source drift was not rejected")
    translated = copy.deepcopy(valid)
    translated[LOCALES] = csv_bytes([["Sample", "Exemple", "Brisez un cristal.", "fr-FR"]])
    validate_archive(archive_bytes(translated), configured_locales=("en-US", "fr-FR"))
    passed.append("valid nondefault configured localization")
    incremental = copy.deepcopy(valid)
    incremental[META] = b"Sample,,True,10000,Hidden,200,\r\n"
    validate_archive(archive_bytes(incremental))
    passed.append("valid incremental boundary and optional empty fields")
    return {"result": "PASS", "checks": len(passed), "cases": passed}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--catalog", type=Path, default=ROOT / "game/catalog.json")
    parser.add_argument("--output-dir", type=Path, default=ROOT / "marketing/play-games-achievements")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--metadata-only", action="store_true", help="Write CSV previews/worksheet; does not check icons or create ZIP")
    mode.add_argument("--verify", type=Path, metavar="ZIP", help="Read-only recheck against current catalog and actual icons")
    mode.add_argument("--self-test", action="store_true", help="Run adversarial in-memory archive validation cases")
    args = parser.parse_args()
    try:
        if args.self_test:
            print(json.dumps(self_test(), indent=2))
            return 0
        catalog_bytes = args.catalog.read_bytes()
        catalog = json.loads(catalog_bytes)
        validate_catalog(catalog)
        if args.metadata_only:
            write_metadata(catalog, args.output_dir)
            print(json.dumps({"result": "METADATA ONLY - icons and ZIP not validated", "achievement_count": 20,
                              "total_points": sum(item["points"] for item in catalog["achievements"])}, indent=2))
            return 0
        expected = source_files(catalog)
        data = args.verify.read_bytes() if args.verify else archive_bytes(expected)
        report = validate_archive(data, expected, catalog["default_locale"], tuple(catalog["configured_locales"]))
        if not args.verify:
            write_metadata(catalog, args.output_dir)
            destination = args.output_dir / ZIP_NAME
            atomic_write(destination, data)
            # Read the actual finished file back; never treat validation of inputs as archive validation.
            report = validate_archive(destination.read_bytes(), expected, catalog["default_locale"], tuple(catalog["configured_locales"]))
            report.update({"checked_at_utc": datetime.now(timezone.utc).isoformat(),
                           "catalog_sha256": digest(catalog_bytes), "sources_checked_date": "2026-11-13",
                           "official_sources": SOURCES, "schema_convention": "Owner-confirmed Beacon plural IconsMappings",
                           "conservative_limits": {"each_file_bytes_exclusive": MAX_FILE_BYTES,
                                                   "zip_bytes_exclusive": MAX_ZIP_BYTES, "max_files": MAX_FILES}})
            atomic_write(args.output_dir / "validation-report.json", (json.dumps(report, indent=2) + "\n").encode("utf-8"))
        print(json.dumps({key: value for key, value in report.items() if key != "files"}, indent=2))
        return 0
    except (ValidationError, OSError, ValueError, KeyError, TypeError) as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
