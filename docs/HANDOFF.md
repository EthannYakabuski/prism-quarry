# Prism Quarry handoff

**Expansion snapshot, 2026-11-14:** the working tree now contains 200 chambers, ten biomes, six twelve-rank upgrades and 42 refreshed desktop captures. This expansion is local only: no new push, CI run or deployment is claimed; the public build remains `58f069e`. [EXPANSION_ACCEPTANCE.md](EXPANSION_ACCEPTANCE.md) records the new automated/browser checks, static exports and remaining Android acceptance. The sections below retain the dated 30-chamber/B14 history and must not be read as proof of the expansion. The Nov13 and B14 JSON receipts remain unchanged.

## Current local expansion deliverables

The source has 200 chambers, ten biomes and six twelve-rank upgrades. The local review includes 42 genuine desktop captures, with original hashes and a narrow attestation for the later unpictured result-button text correction. See [expansion acceptance](EXPANSION_ACCEPTANCE.md), [exact local artifact receipt](expansion-evidence.json) and [economy/migration details](ECONOMY_AND_MIGRATION.md).

| Local path | Scope |
| --- | --- |
| `build/expansion-20261114/android/prism-quarry-test.apk` | Version 1.1.0/code 2; verified debug signature, same prior certificate; SHA256 `0c4395be2dd47dab846d0fc4b9113b555e2494694fa27914f4cff8d27a50be74` |
| `build/expansion-20261114/android/prism-quarry-debug.aab` | Unsigned development bundle; SHA256 `5bc87f3da28cf5452f335befc0abec3034a87e39ddc31bd979d13b9f5c90d5a2` |
| `build/expansion-20261114/site/play/` | Final ordinary single-threaded Web export; 533 PCK entries and nine file hashes verified |
| `review/index.html` | Direct-file review with current expansion fallback images; HTTP enables all 42 desktop captures and profile controls |
| `marketing/play-games-achievements/prism-quarry-achievements-google-play.zip` | Updated milestone wording; unchanged keys/thresholds/points; SHA256 `f978d0f1338d01acee607fad9e713362a3e1ce35b735f63f2d5be7f5af5aa60e` |

Build outputs are ignored local artifacts, not repository downloads. The ordinary Web export passed fresh-profile input, payout/reload, untouched-exit and unavailable-continuation checks; representative chambers 1, 101 and 200 were played separately in an explicitly seeded QA browser build. New Android installation/play remains unverified. A minor decorative Web floor/backwall palette difference is documented; gameplay remains readable. No new push, hosted CI, deployment or store publication is claimed.

## Historical edition record

The Godot 4.5.1 project includes the verified live label-corrected Web build at `7950a924c434f5f7755bf311e9eee37b866173d1`, rebuilt Nov14 Android debug APK/AAB, genuine captures, styled review and store materials. Runtime correction revision: `363d0f6c9728fc4ed72c9322fe9f688cd68510ac`. Local fixtures and actual live-browser checks pass. The refreshed Android packages pass static checks but have not been installed or played; Nov13 native captures and the earlier receipt remain historical evidence. Later documentation-only publication needs its own exact build-identity receipt.

