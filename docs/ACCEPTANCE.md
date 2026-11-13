# Prism Quarry acceptance record

Status: implementation in progress. This document is a checklist until dated evidence is added. No unchecked item is a passing claim.

## Required checks

| Area | Required observation | Evidence status |
|---|---|---|
| Core loop | Aim and release through ordinary controls; ricochets hit visible crystals; chain reaction and results agree with model | Pending |
| Content | All 30 chambers succeed with base equipment using the real simulation; three distinct themes | Pending |
| Repeated actions | Rapid repeated launch/recall/result/claim/upgrade cannot duplicate action or reward | Pending |
| Interruption | Back/background/focus loss/pending ad freeze shot and require explicit resume | Pending |
| Persistence | Cold restart during shot and result; atomic save and backup; corrupt save recovery | Pending |
| Daily progression | UTC rollover and backward-clock handling; seven-day gifts/goals pay once | Pending |
| Progression | XP/levels/rig purchases; all achievement metrics and leaderboard mappings | Pending |
| Ads | Real sample banner, interstitial presentation/dismissal, earned and unearned rewarded closure; application callback fixtures separately | Pending |
| Services | Disabled PGS and unavailable native services preserve offline play; pending records durable | Pending |
| Android | Ordinary debug APK install/launch/play/save/Back on identified isolated emulator; bundle ABI consistency | Pending |
| Web | Export, browser load/input/reload persistence when WebGL2 is available | Pending |
| Responsive UI | Genuine game captures at phone and 7/10-inch viewport sizes; no clipping or misleading platform labels | Pending |
| Store/branding | Icon/feature/splash/20 badges/3 boards/listing and styled review | Pending |
| Achievement import | Finished ZIP independently reopened and statically validated against owner-confirmed Beacon schema | Pending |
| Publication | New public repository; audited intended files only; exact remote SHA and passing hosted CI | Pending |

## Evidence classes

- **Actual runtime**: real Godot rendering and input, or real Android install/launch/interaction. Record runtime build identity, viewport, input path, and whether setup was seeded.
- **Simulated fixtures**: deterministic model tests, isolated profiles, mocked service callbacks. These establish application behavior, not SDK/backend or human-play success.
- **Not tested**: physical device touch/audio/thermal performance, production AdMob/PGS/backend/signing, and any environment-blocked path. State the limitation directly.

Desktop phone/tablet viewport captures are genuine implemented-game images but do not establish physical-device or native Android verification. Diagnostic acceptance APKs, if used, remain separate from the ordinary APK. No Play Console import or Google Play publication is permitted in this run.

## Bug log

| ID | Observed defect | State |
|---|---|---|
| B01 | First import lacked the cave model's external colormap texture | Corrected; final import verification pending |
| B02 | Paused Android Back could resume without the Resume action | Corrected in source; lifecycle regression pending |
| B03 | A cold-restored endless descent checkpoint could lose its Descend action | Corrected in source; lifecycle regression pending |
| B04 | Banking an untouched run could farm coins and XP | Correction and regression pending |
| B05 | First rendered HUD wrapped score/ore labels vertically and clipped home actions | Visual correction and fresh capture pending |
| B06 | First rendered cave textures/lighting were overexposed | Visual correction and fresh capture pending |
| B07 | Bank Shot description said wall-only while its metric includes bumper ricochets | Catalog wording corrected; import ZIP regenerated and statically verified |
| B08 | Daily completion across midnight and endless depth-on-entry had inconsistent achievement semantics | Correction and regression pending |
| B09 | Background/focus interruption did not consistently suspend music | Correction and regression pending |

Initial model pass: 152 checks, zero failures, including base-equipment chamber completion. Initial platform fixture pass: 30 checks, zero failures. These precede the final regression pass and are not final-build acceptance claims. The Windows host reported a root-certificate-store warning; no security settings were changed.
