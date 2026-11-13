# Prism Quarry platform setup

The game uses Godot 4.5.1 Compatibility, package `com.ethannyakabuski.prismquarry`, min Android API 24 and target API 36. `Android` is the default debug AAB preset; `Android Test APK` has the same configuration in APK format. Both include ARM64, x86_64 and x86 (the existing development emulator is x86). Web is single-threaded and has no native ad entitlement. No Windows distribution preset is included.

## Native contract

`Services` follows the `GodotPlayGameServices` autoload. `configure_catalog()` accepts `game/catalog.json`; `submit_metrics()` derives standard achievement unlocks and larger-is-better scores from its metric fields. `request_sign_in()`, `open_achievements()`, `open_leaderboards(key)` and `request_privacy_options()` are safe with missing native services. `status()`, `can_reward()` and `services_updated` expose availability.

`set_banner_visible(true)` is for home/results. Active gameplay uses false. Menus reserve `menu_bottom_reserve(reference)` units beneath controls and update on `menu_bottom_reserve_changed`. The calculation converts actual banner pixels and Android safe insets once, including a conservative navigation allowance when Android reports no useful safe rectangle.

Call `record_round_completed(stable_round_id)` only after final round persistence. It deduplicates the ID in the current session. `request_interstitial_at_transition()` consumes an opportunity on every third completed round when Next/Retry is pressed. Unavailable opportunities are skipped. Cadence restarts per app session; this is deliberately conservative after process death. A failed round later continued should not be counted twice by the game.

`request_rewarded_continue()` starts only on explicit opt-in with a loaded native rewarded ad. `fullscreen_pending(reason)` is synchronous before SDK show. `fullscreen_visibility_changed(true/false)` tracks SDK display and dismissal plus UMP consent/privacy forms. The game must freeze/checkpoint from pending until dismissal and require explicit resume. A genuine native earned callback records entitlement; `reward_finished(true)` occurs only after that request dismisses. Cancellation, unavailable services, Web/editor requests, stale callbacks and failed display cannot grant it. Duplicate active reward requests are ignored. The game owns durable once-only continuation and must bind it to the current failed round. No automatic or simulated Web rewards exist.

The API returns whether a request started. Unavailable reward/interstitial requests deliver their false completion deferred; duplicate active reward input is ignored without completing the original request. `interstitial_finished(shown)` reports closure or skipped opportunity. A native callback that never arrives leaves the fullscreen block in place; do not resume gameplay under an uncertain visible SDK activity. Restart recovers the game's interrupted round. An app termination during a rewarded ad can lose an uncommitted continuation; it cannot synthesize a reward.

## Ads and privacy

The operative manifest setting is `[admob] general/android/app_id` in `project.godot`: Google's sample app ID `ca-app-pub-3940256099942544~3347511713`. The JSON app ID is documentation context; changing JSON alone does not change the manifest. Debug builds always force Google sample banner/interstitial/rewarded units. `platform/config.json` also keeps `test_mode=true` and blank production unit mappings.

UMP updates consent before Mobile Ads initialization and only requests ads after `OBTAINED` or `NOT_REQUIRED`. A required form is shown through the supplied plugin. Privacy options are exposed from settings. Unknown/unavailable consent leaves ads off. The under-age-of-consent flag currently defaults false; the owner must configure audience, consent messages and regional testing before production. Changing privacy state disables loaded ads when consent no longer permits requests.

Initialization and ad-load callbacks carry a consent generation. Opening privacy choices invalidates the preceding generation and destroys loaded ads; late success/failure callbacks cannot enable old ads, clear newer load flags or initialize ads while the form is open.

## Play Games

Twenty achievement and three leaderboard mappings are blank and `play_games.enabled=false`. To enable them, the owner supplies the same real numeric game ID to both Android export presets' `godot_play_game_services/game_id` and JSON `play_games.game_id`, then supplies real mappings from the shared catalog. The exporter omits APP_ID metadata while blank. The owner configures linked app, OAuth/signing fingerprints, testers and published resources in the Google consoles. This project never uploads/imports into Play Console.

