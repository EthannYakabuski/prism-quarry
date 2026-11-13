# Core verification

Godot 4.5.1 Compatibility; final local core pass on 13 November 2026.

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

`game_ui_test.gd`: **90 checks, zero failures**. A Viewport pointer press/release
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

`game_capture.gd` produced eighteen unmodified real viewport PNGs using OpenGL
3.3 on NVIDIA RTX A400: phone 1080×1920, 7-inch viewport 1200×1920, and 10-inch
viewport 1600×2560. Six views per profile: home, gameplay, Azure, Violet,
workshop and results. Later chambers are selected directly by a fixture;
results are computed by the actual shot model. The screenshots are desktop
viewport evidence, not physical Android-device screenshots or human gameplay.
Paths, dimensions, SHA-256 values and runtime source hashes are recorded in
`marketing/screenshots/provenance.json` and `capture-source.json`.

Native Android, real SDK callbacks, Web browser interaction, physical touch,
audio listening, accessibility, performance and human difficulty acceptance
must be described separately from these checks.
