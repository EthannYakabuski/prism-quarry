# Prism Quarry achievement import

`game/catalog.json` is the shared source for twenty local achievements and three
leaderboards. `tools/build_achievement_import.py` generates a separate Google Play
Games achievement import package. The package creates definitions; it does not
bind generated Play IDs to the game or publish anything.

## Proposed choices

- All twenty achievements are **standard** (`False` incremental value). The game
  evaluates each catalog metric against its threshold and directly unlocks it.
  A threshold such as 1,000 collected crystals is a local condition, not a Play
  incremental step count. Consequently the import's Steps Needed field is blank.
- All initial states are **Revealed**.
- Points range from 10 to 100 and total **720**, leaving 1,280 of the game's
  2,000-point allowance for future achievements. These are proposed design values.
- Display order matches the catalog. Names, descriptions and points are generated
  directly from it; filenames use the stable local keys.
- English `en-US` is the assumed default locale. The metadata provides that text.
  No `AchievementsLocalizations.csv` is included because there are no additional
  translations. The default locale must not be duplicated in that optional file.
- Achievement icons are the actual 512×512 PNGs under `marketing/achievements/`.
  All names, descriptions and icon bytes must be unique in this package.
- Catalog `icon` paths identify those canonical store images. Runtime UI derives
  `res://assets/badges/{key}.png` from each local key and uses the smaller copies
  supplied there. This lets Android/Web exports exclude marketing deliverables
  while retaining both achievement and leaderboard badges in the game.
- The three leaderboards are `best_score`, `endless_depth` and `miner_xp`. The
  achievement ZIP does **not** import leaderboards. Their names, metrics and icons
  remain in the same catalog for separate owner configuration.

| Key | Local condition | Points |
|---|---|---:|
| first_fracture | crystals ≥ 1 | 10 |
| cascade | chains ≥ 5 | 20 |
| chain_reaction | chains ≥ 12 | 50 |
| clean_sweep | perfect ≥ 1 | 20 |
| steady_hand | clears ≥ 5 | 20 |
| amber_cartographer | campaign_clears ≥ 10 | 25 |
| azure_explorer | campaign_clears ≥ 20 | 40 |
| vault_keeper | campaign_clears ≥ 30 | 60 |
| star_pocket | stars ≥ 15 | 20 |
| constellation | stars ≥ 60 | 50 |
| master_miner | stars ≥ 90 | 100 |
| crystal_collector | crystals ≥ 100 | 20 |
| crystal_connoisseur | crystals ≥ 1000 | 50 |
| bank_shot | ricochets ≥ 25 | 20 |
| spectacular | best_score ≥ 5000 | 40 |
| deep_diver | endless_depth ≥ 5 | 40 |
| daily_spark | daily_clears ≥ 1 | 15 |
| week_of_wonder | login_streak ≥ 7 | 40 |
| workshop_whiz | upgrades ≥ 5 | 30 |
| seasoned_miner | level ≥ 10 | 50 |

Campaign clears count distinct chambers; campaign stars are each chamber's best
rating summed across thirty chambers. Chains measures the largest individual
chain reaction. Crystal and ricochet counts accumulate; the login streak follows
consecutive claimed login gifts. Runtime and platform code must preserve these
meanings so a name and description describe the actual earned condition.

## Build and verify

Python 3.10 or newer is required; no third-party Python packages are needed.

```sh
python tools/build_achievement_import.py --self-test
python tools/build_achievement_import.py --metadata-only
python tools/build_achievement_import.py
python tools/build_achievement_import.py --verify marketing/play-games-achievements/prism-quarry-achievements-google-play.zip
```

`--metadata-only` writes reviewable CSV previews and the blank-ID worksheet. It
does not claim that icons or an archive have passed. The full build requires all
twenty icons, builds deterministic ZIP bytes, then reopens the saved file and
compares it with the catalog and original icon bytes. `--verify` is read-only.
The worksheet is not overwritten if it contains owner-entered Play IDs.

On Windows, use an installed Python interpreter. If `python` or `py -3` resolves
an unavailable Microsoft Store alias, replace `python` below with the path to
your actual installed interpreter.

