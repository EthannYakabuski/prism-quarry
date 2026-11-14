# 200-chamber expansion: evidence and publication identity

The expanded development edition contains 200 chambers, ten biomes and six twelve-rank workshop choices. Publication is authorized. The local checks below were recorded on 2026-11-14; [expansion-evidence.json](expansion-evidence.json) preserves their prepublication snapshot. Historical CI, browser and Android observations in [ACCEPTANCE.md](ACCEPTANCE.md), [build-evidence.json](build-evidence.json) and [ui-glyph-fix-evidence.json](ui-glyph-fix-evidence.json) remain bound to their original revisions.

## Verify the published revision

Open the [game](https://ethannyakabuski.github.io/prism-quarry/play/) or [review](https://ethannyakabuski.github.io/prism-quarry/review/), then compare [live build.json](https://ethannyakabuski.github.io/prism-quarry/build.json) with the exact source revision of its successful [validation](https://github.com/EthannYakabuski/prism-quarry/actions/workflows/ci.yml) and [Pages](https://github.com/EthannYakabuski/prism-quarry/actions/workflows/pages.yml) runs. The assembled review also displays source identity. These links identify where to verify publication; authorization, a prepared workflow and local acceptance do not themselves establish deployment success.

## Implemented scope

The campaign has 200 chambers in ten biomes of twenty. The original thirty layouts retain their geometry at zero-based indices 0-9, 20-29 and 40-49; the other 170 use sixteen arrangement motifs. Scenery varies through industrial props, foliage, ice shelves, basalt formations, stone structures and crystal ridges. These decorations do not introduce collision rules.

The workshop has six choices with twelve ranks each: Longburn drill, Echo lens, Salvage rig, Focus tip, Prism resonator and Combo calibrator. Shared effect definitions drive gameplay and visible chain links. Round ore is reduced while existing balances, purchased ranks and XP are preserved. Clear feedback holds the finished board for 0.85 seconds before the result popup's 0.28-second transition; reduced motion retains a stationary fade.

Vault Keeper remains a thirty-chamber milestone and Master Miner a ninety-star milestone. Only their descriptions changed; achievement keys, thresholds, icons and points remain intact. The regenerated ZIP passes the existing plural-filename schema and finished-file verification. No Console import or backend mapping change is claimed.

## Local automated evidence

| Check | Actual recorded result | Scope |
| --- | --- | --- |
| Campaign | 4,398 checks, zero failures; all 200 campaign and 200 seeded daily solution replays pass | Every replay uses base equipment; 108 daily layouts are mirrored. Deterministic simulation, not manual play of every chamber or upgraded-equipment testing. All campaign baseline solutions earn three stars within their original shot budgets, without a rewarded continuation. |
| Geometry | 200 exact mirror/color-invariant and 200 coarse half-unit signatures | Original layouts preserved; 170 additional layouts span sixteen motifs. |
| Profile/economy | 8,732 checks, zero failures | Legacy frontiers, saved rounds, migration/recovery, six upgrade caps/effects, payouts and settlement behavior. |
| Real prior QA saves | Five actual historical QA saves, 30 checks, zero failures | Migration fixtures derived from retained task-owned native QA saves; this is not fresh expanded-APK input testing. |
| UI | 219 checks, zero failures after the final-result label correction | Expanded map/workshop, bounds, result timing, final Return home action and interaction fixtures. The earlier local report had 217 checks. |
| Touch teardown | Ten ScreenTouch transitions, zero failures and zero can_process errors | Final local rerun after the label correction; distinct from historical Android evidence. |
| Platform callbacks | 36 checks, zero failures in a fresh isolated project | Service/callback fixtures only; native SDK proof is explicitly false. |
| Achievement package | 31 adversarial self-tests and finished ZIP reread pass | 20 achievements, 22 flat entries, 720 points. Authoring artifact only. |
| Desktop captures | 42 actual graphical renders; all dimensions and hashes pass; all visually inspected | Ten biome fixtures plus home/map/workshop/results at three sizes. No script or touch-teardown errors in the completed capture logs. |

Detailed local reports are retained in ignored `build/evidence/campaign-expansion.json`, `profile-expansion.json`, `game-ui.json` and the economy reports. The campaign report records an average solution length of 1.68 shots in chambers 1-60, 2.10 in 61-140 and 2.23 in 141-200. These are sampled algorithmic solutions, not minimum-shot proofs or measured human difficulty.

The matched-payout analysis applies the actual payout functions to the same recorded crystals, scores, wins and daily entitlement. Across the 200 baseline three-star clears, rank-zero ore changes from 25,633 to 5,043; legal historical salvage rank four changes from 40,737 to 8,065. New salvage ranks five through twelve retain 20.625%-25% of the capped historical total, and each checked integer payout is at most one quarter of its matched historical payout. XP is unchanged.

All 72 workshop ranks cost 17,568 ore in total. A fixed-score spending benchmark reaches the first purchase after chamber 2; prioritizing only Longburn reaches rank twelve after chamber 116. This benchmark assumes a fresh profile, the first login gift, and one baseline three-star clear per chamber, without ads, replays, daily or quest income. It holds recorded shot outcomes fixed after purchases and is not an upgraded physics or human-progression test.

## Fresh capture provenance and visual review

The original 426-input capture manifest remains unchanged. A separate [validation scope](../marketing/screenshots/capture-validation-scope.json) classifies 295 repository inputs as mandatory and exactly 131 ignored local SDK installation files as archival. Fresh checkouts may omit only that pinned SDK set; any present archival file must still match its original hash. The committed Android AARs, game, assets, capture fixture and exact post-capture label attestation remain strict. A Git-only temporary-checkout regression exercises successful validation, missing and changed mandatory inputs, corrupt present SDK copies, and attempts to broaden the optional classification.

The [42-image manifest](../marketing/screenshots/provenance.json) and [source identity](../marketing/screenshots/capture-source.json) identify the frozen working tree by SHA256 `d626287db94a8afa57f92a967986726a6e01154b052ee340846b62aab2861059`, with 426 source-file hashes. The existing HEAD at capture was the older public revision; it is explicitly not presented as the expansion source commit. Three sequential graphical Godot 4.5.1 Compatibility runs used fresh isolated QA profiles and rendered 14 views each at 1080 x 1920, 1200 x 1920 and 1600 x 2560. Source hashes remained unchanged across the runs.

Every original PNG was visually inspected. Long biome headings, Pause, numeric shot counters, crystals, bumpers and aim guides remain readable. All result popups are fully visible, showing the actual simulated chamber-one result of 1,800 points, nine crystals, one shot, three stars, +15 ore and +82 XP. The map shows 200 chambers and ten pages; visible workshop cards show current/next effects and twelve-rank limits. The initial map/workshop scroll positions do not show every title or all six cards at once.

Some pale scenery behind headings reduces local contrast, without hiding text in the checked frames. The existing gem table and wooden bracket slightly overlap the lower board edge but obscure no displayed ore, bumper or launcher. No blocking clipping, missing glyph or overlay was found. These are direct-selection desktop rendering fixtures, not Android or physical-device play.

The complete previous screenshot tree and manifests were archived with 46 verified file hashes under ignored `build/pre-expansion-20261114/screenshots/`. The eleven public native images retain their original Nov13 APK identities and remain explicitly historical. Old achievement materials are separately archived under `build/pre-expansion-20261114/achievement-import/`.

After capture, actual final-chamber play exposed one inaccurate button label: it said Back to the workshop although its existing action returns home. The sole later `game/main.gd` change replaces that label with Return home, without changing the callback. The same branch also handles non-campaign wins. None of those result states appears in the 42 frames; the result fixture is campaign chamber one. Original image bytes and captured source hashes remain intact. The source manifest records both script hashes, and `validate_store.py` reverses the one exact statement to reproduce the captured hash before accepting this narrowly scoped difference. It still rejects other runtime drift and a changed capture script. Six temporary-file checks passed, including rejection of an unrelated edit even when its new hash was added to the attestation.

## Actual local browser observations

The isolated desktop in-app browser rendered a local expanded Web export using an explicitly seeded QA fixture: base equipment, 2,500 ore and all campaign chambers unlocked. Actual drag input in chamber one cleared nine crystals for 1,800 points. The finished cave remained visible beneath the animated result popup; +15 ore was displayed. Reload returned home at 2,515 ore and Miner 2, confirming this observed result did not pay twice.

In chamber 101, actual pointer input cleared 17 crystals for 2,625 points in four shots, with eight ricochets and three stars, paying +20 ore/+106 XP. Pausing during the third shot and reloading restored a paused chamber and required explicit Resume; play continued in the same round. A manually aimed recovery shot completed the run. The popup appeared over the remaining cave, and home showed 2,535 ore, exactly the seeded balance plus the two observed awards.

Chamber 200 reached its quota with 18 of 21 crystals, 3,400 points, four shots, ten ricochets and one star, paying +22 ore/+109 XP. The CHAMBER CLEAR hold was observed before the popup, and home reached 2,557 ore. This was a successful quota clear, not a manual three-star result. All three manually played chambers used base equipment.

After those rounds, an actual workshop purchase raised Prism resonator to rank one for 35 ore: 2,557 to 2,522. Reload retained the balance and the workshop showed 1/12, Now 2.15 m, Next 2.19 m and next price 53. Six cards, scrolling and twelve-rank caps were visible. The console warning/error query returned an empty list at the end; this does not assert an entirely silent session. These are local browser input and persistence observations, not live Pages, solver execution or an unseeded full campaign run. They precede the sole final-result text correction; the final 219-check UI and ten-transition touch runs separately cover the corrected source. The QA browser tab was closed and its loopback server stopped with exit zero.

## Build and acceptance boundaries

The final ordinary local Web export was then played in the isolated in-app browser with a fresh, unseeded profile: home began at 10 ore and chamber one. Actual drag input cleared nine crystals for 1,800 points and three stars, awarding +15 ore/+82 XP. Reload retained home at 25 ore, Miner 2 and chamber two. Pausing and leaving untouched chamber two kept 25 ore, with no award. Three actual drag/recall shots produced a failed zero-crystal, zero-point, zero-star run; its ad continuation was disabled with unavailable text and granted no fake entitlement. Banking that played failure paid one ore, as expected from floor(8 x 0.2), returning home at 26 ore. This is distinct from the untouched exit, which paid zero. The final console warning/error query returned an empty list. The final-chamber Return home label itself was checked by the 219-test UI suite, not revisited through actual final-chamber browser play after the text patch.

A minor presentation difference remains: decorative floor/backwall materials appear more silver-grey in the ordinary Web export than in the separate QA build and desktop captures. The playfield, gems and labels remain unobscured, and no runtime error was observed during this check. Read-only comparison found identical relevant source GLBs, cave colormap, import metadata and cavern code, with no duplicate asset import UIDs; imported scene blobs differ between caches. Cache/serialization variation is plausible but unconfirmed. Assets and caches were preserved, and cross-export decorative palette parity is not claimed.

All three final exports use the same 443-file source fingerprint, `4b5bcf9e4903282b5ae1f846025e63ff15d8037ea89db88bd6b9664ced33e08d`, with unchanged source during each export. It covers a broader source/license scope than the separate capture fingerprint. Exact identities and scope are in [expansion-evidence.json](expansion-evidence.json).

| Local artifact | Bytes | SHA256 |
| --- | ---: | --- |
| Ordinary debug APK | 274,771,924 | `0c4395be2dd47dab846d0fc4b9113b555e2494694fa27914f4cff8d27a50be74` |
| Unsigned development AAB | 102,253,043 | `5bc87f3da28cf5452f335befc0abec3034a87e39ddc31bd979d13b9f5c90d5a2` |
| Web PCK | 11,123,184 | `bba01c58012a72d9f04b35ee82e8054ff00d668c53d6f0960c24c62018e7be6b` |
| Official Web WASM | 38,034,280 | `6498359ba889796a0d95a2f71113ac184badc0f2d84cf28f4103c7e399d2d547` |

Both native packages report version 1.1.0/code 2, min API 24/target 36, Google sample AdMob configuration and absent production Play Games ID. Their 539 asset entries, matching three ABI payloads and static 64-bit ELF LOAD alignment pass. The APK's debug signature verifies and uses the same certificate as the prior test APK. The AAB is unsigned, as was the prior development bundle; it is not a signed release artifact. Web has 533 verified PCK entry checksums and nine verified output files, with all eight game-script payload hashes identical to the APK. Only the main script payload changed after the final label fix; earlier export bytes were archived.

A desktop OpenGL window rendered, but no controllable native window was exposed to the input tool; no native input acceptance is inferred from that launch.

Expanded Android installation/play, physical-device behavior, production ads/Play Games, production signing and Google Play store publication are not established here. Hosted CI and deployment evidence must identify the exact served revision separately from the retained local receipt. Historical native frames and earlier public revisions do not prove this expansion's Android behavior.