Local metrics queue independently of remote availability. The versioned pending journal writes a temporary file and renames it, preserves a backup and recovers the union/highest valid records. Native successful submissions are acknowledged only for the current session. Desired progress remains durable for account changes. Ambiguous late ID-only native callbacks never acknowledge a newer score; retries are idempotent and rate limited. Real authentication, account switching and backend submissions remain owner-backend validation work.

## Reproducible local commands

Prerequisites: official Godot `4.5.1.stable.official.f62fdbde1`, its matching export templates, JDK 17, Android SDK platform 36 plus the Godot template's compile SDK 35/build-tools 35.0.0, and Python 3. The preset overrides the manifest target to 36. Local tool locations are recorded only in ignored build receipts.

From the repository root in PowerShell, set `GODOT_BIN` to your installed executable, `JAVA_HOME` to JDK 17 and `ANDROID_HOME` to your Android SDK. Existing Godot editor export settings must point to that JDK/SDK. The standard Windows template location is derived from `APPDATA`; other platforms may pass their own template directory.

```powershell
$pqGodot = $env:GODOT_BIN
$pqPython = (Get-Command python).Source
if (-not $env:ANDROID_HOME) { $env:ANDROID_HOME = Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
$pqTemplate = Join-Path $env:APPDATA 'Godot\export_templates\4.5.1.stable\android_source.zip'
& $pqPython platform/prepare_android.py --template $pqTemplate
& $pqPython platform/tests/validate_platform.py
& $pqPython platform/tests/run_tests.py --godot $pqGodot
New-Item -ItemType Directory -Force build/android,build/web | Out-Null
& $pqGodot --headless --path . --editor --import --quit
& $pqGodot --headless --path . --export-debug Android build/android/prism-quarry-debug.aab
& $pqGodot --headless --path . --export-debug 'Android Test APK' build/android/prism-quarry-test.apk
& $pqGodot --headless --path . --export-release Web build/web/index.html
& $pqPython platform/tests/validate_platform.py --artifact build/android/prism-quarry-debug.aab
& $pqPython platform/tests/validate_platform.py --artifact build/android/prism-quarry-test.apk
```

`android/build` is generated and ignored. The bootstrap extracts the official installed template, never an earlier game's assets/signing/local properties. Existing prepared source is left intact. Linux requires an executable `android/build/gradlew`; the bootstrap restores mode `0755` on POSIX for both fresh and already-prepared templates. On a clean CI host, install the pinned official 4.5.1 engine/templates and existing Java/SDK prerequisites in the CI workflow, including both compile SDK 35 and target SDK 36, then use the same bootstrap and export commands. No installer or security setting changes are performed by the platform scripts. Gradle dependencies may require network/cache availability.

The callback runner creates a fresh `build/platform-tests-*` project and process-local APPDATA/XDG directories. Its scene fixture uses normal autoload startup; direct `--script` startup can compile third-party Play Games classes before the autoload identifier exists, so use the runner. Fixture logs are application-logic evidence, not proof of native consent, reward delivery, banner visibility or Play Games backend acceptance. Final bundle/APK manifest inspection, actual Android lifecycle/ad tests, real-device tests, release signing and Play publication belong to the coordinator/owner.

Local callback validation on 2026-11-13: **36 checks passed**, with logs in `build/platform-tests-abd959266e39/result.json`. Coverage includes duplicate/stale/failed earned callbacks, dismissal ordering, every-third-round transition, missing safe insets, stale consent loads/initialization, corrupted and wrong-type journals, blank ID maps and ambiguous Play Games acknowledgements. Godot emitted its host `Failed to read the root certificate store` warning; no certificate/security settings were changed. These fixtures do not claim native SDK or backend acceptance.
