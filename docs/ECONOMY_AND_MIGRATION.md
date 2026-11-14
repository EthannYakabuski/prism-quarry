# Economy and save migration

The expanded campaign has 200 chambers and six optional workshop choices with 12 ranks each. Existing currency, XP, purchased ranks and achievement flags are retained. The 200-level solver receipt demonstrates baseline three-star solutions without upgrades, ads or replay income; spending never gates campaign access.

## Shared upgrade contract

`game/upgrades.gd` owns `KEYS`, `cap(key)`, `price(key, current_rank)`, `title(key)`, `description(key)`, `effect_label(key, rank)` and `next_effect_label(key, rank)`. Price means the next purchase; it returns zero for an unknown or capped key. `Profile.upgrade()` checks the cap, balance and successful save before changing in-memory progress.

| Key | Choice | Rank 12 effect | Rank 1 / 6 / 12 purchase | All 12 ranks |
|---|---|---|---|---|
| drill | Longburn drill | +1.08 seconds flight | 30 / 180 / 558 ore | 2,868 ore |
| echo | Echo lens | 1.52 m matching reach | 35 / 185 / 563 ore | 2,928 ore |
| salvage | Salvage rig | Up to 25% of the historical capped reference payout | 40 / 190 / 568 ore | 2,988 ore |
| focus | Focus tip | 0.62 m crystal contact margin | 30 / 180 / 558 ore | 2,868 ore |
| prism | Prism resonator | 2.64 m white-prism reach | 35 / 185 / 563 ore | 2,928 ore |
| combo | Combo calibrator | +12% crystal score | 40 / 190 / 568 ore | 2,988 ore |

Each next price is its category's base price plus `15 × current_rank + 3 × current_rank²`. All 72 purchases cost 17,568 ore. Drill and echo retain their exact rank 0–4 effects: +0.15 seconds/rank and +0.06 m/rank. Later ranks add smaller increments. The new effects start at zero benefit, so baseline physics is unchanged. `Run.chain_radius(kind)` is shared by fracture logic and vein rendering. Upgrades never add shots or synthesize an ad entitlement.

## Payout guarantee and measured pacing

For the same recorded crystals, score, outcome and eligible daily bonus, the historical reference is:

```
reference = crystals × (2 + clamp(salvage_rank, 0, 4))
          + floor(score / 80) + (35 for a win, otherwise 8)
```

An untouched zero-crystal run zeroes that base, matching the old rule. Add the old 120-ore daily entitlement only when it is earned and not already paid. The legal historical salvage cap was four; new ranks never expand that comparison baseline.

The new integer award is `floor(reference × numerator / 4000)`, additionally clamped to `floor(reference / 4)`. The numerator is 800 through salvage rank four, then increases by 25 per rank to 1,000 at rank 12. This retains 20% initially and at most 25% at maximum salvage, including the daily bonus. Combo upgrades can change the recorded score; the matched comparison always uses that same score in both formulas. No flat ore bonus is appended after the cap.

Measured from the actual 200 baseline three-star solutions in `build/evidence/campaign-expansion.json`:

| Fixed salvage scenario | Old matched campaign total | New total |
|---|---:|---:|
| Rank 0 | 25,633 | 5,043 |
| Rank 4 | 40,737 | 8,065 |
| Rank 12, compared with historical cap 4 | 40,737 | 10,106 |

Rank-zero awards average 25.25 ore in chambers 1–20, 22.80 in 91–110 and 26.45 in 181–200. The first chamber's old 75 ore becomes 15; its eligible daily total of 195 becomes 39. Award flooring is per run, not applied once to the campaign total.

The spending benchmark starts with the new 10-ore first login gift and clears each chamber once using its recorded baseline score/crystals. It assumes no failed runs and includes no ads, replays, quests or later login income. Choosing the cheapest available next rank yields all six choices at rank 2 after chamber 20 and rank 6 after chamber 100; after chamber 200 the ranks are 8-9. Spending only on the drill reaches rank 12 after chamber 116. Both policies first buy after chamber 2. This is a spending calculation, not a second physics run with those purchases equipped.

Login gifts are 10, 13, 16, 19, 22, 25 and 28 ore across the seven-day cycle; each completed daily quest grants 18 ore and the unchanged 40 XP. Completion XP is unchanged. Existing saved balances are not rescaled or refunded, so established players may afford more immediately.