```powershell
python tools/build_achievement_import.py
```

The only uploadable file is:

`marketing/play-games-achievements/prism-quarry-achievements-google-play.zip`

Keep `README.txt`, `validation-report.json`, the ID worksheet and this document
outside it. Its root contains `AchievementsMetadata.csv`,
`AchievementsIconsMappings.csv` and twenty PNGs; there are no directories.

## Import schema and checks

The CSV files use UTF-8 without BOM, CRLF rows and **no header row**. Metadata has
seven fields, in this order:

```text
Name,Description,Incremental value,Steps Needed,Initial State,Points,List Order
```

This line describes the fields and must not be inserted into the CSV. The icon
mapping has two fields: the exact metadata name and the root-level PNG filename.
The generated package checks unique names; name/description length limits;
commas and embedded line breaks; exact boolean/state spelling; blank standard
steps; whole numbers and point multiples; point budget; and mapping completeness.
The reusable archive validator also handles positive integral incremental steps
up to 10,000 and nondefault localization rows, although this catalog uses neither.

The ZIP validator rejects duplicate or nested paths, extra companion files,
missing/unreferenced icons, malformed UTF-8/CSV, archive CRC failures, file-size
violations, unexpected source drift and duplicate image bytes. PNG checks inspect
the signature, chunk CRCs, dimensions, palette rules, compression stream and
scanline layout including Adam7 passes. This checks image integrity, not artistic
quality or Console acceptance.

The builder deliberately uses conservative byte limits: each entry below
1,000,000 bytes, ZIP below 200,000,000 bytes, and at most 202 entries. The resulting
22-entry package is far below both published file-count limits. Incremental
minimum one, unique numeric list order, one unique PNG per achievement, no text
commas in localizations, and UTF-8 without BOM are strict authoring conventions;
they are not all separately stated as Google import requirements.

## Expanded campaign compatibility

On November 14, the development campaign expanded to 200 chambers. Existing
achievement keys, thresholds, points, order and icons remain unchanged so earned
milestones keep their meaning. Vault Keeper now says "Clear thirty different
campaign chambers" at threshold 30, and Master Miner says "Earn ninety campaign
stars" at threshold 90. Neither claims completion of the full expanded campaign.
The previous ZIP and catalog were archived locally before regeneration. The new
22-entry ZIP contains 20 achievements and 720 points, is 9,338,709 bytes, and has
SHA256 `f978d0f1338d01acee607fad9e713362a3e1ce35b735f63f2d5be7f5af5aa60e`.
All 31 validator self-tests and the finished-file reread pass. This is local static
authoring validation; no Console upload, import or backend-ID change was performed.

## Source reconciliation and evidence

On November 13, 2026, [Android Developers' import guide](https://developer.android.com/games/pgs/integrate-achievements#zip-file-guidelines)
specified plural `AchievementsIconsMappings.csv`, up to 403 entries, ZIP below
800 MB, and a required incremental flag. [Play Console Help](https://support.google.com/googleplay/android-developer/answer/2990418?hl=en)
still specified singular `AchievementsIconMappings.csv`, fewer than 203 entries,
ZIP below 200 MB, and an optional incremental flag. The owner confirmed a
successful November 12 Beacon Breakwater import using the plural filename. This
package follows that confirmed convention and supplies the flag explicitly.

The original Beacon reference was inspected read-only. Its archive hash was
`856729C69788CB15340513EE3E911697D1485B66681646E4E5CE860AD3A9DB5F`.
No Beacon file or configuration is changed by this tooling.

[Google's achievement guidance](https://developer.android.com/games/pgs/achievements#points_and_experience_points)
sets the 2,000-point game budget. The report records the exact new ZIP and catalog
hashes, each contained file hash, dimensions, counts and validation time.

**A PASS means local static validation only.** No Play Console import, current
Console duplicate check, translation configuration check, generated real-ID
binding, authenticated Play unlock or publication has been performed by this
tool. The owner should review definitions before import and publication; published
types and initial states cannot be changed. Once definitions exist, use their
generated IDs in the local-key worksheet and the platform configuration. Keep
native integration disabled until real configuration is supplied and tested.