- [Repository](https://github.com/EthannYakabuski/prism-quarry)
- [Play live](https://ethannyakabuski.github.io/prism-quarry/play/) and [live review](https://ethannyakabuski.github.io/prism-quarry/review/)
- [Acceptance and exact limitations](ACCEPTANCE.md)
- [Current label-fix tests, captures and Android identities](ui-glyph-fix-evidence.json)
- [Historical Nov13 five-artifact identity receipt](build-evidence.json)
- [Styled review - may also be opened directly from disk](../review/index.html)
- [Achievement ZIP](../marketing/play-games-achievements/prism-quarry-achievements-google-play.zip)
- [Store/release notes](STORE_AND_RELEASE.md) and [platform setup](PLATFORM_SETUP.md)

## Deliverables

| File/folder | Use |
|---|---|
| build/android/prism-quarry-test.apk | Nov14 B14 debug test APK, 274,649,002 bytes; SHA2d448b5e...; static checks pass, not installed or played |
| build/android/prism-quarry-debug.aab | Nov14 B14 debug AAB, 102,129,568 bytes; SHA2c84afad...; static checks pass, not installed or played |
| build/site/ | Assembled review and single-threaded Web export |
| review/index.html | Direct-file review with real fallback captures; HTTP enables all gallery controls |
| marketing/store/ | Listing, privacy, support and Data safety drafts |
| marketing/screenshots/ | 18 freshly rendered Nov14 desktop fixtures from B14 plus 11 retained Nov13 native frames; see manifests for their separate source identities |
| marketing/play-games-achievements/ | Finished ZIP, validation report and proposed metadata |

Compiled builds are excluded from Git. Preserve the local binaries or reproduce them and compare the receipt's full hashes. CI Web/optional Android artifacts use three-day retention. To serve the assembled review locally:

    python -m http.server 8768 --bind 127.0.0.1 --directory build/site

Open http://127.0.0.1:8768/review/ for the review or / for the game wrapper. A server/export alone does not establish Web play.

Current APK SHA256: `2d448b5ef11dd8ac8d3b302faa35271ed2c9649f4b86dd271f7803680cff14ff`. Current AAB SHA256: `2c84afade5ab16a22d536f22828129c258dfd633353e277333d53488da4eb39a`. Both exports used runtime revision 363d0f6 with identical source fingerprint `8d4bee2e8e8bfc0879009a822f25d30bf46864fe350c68c11784625a91164c26` and unchanged source during export. Package/configuration, ABI payload, manifest and static 64-bit ELF LOAD alignment checks pass. The previously played packages are preserved under ignored build/native/pre-glyph-fix-20261114/; their evidence is not reassigned to these rebuilt binaries.

## Verified scope

The retained Nov13 verification includes 189 model, 90 UI, ten native-style touch transitions, 36 platform-fixture and 31 achievement-validator checks. Nov14 local B14 verification passed the updated 128-check UI suite and ten touch transitions with zero teardown errors. Actual corrected-Nov13-APK touches, results, interrupted-before-earned reward restore, tablet-size profiles, repeated daily claim and zero-payout untouched abandon remain historical native evidence. Real banner, earned reward and third-session-round interstitial observations on the earlier APK retain that APK's provenance; the platform implementation is unchanged. All 30 chambers have three-star base-equipment simulation solutions.

All 18 desktop captures were regenerated after B14 in three graphical runs with isolated profiles. Dimensions, image hashes and 93 runtime-source hashes pass; all images were visually reviewed, including readable Pause and numeric shot labels at every profile size. They remain desktop fixture evidence, not Android or live-browser captures.

The earlier live revision `769b3cd9424f5f7181104f39791e092e56a72fa9` passed actual desktop-browser aiming/completion, banked-progress persistence and paused-run recovery. Chamber 1 cleared nine crystals for 1,800 points, three stars and +75 ore/+82 XP; chamber 2 retained eight crystals, 1,500 points and two shots after pause/reload/resume. Missing symbols in that run prompted B14's readable Pause label and numeric shot counter. Retained Nov13 native packages and screenshots do not demonstrate the label fix.

Chamber 2 then completed with 14 crystals, 2,475 points and three stars, awarding 93 ore/97 XP. Reloading from that result retained 218 ore, Miner 2 and chamber 03 unlocked without a duplicate payout.

Corrected live payload 7950a924 retained that progress. Pause/Resume and 3 SHOTS LEFT rendered without boxes or clipping. Chamber 3 then completed through an actual shot: 20 crystals, 6,750 points, three stars, +159 ore/+115 XP. Chamber 4 showed 3, 2 and 1 SHOT(S) LEFT through actual input; pause/reload required explicit Resume and retained one shot, zero crystals and zero points. The console warning/error query was empty at the final check. See the [B14 receipt](ui-glyph-fix-evidence.json) for exact provenance and limits.

Browser coverage remains limited: emulator Chrome 83 supports WebGL2 but cannot parse the official Godot JavaScript; separate cloud Chromium rendered the review but lacked WebGL 2 for gameplay. The earlier HTTP review check showed 18 gallery figures and six loaded selected-profile images; its missing-engine diagnostic displayed correctly. Native fully disconnected play remains inconclusive despite emulator setting changes; a validated network remained active. No physical-device or subjective audio acceptance is claimed.

## Verified hosting

The user explicitly authorized Prism Quarry Pages on 2026-11-14. Activation, the workflow gate and [deployment run 43541679015](https://github.com/EthannYakabuski/prism-quarry/actions/runs/43541679015) succeeded. The first verified live source was `769b3cd9424f5f7181104f39791e092e56a72fa9`; HTTP verification passed 98 responses, nine Web-file hashes, 516 PCK entries and all 29 captures. The [live build.json](https://ethannyakabuski.github.io/prism-quarry/build.json) identifies the current deployed revision, including later documentation commits.

The unchanged Nov13 receipt preserves the earlier approval-denial history as a dated snapshot. It does not describe the current hosting state. No Google Play upload/publication or achievement Console import was performed.

Corrected payload 7950a924 passed [validation 43544718140](https://github.com/EthannYakabuski/prism-quarry/actions/runs/43544718140) and [Pages 43544773056](https://github.com/EthannYakabuski/prism-quarry/actions/runs/43544773056), with 98 HTTP responses, nine Web-file hashes, 516 PCK entries and all 29 captures verified. The final documentation-only commit/deployment is separate from this tested payload and must be confirmed by its own live build.json receipt.

## Owner release inputs

Supply publishing identity, support email, privacy contact and public policy/support URLs. Review shipped SDK behavior before Data safety, audience and content-rating declarations. Configure/test production AdMob and Play Games, consent and signing; preserve production keys outside Git. Verify physical devices, genuinely disconnected operation, ordinary unearned ad closure, broader browser compatibility, audio/thermal behavior and 16KB-device/ZIP packaging requirements.

Test the rebuilt Android packages at runtime; their completed static checks do not establish native play. Preserve the retained Nov13 APK hashes and captures as historical evidence. The ignored build/publication-glyph-fix-final.json receipt records later documentation-deployment continuity separately from the tested 7950a924 gameplay payload.

Sunken Geodes is only a future concept: flooded chambers with refracting currents. No DLC content, price, release date or billing product is included.
