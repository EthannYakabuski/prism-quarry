# Prism Quarry acceptance record

Evidence dates: 2026-11-13 (retained native/build snapshot) and 2026-11-14 (live Pages/browser verification and label correction). B14 is verified locally and in the live Web payload at `7950a924c434f5f7755bf311e9eee37b866173d1`. Rebuilt Android packages pass static checks but have not been installed or played; the native capture gallery remains historical Nov13 evidence. This is development acceptance, not a production-release certification.

Nov13 runtime correction revision: [f0fdea95a100c1250e5e5b94f04b568142209629](https://github.com/EthannYakabuski/prism-quarry/commit/f0fdea95a100c1250e5e5b94f04b568142209629). Nov14 label-fix revision: `363d0f6c9728fc4ed72c9322fe9f688cd68510ac`. [build-evidence.json](build-evidence.json) remains the unchanged prepublication verification snapshot: five actual artifact identities and source/worktree state recorded on 2026-11-13. The snapshot includes [hosted run 43475885486](https://github.com/EthannYakabuski/prism-quarry/actions/runs/43475885486), which passed at aa830e55. For later publication state, compare the exact commit against [current CI runs](https://github.com/EthannYakabuski/prism-quarry/actions/workflows/ci.yml); later source identities and CI outcomes must be recorded separately from this retained receipt.

## Automated and static checks

| Area | Recorded result | Scope |
|---|---|---|
| Model | 189 checks, 0 failures | All 30 chambers have base-equipment three-star simulation solutions. Straight-first-shot and fixed-angle-sweep strategies each clear only five. |
| Application/UI | 128 checks, 0 failures on Nov14 | Updated local suite after B14; navigation, bounds, Viewport pointer dispatch, once-only results/claims, save failures, cold restore, Back/focus/fullscreen and synthetic reward cases. The retained Nov13 pass had 90 checks. |
| Touch teardown | 10 ScreenTouch transitions, 0 failures, 0 can_process errors on Nov14 | Local rerun after B14 with a fresh isolated profile; wrapper requires all expected screens, a new report and actual completed engine log. This fixture is separate from Nov13 native touch evidence. |
| Platform | 36 checks, 0 failures | Isolated service/callback/configuration fixtures, not backend proof. |
| Achievement validator | 31 self-tests pass | Finished ZIP independently reopens: 20 achievements, 22 flat entries, 720 proposed points. No Console import or acceptance is claimed. |
| Desktop captures | Nov14 B14 set: 18 unmodified images; 93 source hashes checked | Six freshly rendered fixture views each at 1080 x 1920, 1200 x 1920 and 1600 x 2560 from revision 363d0f6c9728fc4ed72c9322fe9f688cd68510ac. All 18 visually reviewed; Pause and numeric shot labels are legible across all profiles. |
| Native captures | Retained Nov13 set: 11 selected PNG/JSON pairs validate | Nine corrected-Nov13-APK emulator frames plus two explicitly labelled earlier-APK Google test-ad QA frames. All predate B14. |
| Web export | Corrected live 7950a924: 516 PCK checksums and nine Web-file hashes pass | Required game/catalog/audio/service resources present; prohibited test/marketing/private payload absent; official single-threaded Godot 4.5.1 templates. Only game/main.gdc changed from the earlier live payload. |
| Store/review | Asset dimensions and copy lengths pass | Icon 512 x 512; feature 1024 x 500; splash 1080 x 1920; title/short/long lengths 12/73/1609. Artwork remains separate from gameplay. |

Local reports are retained under build/evidence/, build/native/ and build/*validation.json; build outputs and raw logs are excluded from Git. The receipt contains concise verification summaries. Capture evidence: [desktop manifest](../marketing/screenshots/provenance.json), [source hashes](../marketing/screenshots/capture-source.json), [native manifest](../marketing/screenshots/android-provenance.json). Achievement details: [validation report](../marketing/play-games-achievements/validation-report.json) and [schema notes](ACHIEVEMENTS_IMPORT.md).

The Nov14 capture refresh used three sequential graphical runs with fresh isolated QA profiles. All 18 PNGs passed dimensions and SHA-256 checks, with six successful saves per run and unchanged source hashes before/after capture. The previous desktop set and manifests are archived under ignored build/font-captures-20261114-f162fb0c/previous-desktop-captures/. Native images retain their original Nov13 APK identities.

## Retained Nov13 Android packages

These historical debug packages and their native captures predate the Nov14 label fix. Their hashes are preserved. The new [B14 receipt](ui-glyph-fix-evidence.json) separately records the rebuilt Nov14 APK (SHA2d448b5e...) and AAB (SHA2c84afad...), their actual bytes/hashes and passing package/configuration, ABI, manifest and static 64-bit ELF LOAD checks. The rebuilt binaries were not installed or played on Android.

- APK: 274,649,262 bytes; SHA256 69581fe0ab4ece0fa08a7fab40eb2084f747500aa6a3254faa740022eec5b60c.
- AAB: 102,129,822 bytes; SHA256 b6be1f9ac82397bbba7946da3992ad779036a68a4247f54248a71597f9eeea4f.

Both debug exports returned zero with unchanged source fingerprints during export. Actual packages contain matching ARM64, x86 and x86_64 payloads. The manifest reports min API 24, target API 36, Google test AdMob app ID and no production Play Games app ID. Each package's 522 asset entries pass configuration and payload checks.

Static 64-bit ELF LOAD alignment passes. This does not prove 16KB-device execution, ZIP alignment or the AAB BundleConfig page-size declaration. Production signing remains unconfigured.

## Actual ordinary-APK runtime, Nov13

Testing used a task-owned disposable Pixel_API_30 x86 emulator, API 30, serial emulator-5560. Inputs were actual emulator touch/Back/lifecycle actions; no save fixtures were injected. No physical device is claimed.

**Prior APK, with unchanged service/progression implementation:** a real Google sample banner displayed. A drag/release cleared nine crystals for 1,800 points and three stars, paying 75 ore/82 XP. Android Back paused; force-stop/relaunch restored the same checkpoint paused; another Back still required explicit Resume. A real Google rewarded test ad earned a continuation; closing it persisted two extra shots and required Resume. Consuming those shots produced no second offer. A Google test interstitial appeared on the third session round and dismissed into the workshop. Repeated upgrade input charged 180 ore once (216 to 36, gear level 1). These observations remain bound to the earlier APK hash in their provenance, rather than being relabelled as the final binary.

**Corrected Nov13 APK:** rapid native menu/recall/result transitions passed with zero observed native can_process teardown errors. A rewarded video was force-stopped before earning; cold restore retained continued=false and zero shots, proving interrupted presentation granted no entitlement. Play then continued. The actual 1200 x 1920, density 320 emulator profile cleared 14 crystals in two shots for 2,475 points, three stars and +93 ore/+97 XP. The 1600 x 2560, density 300 profile showed the result and chapter 3 gameplay. These are emulated tablet-size profiles, not physical tablets.

Returning from the browser required explicit Resume. Two actual Collect reward taps paid the daily claim once: ore 137 to 227 and XP 306 to 346, with the clears claim recorded. Leaving untouched chapter 3 produced a zero-ore/zero-XP receipt.

**Limits:** an early Back attempt during a rewarded video was ignored by the SDK and the ad later earned, so ordinary user-initiated unearned ad closure is not verified by that attempt. Interrupted-before-earned force-stop is separately verified. Full native offline acceptance is inconclusive: Wi-Fi/data settings were disabled and airplane mode enabled, yet Connectivity still reported validated network 101. Connectivity and display defaults were restored. Do not treat filenames containing offline as offline proof. Physical-device behavior, subjective audio/thermal performance and production services remain untested.

The initial System UI ANR, splash transitions, OS overlays, repetitive frames and unselected third-party ad creative were preserved in ignored local build/native/qa-archive/ or rejected-captures/. Only clean selected images remain in the public capture folders. Test-ad images are labelled QA and kept outside marketing gameplay.

## Browser and review

**Earlier live Web gameplay verified on 2026-11-14, before B14:** the isolated desktop in-app browser rendered the deployed build at `769b3cd9424f5f7181104f39791e092e56a72fa9`. Actual pointer drag/release cleared chamber 1 with nine crystals, 1,800 points and three stars, paying 75 ore/82 XP. Banking returned home at Miner 2, 125 ore and chamber 02; reloading retained that progress. In chamber 2, an actual shot reached eight crystals, 1,500 points and two shots remaining. Pause followed by reload restored SHIFT PAUSED and required explicit Resume; resuming retained the same crystals, score and shots. These are browser input and persistence observations, not simulated fixtures.

Some pause/shot-symbol Unicode characters appeared as missing-glyph boxes during that earlier live run. B14 replaces them with ASCII `Pause`, a minimum 96 x 44 control, and numeric shot counts in runtime revision `363d0f6c9728fc4ed72c9322fe9f688cd68510ac`. The updated local UI suite passed 128 checks; ten touch transitions passed with zero teardown errors. The corrected live payload at `7950a924c434f5f7755bf311e9eee37b866173d1` was verified through actual isolated desktop-browser input on Nov14.

The corrected live build retained Miner 2, 218 ore and chamber 03 from the earlier session. Chamber 3 displayed readable Pause and 3 SHOTS LEFT without boxes or clipping; clicking Pause and Resume preserved three shots, zero crystals and zero points. An actual drag shot displayed 2 SHOTS LEFT, then completed the chamber with 20 crystals, 6,750 points, one ricochet, one shot and three stars, awarding 159 ore/115 XP. Chamber 4 began at 3 SHOTS LEFT. Two actual drag/immediate-Recall cycles displayed 2 SHOTS LEFT then 1 SHOT LEFT, with zero crystals/points. Pause and reload restored SHIFT PAUSED; explicit Resume preserved one shot, zero crystals and zero points. Pause remained readable. A console warning/error query returned an empty list at that check; no whole-session silence is claimed. Storage was not cleared, and no personal Edge profile or security-setting change was used.

A separate cloud Chromium browser rendered the review but lacked WebGL 2 for gameplay. Its environment limit does not negate the successful earlier desktop-browser run or establish broader browser compatibility.

After Resume, a second chamber-2 shot cleared 14 crystals total for 2,475 points, two ricochets, two shots and three stars, awarding 93 ore/97 XP. Reloading directly from the result returned home with 218 ore, Miner 2 and chamber 03 unlocked, without duplicating the payout. The supported-browser console warning/error reader returned an empty list at that completed result; this is a point-in-time observation, not a claim that the entire session was silent.

**Earlier emulator-browser check, 2026-11-13:** Chrome 83 had a secure localhost context, WebGL2=true and WebAssembly availability, but the official engine JavaScript failed parsing with SyntaxError: Unexpected token '='; Engine remained undefined. Gameplay did not run in that browser because of old JavaScript support, not missing WebGL2.

The review's replaceChildren calls were replaced with textContent clearing, and a flex-gap margin fallback was added for Chrome 83. The review also contains real static fallback images for direct file opening; HTTP enables full profile controls. The assembled game HTML checks for a missing Engine and displays an update-browser message before engine startup. Official index.js is unmodified. The HTTP review refresh was observed successfully in Chrome 83: 18 gallery figures were present and six images loaded for the selected profile. Actual desktop gameplay/home cards and their truthful captions were visually confirmed (local build/browser/13-review-gallery.png). The missing-engine visual diagnostic also displayed correctly. This confirms review rendering and the diagnostic, not Web gameplay.

Earlier host attempts on 2026-11-13: IAB was unavailable; isolated host Chrome exited 0x80000003 without a page; a process-command-line query returned Access denied. The isolated IAB was available for the successful 2026-11-14 run. No personal browser profile, security-warning bypass or security-setting change was used.

## Publication

The [public repository](https://github.com/EthannYakabuski/prism-quarry) exists. Initial CI omitted four Poing AARs due to an upstream ignore rule; the exact licensed binaries were tracked and the subsequent hosted validation passed.

**Pages is live following explicit user authorization on 2026-11-14.** The first verified deployment, [run 43541679015](https://github.com/EthannYakabuski/prism-quarry/actions/runs/43541679015), succeeded at `769b3cd9424f5f7181104f39791e092e56a72fa9`: [play](https://ethannyakabuski.github.io/prism-quarry/play/) and [review](https://ethannyakabuski.github.io/prism-quarry/review/). Independent live HTTP checks passed for 98 responses, nine Web-file hashes, 516 PCK entries and all 29 capture images from that clean revision. The [live build.json](https://ethannyakabuski.github.io/prism-quarry/build.json) records the currently deployed commit; later documentation deployments have their own source identity.

The Nov13 approval denials remain recorded in the unchanged, dated [prepublication snapshot](build-evidence.json). New explicit authorization permitted the Nov14 activation and deployment. Google Play publication and achievement Console import were not performed.

The corrected payload at `7950a924c434f5f7755bf311e9eee37b866173d1` passed [validation run 43544718140](https://github.com/EthannYakabuski/prism-quarry/actions/runs/43544718140) and [Pages run 43544773056](https://github.com/EthannYakabuski/prism-quarry/actions/runs/43544773056). Live verification passed 98 HTTP responses, nine Web-file hashes, 516 PCK entries, 18 current desktop captures and 11 historical native captures. Only main.gdc changed inside the PCK compared with the earlier tested payload. These results identify tested revision 7950a924; any final documentation-only deployment needs a separate exact-SHA/build.json continuity receipt.

## Corrected defects and retained diagnostics

| ID | Defect | Resolution/evidence |
|---|---|---|
| B01 | Missing cave colormap | Corrected; final captures and exports include it. |
| B02-B04 | Back resumed pause, descent restore lost action, untouched bank farmed payout | UI/model regressions pass; final native Back/restore and zero-payout abandon observed. |
| B05-B06 | HUD wrapping/clipping and overexposure | Layout/lighting corrected; final bounds checks and three rendered profiles retained. |
| B07-B09 | Bank Shot wording, midnight/depth metrics, focus audio suspension | Wording/ZIP corrected; corresponding model/UI fixtures pass. Subjective audio remains separate. |
| B10-B11 | Android build assets imported recursively; four AARs absent from clean clone | Ignore/preparation corrected, exact binaries tracked, exports/payload checks and corrected CI pass. |
| B12 | Touch input detached UI during dispatch | Deferred hide/free correction reduces reproduced eight errors in ten transitions to zero; 90 UI checks, ten logged touch transitions and final native retest pass. Shot grammar also corrected. |
| B13 | Linux template extraction lost the Gradle launcher's executable bit; compile SDK 35 was implicit in CI | Bootstrap restores POSIX mode 0755 for fresh and existing templates; CI explicitly installs SDK 35 and 36 and runs an isolated launcher regression. Local preparation checks pass; hosted Linux execution and Android build results are recorded separately in the final publication receipt and current CI. |
| B14 | Pause/shot Unicode symbols rendered as missing-glyph boxes in the earlier live browser build | Runtime 363d0f6 uses ASCII Pause and numeric counters. Local 128 UI checks and ten logged touch transitions pass. Deployed payload 7950a924 passed actual Pause/Resume, 3/2/1 shot labels, completion and paused reload/recovery; no boxes or clipping observed. |

Local headless logs retain root-certificate-store, dummy-renderer material and shutdown-resource diagnostics. Passing assertions and the targeted zero-teardown-error gate are not described as warning-free execution.

Remaining checks include runtime testing of the rebuilt Android artifacts, production IDs/signing, privacy/support URLs and identity, Data safety/audience/rating declarations, production SDK/backend checks, physical devices, proven network-disconnected play, 16KB/ZIP packaging checks and broader browser coverage. Later documentation-deployment continuity is recorded separately in the ignored build/publication-glyph-fix-final.json receipt and live build.json. Sunken Geodes remains a future DLC concept only. See [HANDOFF.md](HANDOFF.md).
