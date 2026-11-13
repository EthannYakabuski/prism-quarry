Prism Quarry - Google Play Games achievement import

Upload only prism-quarry-achievements-google-play.zip after owner review.
This tool does not upload to Play Console or publish anything.

The ZIP contains headerless AchievementsMetadata.csv, plural
AchievementsIconsMappings.csv, and 20 unique 512x512 PNG icons at its root.
README.txt, validation-report.json and achievement-id-mapping-and-points.csv
are companion files and must not be added to the ZIP.

All 20 proposed achievements are standard (False), with blank step counts and
Revealed initial state. The local metric thresholds are not Play incremental
steps. Proposed points total 720, ranging from 10 to 100 and leaving 1280 points
of Google's 2000-point game budget. Order/text/icons come from game/catalog.json.

English en-US is the assumed default locale. The metadata supplies English text.
No localization CSV is included: there are no additional translations and the
default locale must not be listed in that optional file.

The plural mapping filename follows the owner's successful Beacon Breakwater
package and current Android Developers guidance. Google Console Help still uses
a conflicting singular filename; see docs/ACHIEVEMENTS_IMPORT.md for details.

Build: python tools/build_achievement_import.py
Verify: python tools/build_achievement_import.py --verify marketing/play-games-achievements/prism-quarry-achievements-google-play.zip
Tests: python tools/build_achievement_import.py --self-test

Read validation-report.json for exact ZIP/catalog/file hashes, dimensions and
checks. PASS means local static validation only, never Play Console acceptance.
No real Play IDs are fabricated. The owner must copy generated IDs into the
worksheet and platform configuration after creating definitions. The three
leaderboards in the catalog need separate configuration; this ZIP imports only
achievements. Published achievement types and initial states cannot be changed.

Official documentation checked 2026-11-13:
https://developer.android.com/games/pgs/integrate-achievements#zip-file-guidelines
https://developer.android.com/games/pgs/achievements#points_and_experience_points
https://support.google.com/googleplay/android-developer/answer/2990418?hl=en
