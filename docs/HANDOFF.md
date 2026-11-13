# Prism Quarry handoff

The corrected Godot 4.5.1 game, debug Android APK/AAB, matching Web export, styled review, 18 desktop captures, 11 selected native evidence frames and store/achievement materials are ready. Runtime correction revision: f0fdea95a100c1250e5e5b94f04b568142209629. The linked receipt is a prepublication verification snapshot dated 2026-11-13. Compare an exact source commit with [current CI runs](https://github.com/EthannYakabuski/prism-quarry/actions/workflows/ci.yml); final publication identity and CI outcome are recorded separately in the local publication receipt and delivery response.

- [Repository](https://github.com/EthannYakabuski/prism-quarry)
- [Acceptance and exact limitations](ACCEPTANCE.md)
- [Five-artifact identity receipt](build-evidence.json)
- [Styled review - may also be opened directly from disk](../review/index.html)
- [Achievement ZIP](../marketing/play-games-achievements/prism-quarry-achievements-google-play.zip)
- [Store/release notes](STORE_AND_RELEASE.md) and [platform setup](PLATFORM_SETUP.md)

## Deliverables

| File/folder | Use |
|---|---|
| build/android/prism-quarry-test.apk | Final installable debug test APK, SHA69581fe0... |
| build/android/prism-quarry-debug.aab | Final debug AAB, SHAb6be1f9a... |
| build/site/ | Assembled review and single-threaded Web export |
| review/index.html | Direct-file review with real fallback captures; HTTP enables all gallery controls |
| marketing/store/ | Listing, privacy, support and Data safety drafts |
| marketing/screenshots/ | 18 desktop rendered fixtures and selected native emulator frames with provenance |
| marketing/play-games-achievements/ | Finished ZIP, validation report and proposed metadata |

Compiled builds are excluded from Git. Preserve the local binaries or reproduce them and compare the receipt's full hashes. CI Web/optional Android artifacts use three-day retention. To serve the assembled review locally:

    python -m http.server 8768 --bind 127.0.0.1 --directory build/site

Open http://127.0.0.1:8768/review/ for the review or / for the game wrapper. A server/export alone does not establish Web play.

## Verified scope

189 model, 90 UI, ten native-style touch transitions, 36 platform-fixture and 31 achievement-validator checks pass. Actual final native touches, results, interrupted-before-earned reward restore, tablet-size profiles, repeated daily claim and zero-payout untouched abandon were exercised. Real banner, earned reward and third-session-round interstitial observations on the prior APK retain that APK's provenance; the platform implementation is unchanged. All 30 chambers have three-star base-equipment simulation solutions.

The final Web PCK has 516 checksum-verified entries. Chrome 83 on the emulator supports WebGL2 but cannot parse the official Godot JavaScript; Engine remains undefined. The HTTP review was observed with 18 gallery figures and six loaded images; its missing-engine diagnostic displayed correctly. The assembled HTML provides a general update-browser message. Modern-browser gameplay is untested. Native fully disconnected play is also inconclusive despite emulator setting changes; a validated network remained active. No physical-device or subjective audio acceptance is claimed.

## Hosting blocker

Pages activation was denied by automatic approval review, including one retry after relevant history was read. Exact action: POST repos/EthannYakabuski/prism-quarry/pages with build_type=workflow. Stated reason: missing trusted authorization for persistent public hosting and a retained publication hold. No Pages site or verified live review URL exists. The local review and gated workflow remain ready; do not repeat or bypass this action without materially new authorization.

The public repository and successful earlier CI run are separate from this blocker. No Google Play upload/publication or achievement Console import was performed.

## Owner release inputs

Supply publishing identity, support email, privacy contact and public policy/support URLs. Review shipped SDK behavior before Data safety, audience and content-rating declarations. Configure/test production AdMob and Play Games, consent and signing; preserve production keys outside Git. Verify physical devices, genuinely disconnected operation, ordinary unearned ad closure, modern-browser input/persistence, audio/thermal behavior and 16KB-device/ZIP packaging requirements.

Sunken Geodes is only a future concept: flooded chambers with refracting currents. No DLC content, price, release date or billing product is included.