## Version 1 to version 2

The existing `user://quarry-v1.json` filename remains in use. Its contents migrate to `version: 2`; changing filenames would strand existing installations. New run snapshots also carry `version: 2`. `Run.valid_snapshot()` rejects unversioned legacy snapshots; `Run.migrate_legacy_snapshot()` is the explicit conversion path.

For an Android update test, retain the existing application package and signing identity and install over the previous build (`adb install -r <updated.apk>`). Do not uninstall or clear application data: either operation removes the save and its immutable migration backup instead of exercising migration. Expansion build artifacts belong in `build/expansion-20261114/android`, preserving the previous exports and their historical QA receipts. Save-copy checks and a successful build do not establish that a new APK has been played on a device.

Legacy chamber `i` maps to `i + floor(i / 10) × 10`: old blocks 0–9, 10–19 and 20–29 become 0–9, 20–29 and 40–49. Stars are copied to those exact indices; inserted chambers receive zero stars. A separate `campaign_frontier` stores the next unlocked chamber. Migration finds the first uncleared chamber in the old contiguous prefix and maps that next chamber. Completing all old 30 sets the frontier to 50. It never infers the frontier from the gaps introduced by mapping. Previously stored stars outside a prefix are retained.

Active campaign, daily and endless runs keep their seed, ore geometry and damage, kinematics, gear, score, shots, continuation flag and run ID. Old chamber geometry is preserved at the mapped indices. New upgrade keys start at zero. `next_run`, `last_paid_run`, `daily_paid`, quest claims, last receipt and achievement flags survive; migrating cannot make an already paid round or earned continuation available again. An unpaid migrated result uses the new payout rules when settled.

Before replacing any valid v1 save, the loader copies its exact original bytes to `quarry-v1.json.migration-v1.bak`. That backup is never rotated or overwritten. A bad existing migration backup blocks replacement with a recovery message. The ordinary `.bak` continues to hold the preceding safe transaction; an invalid primary is preserved as `.corrupt` before replacement.

Transactions write and flush `.tmp`, preserve the prior safe file, then replace the primary. Loading considers valid primary, temporary, ordinary backup and original migration backup candidates by sequence; the primary wins an equal-sequence tie. A newer complete temporary transaction interrupted by process death is promoted once; truncated temporary data is ignored. Promotion of `.tmp` uses a separate `.recovery.tmp`, which is itself recoverable, so a failed write or retry never truncates the only valid recovery source. Reported write, backup-copy or rename failures discard the new transaction's staging file, leaving the selected recovery source intact. Recovery from a legacy backup migrates that actual candidate, never the corrupt primary. The tested storage failures retain the on-disk original and current in-memory balance/ranks. This is application recovery behavior, not a claim of hardware-level power-loss guarantees.

## Reproducing evidence

Run `python tools/run_profile_expansion.py --godot <installed-Godot-4.5.1>` from the repository root. The runner creates fresh process-local user-data directories under ignored `build/`, requires a fresh report and checks the actual engine log. Public fixtures contain synthetic progress and frozen legacy chamber geometry, not personal saves.

After the campaign solver passes, run Godot headlessly with `--script res://tools/economy_report.gd` and an isolated application-data environment. This helper refuses an incomplete or failing campaign receipt and evaluates the actual `Profile` and `Upgrades` functions. Outputs are `build/evidence/profile-expansion.json`, `economy-matched-payouts.json` and `economy-expansion.json`.

Coverage includes all 31 legacy completion frontiers, 120 old chamber/seed combinations, moving/won/daily/endless/failed/continued states, original-backup retention, corrupt-primary recovery, valid/truncated temporary writes, interrupted migration, paid-result and quest replay, unavailable storage, all 72 purchases and distinct maximum effects. The matched payout matrix covers 2,080 combinations, including zero activity, daily bonuses, extreme scores and every salvage rank.

Recorded local validation: **8,732 checks, zero failures**, including blocked promotion of a sole valid temporary save, safe retries, late backup/rename failure, equal-sequence precedence and partially cleared moving ore. An additional **30 checks, zero failures** migrated isolated exact copies of five historical task-emulator v1 saves (earned continuation, pause, interrupted reward, daily claim and purchased upgrade). Their complete converted state and immutable backup hashes matched expectations; the five original files were hash-verified unchanged. These are save-file migration checks, not a new Android gameplay session.
