# Prism Quarry acceptance record

Evidence date: 2026-11-13. The corrected game has final Android debug APK/AAB exports, a matching single-threaded Web export, passing model/UI/touch/platform fixtures and genuine desktop/Android-emulator captures. This is development acceptance, not a production-release certification.

Runtime correction revision: [f0fdea95a100c1250e5e5b94f04b568142209629](https://github.com/EthannYakabuski/prism-quarry/commit/f0fdea95a100c1250e5e5b94f04b568142209629). [build-evidence.json](build-evidence.json) is the prepublication verification snapshot: five actual artifact identities and source/worktree state recorded on 2026-11-13. The snapshot includes [hosted run 43475885486](https://github.com/EthannYakabuski/prism-quarry/actions/runs/43475885486), which passed at aa830e55. For later publication state, compare the exact commit against [current CI runs](https://github.com/EthannYakabuski/prism-quarry/actions/workflows/ci.yml); the final source SHA and CI outcome are recorded separately in the local publication receipt and delivery response.

## Automated and static checks

| Area | Recorded result | Scope |
|---|---|---|
| Model | 189 checks, 0 failures | All 30 chambers have base-equipment three-star simulation solutions. Straight-first-shot and fixed-angle-sweep strategies each clear only five. |
| Application/UI | 90 checks, 0 failures | Navigation, bounds, Viewport pointer dispatch, once-only results/claims, save failures, cold restore, Back/focus/fullscreen and synthetic reward cases. |
| Touch teardown | 10 ScreenTouch transitions, 0 failures, 0 can_process errors | Fresh isolated profile; wrapper requires all expected screens, a new report and actual completed engine log. This is a headless input fixture, separate from final native touch retest. |
| Platform | 36 checks, 0 failures | Isolated service/callback/configuration fixtures, not backend proof. |
| Achievement validator | 31 self-tests pass | Finished ZIP independently reopens: 20 achievements, 22 flat entries, 720 proposed points. No Console import or acceptance is claimed. |
| Desktop captures | 18 unmodified images; 93 source hashes checked | Six actual rendered fixture views each at 1080 x 1920, 1200 x 1920 and 1600 x 2560. Regenerated after the touch/plural fix. |
| Native captures | 11 selected PNG/JSON pairs validate | Nine final-APK emulator frames plus two explicitly labelled prior-APK Google test-ad QA frames. |
| Web export | 516 PCK entry checksums pass | Required game/catalog/audio/service resources present; prohibited test/marketing/private payload absent; official single-threaded Godot 4.5.1 templates. |
| Store/review | Asset dimensions and copy lengths pass | Icon 512 x 512; feature 1024 x 500; splash 1080 x 1920; title/short/long lengths 12/73/1609. Artwork remains separate from gameplay. |

Local reports are retained under build/evidence/, build/native/ and build/*validation.json; build outputs and raw logs are excluded from Git. The receipt contains concise verification summaries. Capture evidence: [desktop manifest](../marketing/screenshots/provenance.json), [source hashes](../marketing/screenshots/capture-source.json), [native manifest](../marketing/screenshots/android-provenance.json). Achievement details: [validation report](../marketing/play-games-achievements/validation-report.json) and [schema notes](ACHIEVEMENTS_IMPORT.md).

## Final Android packages

- APK: 274,649,262 bytes; SHA256 69581fe0ab4ece0fa08a7fab40eb2084f747500aa6a3254faa740022eec5b60c.
- AAB: 102,129,822 bytes; SHA256 b6be1f9ac82397bbba7946da3992ad779036a68a4247f54248a71597f9eeea4f.

Both debug exports returned zero with unchanged source fingerprints during export. Actual packages contain matching ARM64, x86 and x86_64 payloads. The manifest reports min API 24, target API 36, Google test AdMob app ID and no production Play Games app ID. Each package's 522 asset entries pass configuration and payload checks.

Static 64-bit ELF LOAD alignment passes. This does not prove 16KB-device execution, ZIP alignment or the AAB BundleConfig page-size declaration. Production signing remains unconfigured.

## Actual ordinary-APK runtime

Testing used a task-owned disposable Pixel_API_30 x86 emulator, API 30, serial emulator-5560. Inputs were actual emulator touch/Back/lifecycle actions; no save fixtures were injected. No physical device is claimed.

**Prior APK, with unchanged service/progression implementation:** a real Google sample banner displayed. A drag/release cleared nine crystals for 1,800 points and three stars, paying 75 ore/82 XP. Android Back paused; force-stop/relaunch restored the same checkpoint paused; another Back still required explicit Resume. A real Google rewarded test ad earned a continuation; closing it persisted two extra shots and required Resume. Consuming those shots produced no second offer. A Google test interstitial appeared on the third session round and dismissed into the workshop. Repeated upgrade input charged 180 ore once (216 to 36, gear level 1). These observations remain bound to the earlier APK hash in their provenance, rather than being relabelled as the final binary.

**Final corrected APK:** rapid native menu/recall/result transitions passed with zero observed native can_process teardown errors. A rewarded video was force-stopped before earning; cold restore retained continued=false and zero shots, proving interrupted presentation granted no entitlement. Play then continued. The actual 1200 x 1920, density 320 emulator profile cleared 14 crystals in two shots for 2,475 points, three stars and +93 ore/+97 XP. The 1600 x 2560, density 300 profile showed the result and chapter 3 gameplay. These are emulated tablet-size profiles, not physical tablets.

Returning from the browser required explicit Resume. Two actual Collect reward taps paid the daily claim once: ore 137 to 227 and XP 306 to 346, with the clears claim recorded. Leaving untouched chapter 3 produced a zero-ore/zero-XP receipt.

**Limits:** an early Back attempt during a rewarded video was ignored by the SDK and the ad later earned, so ordinary user-initiated unearned ad closure is not verified by that attempt. Interrupted-before-earned force-stop is separately verified. Full native offline acceptance is inconclusive: Wi-Fi/data settings were disabled and airplane mode enabled, yet Connectivity still reported validated network 101. Connectivity and display defaults were restored. Do not treat filenames containing offline as offline proof. Physical-device behavior, subjective audio/thermal performance and production services remain untested.

The initial System UI ANR, splash transitions, OS overlays, repetitive frames and unselected third-party ad creative were preserved in ignored local build/native/qa-archive/ or rejected-captures/. Only clean selected images remain in the public capture folders. Test-ad images are labelled QA and kept outside marketing gameplay.

## Browser and review

The existing emulator browser is Chrome 83. Read-only diagnostics established a secure localhost context, WebGL2=true and WebAssembly availability. The fetched official engine JavaScript fails parsing with SyntaxError: Unexpected token '='; Engine remains undefined. **Web gameplay is not run. This is an old-browser JavaScript compatibility limit, not missing WebGL2.** Modern-browser load/input/persistence remains untested.

The review's replaceChildren calls were replaced with textContent clearing, and a flex-gap margin fallback was added for Chrome 83. The review also contains real static fallback images for direct file opening; HTTP enables full profile controls. The assembled game HTML checks for a missing Engine and displays an update-browser message before engine startup. Official index.js is unmodified. The HTTP review refresh was observed successfully in Chrome 83: 18 gallery figures were present and six images loaded for the selected profile. Actual desktop gameplay/home cards and their truthful captions were visually confirmed (local build/browser/13-review-gallery.png). The missing-engine visual diagnostic also displayed correctly. This confirms review rendering and the diagnostic, not Web gameplay.

Earlier host attempts: IAB was unavailable; isolated host Chrome exited 0x80000003 without a page; a process-command-line query returned Access denied. No personal browser profile, security-warning bypass or security-setting change was used.

## Publication

The [public repository](https://github.com/EthannYakabuski/prism-quarry) exists. Initial CI omitted four Poing AARs due to an upstream ignore rule; the exact licensed binaries were tracked and the subsequent hosted validation passed.

**Pages remains blocked, not deployed.** Automatic approval review denied POST repos/EthannYakabuski/prism-quarry/pages with build_type=workflow. The single identical retry after history review was also denied: no trusted user message authorizes persistent public hosting while retained context records a publication hold. That action stopped. The local review and gated workflow are ready; no live URL or bypass is claimed. Google Play publication and achievement Console import were not performed.

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

Local headless logs retain root-certificate-store, dummy-renderer material and shutdown-resource diagnostics. Passing assertions and the targeted zero-teardown-error gate are not described as warning-free execution.

Remaining owner work: production IDs/signing, privacy/support URLs and identity, Data safety/audience/rating declarations, production SDK/backend checks, physical devices, proven network-disconnected play, 16KB/ZIP packaging checks and modern-browser play. Sunken Geodes remains a future DLC concept only. See [HANDOFF.md](HANDOFF.md).
