# Core verification

Godot 4.5.1 Compatibility. Baseline core evidence is dated 13 November 2026;
the local B14 label-correction rerun is dated 14 November 2026.

`game_model_test.gd`: **189 checks, zero failures**. It simulates every authored
chamber with the baseline drill, verifies three-star reachability within the
original shot budget, and checks deterministic snapshots, bounded simulation,
single-shot enforcement, seeded daily content, endless progression, validated
saves, backup recovery, failed writes, clock rollback, claims, stale results,
upgrades and once-only settlement. Exact solutions and strategy comparisons are
written to `build/evidence/game-model.json`.

Three-star solution shot counts:

| Environment | Chambers, in order | Straight first-shot wins | Repeated -70° sweep wins |
| --- | --- | --- | --- |
| Amber Hollow | 1,1,1,1,1,1,1,1,1,1 | 4/10 | 4/10 |
| Azure Grotto | 1,1,2,3,1,2,2,2,2,2 | 1/10 | 1/10 |
| Violet Vault | 2,3,2,2,2,3,3,2,2,3 | 0/10 | 0/10 |

These are sampled algorithmic solutions, not minimum-shot proofs or human
difficulty judgments. Later seams have fissures that interrupt crystal links.
Flight time is 2.4 seconds for the two tutorials, 1.55 for the rest of Amber,
1.35 for Azure and 1.2 for Violet; each flywheel rank adds 0.15 seconds. The aim
preview uses the same horizon and the same wall/bumper rules. It uses 90 Hz
sampling while actual motion uses bounded 120 Hz substeps, so grazing contacts
can differ slightly.

`game_ui_test.gd`: **128 checks, zero failures on 14 November 2026** after B14
(the retained Nov13 pass had 90 checks). A Viewport pointer press/release
actually launches the first seam. Checks include stationary pause, Back while
paused, foreground/background audio and explicit resume, cold restoration,
completion/results, repeated payouts, zero-activity abandonment, stale-run
rejection, menu routes and layouts, midnight daily refresh, deepest reached,
and full-screen lifecycle fixtures. Earned, unearned, duplicate and failed-save
reward callbacks are explicitly simulated fixtures; they do not establish SDK
or advertising acceptance. A failed earned-continuation save retains the
entitlement in memory while gameplay remains paused until a successful save.

The UI test refuses to run without a fresh
`-- --qa-profile=user://qa-ui-<unique>.json` argument. On the restricted Windows
executor, set process-local `APPDATA` to a task directory under `build/` and use
an explicit project-local `--log-file`; this keeps test data out of owner saves.
The model test creates and removes its own unique profile files.

The headless UI pass emitted a dummy-renderer `material is null` diagnostic and
the environment's root-certificate-store diagnostic, without a script
exception. The real graphical capture passes emitted only the certificate
diagnostic. No renderer error appeared in the graphical captures.

The Nov14 `game_capture.gd` refresh produced eighteen unmodified real viewport PNGs using OpenGL
3.3 on NVIDIA RTX A400: phone 1080 x 1920, 7-inch viewport 1200 x 1920, and 10-inch
viewport 1600 x 2560. Six views per profile: home, gameplay, Azure, Violet,
workshop and results. Later chambers are selected directly by a fixture;
results are computed by the actual shot model. The screenshots are desktop
viewport evidence, not physical Android-device screenshots or human gameplay.
Paths, dimensions, SHA-256 values and runtime source hashes are recorded in
`marketing/screenshots/provenance.json` and `capture-source.json`.

Native Android, real SDK callbacks, Web browser interaction, physical touch,
audio listening, accessibility, performance and human difficulty acceptance
must be described separately from these checks.

## Touch teardown regression

The ordinary Android build exposed a nonfatal `can_process` diagnostic when a
touch-triggered button replaced its screen. A graphical ScreenTouch fixture
reproduced the exact error eight times across ten button transitions; the same
mouse-only fixture produced zero. `_clear_ui` previously detached Controls
synchronously while native touch-to-mouse dispatch still retained references.
It now hides old Controls and lets `queue_free` detach them after dispatch.

The same graphical touch fixture produced **zero** `can_process` errors after
the correction, and all **90 UI checks passed again**. A headless run also
completed all ten expected transitions with zero such errors. The new
`game_touch_teardown_test.gd` asserts the ten screen outcomes and writes its
report; the CI wrapper scans the completed engine log because Godot does not
expose the consumed `--log-file` option to the script reliably. The paired
local evidence is `build/evidence/touch-teardown-comparison.json`.

All eighteen Nov13 captures were regenerated after this correction and the
singular `1 shot` result-label correction. Native repeat acceptance belongs
to the corrected Nov13 ordinary APK, not the earlier APK that first exposed
the diagnostic. Neither that APK nor those captures establishes the later
B14 label correction.

## B14 label correction, Nov14 local snapshot

Revision `363d0f6c9728fc4ed72c9322fe9f688cd68510ac` replaces the unsupported pause
symbol with ASCII `Pause`, sets its minimum control size to 96 x 44, and uses
a numeric shot counter. The updated local UI suite passed **128 checks**;
the touch regression passed **ten transitions with zero teardown errors**.

The correction passed actual isolated desktop-browser verification in deployed
revision `7950a924c434f5f7755bf311e9eee37b866173d1`: readable Pause and 3/2/1
shot counters, Pause/Resume, chamber-3 completion and chamber-4 paused reload
recovery retaining one shot, zero crystals and zero points. Validation run
43544718140 and Pages run 43544773056 succeeded. Later documentation-only
deployment continuity needs its own exact-SHA receipt. Retained Nov13 Android binary hashes,
native captures and `docs/build-evidence.json` are unchanged historical
evidence. All 18 desktop images were freshly captured from B14 in three sequential
graphical runs with isolated QA profiles, then visually inspected. Pause and numeric
shot labels are readable in all three viewport profiles. Dimensions, image hashes,
six successful saves per run and unchanged 93-file source identity were verified.
The previous desktop captures and manifests are preserved in the ignored local
capture archive; the public desktop manifests identify the new frozen source.
