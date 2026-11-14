# Store and release preparation

Prism Quarry is a development package for `com.ethannyakabuski.prismquarry`. Store text is a draft, not a live listing. Build artifacts, CI success, static achievement validation, runtime input evidence, device testing and publication are separate outcomes. Consult [ACCEPTANCE.md](ACCEPTANCE.md) for recorded evidence; do not infer completion from this checklist.

## Store materials

The editable source is [store-listing.json](../marketing/store/store-listing.json): title **Prism Quarry**, proposed **Game / Arcade**, short and long English copy, discovery keywords, asset paths and unresolved owner fields. Keywords are proposed discovery concepts; select actual available Console tags that accurately describe the shipped build. No content rating or target age group has been asserted.

The 512 × 512 app icon, 1024 × 500 feature graphic and 1080 × 1920 splash are branding images. They must never be submitted as gameplay screenshots. Genuine captures are listed separately in [capture provenance](../marketing/screenshots/provenance.json). Phone, 7-inch and 10-inch-sized desktop viewport captures establish layout evidence only; they are not physical-device or emulator evidence. Retain original captures and their provenance without retouching gameplay into a fabricated state.

The [styled review](../review/index.html) presents the hook, loop, three selling cards, progression, monetization, branding, runtime gallery and download links. Serve the assembled site over HTTP; its gallery and source identity read local JSON. A pending or missing capture stays visibly pending.

## Native services and owner fields

Use [PLATFORM_SETUP.md](PLATFORM_SETUP.md) for exact plugin versions, configuration and callbacks. Development uses Google test ad IDs; production Play Games mappings are blank/disabled until configured by the owner. No production credentials, backend, publisher account or signing key is provided.

- Set the legal publishing identity, verified support email and support URL.
- Publish a final app-specific privacy policy at a public HTTPS URL and make it reachable in-app. Replace the explicitly labelled [privacy draft](../marketing/store/privacy-draft.html) after confirming the shipped behavior.
- Reconcile [Data safety draft](../marketing/store/data-safety-draft.json) with actual SDK versions, service configuration and network behavior. Local-only game storage does not prove that native advertising SDKs collect no data.
- Decide target audience, complete the content-rating questionnaire, declare ads, and verify applicable consent/privacy controls.
- Enter real AdMob and Play Games IDs only in the intended production configuration; validate reward, cancellation, unavailable-service and interrupted-lifecycle behavior on Android.
- Create and protect production signing material outside the repository. Debug signatures are test-only.

Google Play's [User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311) requires app-specific privacy disclosures and accurate Data safety information, including relevant SDK behavior. Its [app-content guidance](https://support.google.com/googleplay/android-developer/answer/9859455) covers privacy, ads, audience and content ratings. The [Mobile Ads disclosure guide](https://developers.google.com/admob/android/privacy/play-data-disclosure) is a starting point for inventorying the shipped advertising SDK. These sources were consulted on 2026-11-13; final declarations remain the publisher's task.

## Achievements and records

[game/catalog.json](../game/catalog.json) is the shared source for 20 achievements and three leaderboards. The [achievement ZIP](../marketing/play-games-achievements/prism-quarry-achievements-google-play.zip) is an authoring import package, not a game build. Its proposed points, fields, schema evidence, exact root filenames and static checks are documented in [ACHIEVEMENTS_IMPORT.md](ACHIEVEMENTS_IMPORT.md).

```sh
python tools/build_achievement_import.py --self-test
python tools/build_achievement_import.py --verify marketing/play-games-achievements/prism-quarry-achievements-google-play.zip
```

Passing these checks does not mean Play Console has accepted an import. Upload/import and real-ID mapping require owner action. This package does not upload to Play Console.

## Build and CI boundaries

`Validate and build` uses ordinary `ubuntu-24.04` GitHub-hosted runners, the official checksummed Godot **4.5.1** engine and matching templates, headless import, isolated test profiles, static store/catalog checks, single-threaded Web export and strict source-identity verification. Web artifacts expire after three days. A manual `android=true` run also builds debug APK/AAB artifacts using Java 17 and Android components; it does not sign a production release or upload to Google Play. A configured job is not a verified successful run: record its URL and exact commit only after completion.

The assembler refuses `--require-clean` if tracked or untracked source files remain dirty after import/export, and `--expected-sha` requires the exact checkout revision. It never silently restores source files. `build.json` records the source identity, runtime-tree hash and exported Web-file hashes. A local build without strict flags is clearly marked uncommitted when appropriate.

```sh
mkdir -p build/site/play
godot --headless --editor --path . --import
godot --headless --path . --export-release Web build/site/play/index.html
python tools/assemble_site.py build/site --require-clean --expected-sha <exact-commit>
python -m http.server 8768 --bind 127.0.0.1 --directory build/site
```

The separate **Deploy reviewed Web build** workflow is manual and additionally gated by `PRISM_PAGES_AUTHORIZED=true`. The user explicitly authorized Pages publication on 2026-11-14; Pages activation and the gate were configured, and [deployment run 43541679015](https://github.com/EthannYakabuski/prism-quarry/actions/runs/43541679015) succeeded at `769b3cd9424f5f7181104f39791e092e56a72fa9`. The [live game](https://ethannyakabuski.github.io/prism-quarry/play/) and [review](https://ethannyakabuski.github.io/prism-quarry/review/) were checked. For each subsequent deployment, verify the [live build.json](https://ethannyakabuski.github.io/prism-quarry/build.json) against that run's exact successful revision. A workflow gate alone does not establish authorization. No paid services or security settings are required by this package.

**Label fix verified live, 2026-11-14:** B14 runtime `363d0f6c9728fc4ed72c9322fe9f688cd68510ac`, deployed in `7950a924c434f5f7755bf311e9eee37b866173d1`, uses readable ASCII Pause and numeric shot counts. Local UI/touch checks and actual browser pause/resume, chamber completion, counters and reload recovery passed. [Validation 43544718140](https://github.com/EthannYakabuski/prism-quarry/actions/runs/43544718140) and [Pages 43544773056](https://github.com/EthannYakabuski/prism-quarry/actions/runs/43544773056) succeeded. The [B14 receipt](ui-glyph-fix-evidence.json) records tested payload identity and rebuilt Android artifacts with static checks only; refreshed native runtime testing remains undone. Retained Nov13 native screenshots keep their original APK provenance. Verify any later documentation-only deployment separately against its live build.json.

Godot's [Android export guide](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_android.html) covers Java 17, SDK configuration and signing. The native presets and local prerequisites are documented in the platform setup notes. Windows distribution is not a target.

## Future expansion

**Sunken Geodes** is a future DLC concept: flooded chambers with refracting currents. It is not implemented, sold, scheduled, priced or included in the current 30-chamber campaign. There is no billing product to configure in this development package.

## Release checklist

1. Freeze the final source revision; run all required tests and exports; verify exact remote SHA and CI URL.
2. Check baseline chamber completion, save recovery, once-only payouts/claims, pause/resume, and service cancellation using genuine input and fixtures with their evidence clearly distinguished.
3. Test the actual Android packages on declared device/emulator profiles; verify performance, safe areas, orientation and interruptions. Do not label desktop captures as Android testing.
4. Finish the owner fields and production-service/privacy work above. Confirm the listing describes the shipped behavior.
5. Verify the achievement ZIP statically, then have the owner review/import it into the intended Play project and map returned IDs.
6. Review final art, genuine screenshots, license notices, support and privacy URLs; retain build/capture provenance.
7. Publish only with the user's explicit authorization and record the successful result. A prepared workflow or a skipped deployment is not a live release.
