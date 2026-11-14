# Prism Quarry expansion supplement

Authorized development scope, 2026-11-14. This supplements the preserved [initial vector](INITIAL_VECTOR_PROMPT.txt); it does not rewrite the original 30-chamber brief or earlier evidence.

Expand the campaign to 200 chambers across ten biomes, twenty chambers each. Preserve the original thirty layouts and add 170 varied layouts. The exact biome order is:

| Index | Biome | Displayed chambers |
|---|---|---|
| 0 | Amber Hollow | 001–020 |
| 1 | Azure Grotto | 021–040 |
| 2 | Violet Vault | 041–060 |
| 3 | Copper Foundry | 061–080 |
| 4 | Jade Canopy | 081–100 |
| 5 | Frostglass Caverns | 101–120 |
| 6 | Ember Rift | 121–140 |
| 7 | Moonstone Archive | 141–160 |
| 8 | Obsidian Crown | 161–180 |
| 9 | Prismatic Depths | 181–200 |

Legacy zero-based indices 0–9 remain 0–9; 10–19 map to 20–29; 20–29 map to 40–49. Migrate saved stars, progression and active rounds without losing earned state or paying an old result twice. Preserve stable achievement keys, thresholds and backend mappings; revise descriptions that incorrectly call thirty chambers or ninety stars the whole campaign.

Give the biomes distinct scenery, silhouettes and prop arrangements, using the supplied licensed Kenney assets first. Keep ore, predicted trajectory and bumper shapes readable; scenery must not imply new collision rules. Reuse shared materials and low-complexity meshes, avoid extra continuous animation, and preserve reduced-motion behavior.

Provide six workshop choices, each with twelve ranks: Longburn drill, Echo lens, Salvage rig, Focus tip, Prism resonator and Combo calibrator. Retain the original drill, echo and salvage progression while adding distinct flight, chain reach, salvage, contact margin, white-prism reach and scoring effects. Show current and next effects clearly, preserve purchased ranks, and bound every upgrade through shared definitions.

Reduce round ore substantially to support the longer campaign while preserving existing balances and XP. The intended baseline is one fifth of the previous matched round payout, including its eligible daily completion bonus; any later-rank salvage adjustment must remain explicit and verified. Existing login and claim rules must continue to pay once. Every chamber should remain completable with base equipment and without a rewarded continuation.

Let the completed chamber remain visible briefly before presenting the result. Use a short result-popup transition, with a stationary reduced-motion alternative; never animate away the player's chance to read the final shot. Test interruption, reload and repeated input around both phases.

## Evidence boundary

This file records requirements, not acceptance. The public Web build, dated receipts and retained screenshots from the earlier edition do not certify the expansion. Keep those artifacts intact and archive replaced captures before generating new ones.

After runtime freeze, capture genuine phone, 7-inch and 10-inch desktop viewport profiles covering all ten biomes, home, the paged campaign map, workshop and a fully visible result: fourteen images per profile, forty-two total. Keep fixture selection, desktop rendering, native emulator evidence and ordinary human input distinct. Fresh capture manifests must identify the actual source files and image hashes; no gameplay illustration or edited composite may stand in for runtime pixels.

Acceptance must separately establish 200-chamber baseline solutions and varied layouts, save migration, workshop effects/caps, the intended ore reduction, clear/result timing, readable UI and all ten biome presentations. Build/export checks, actual browser or native play, exact-revision CI and deployment each require their own evidence. No new live build, CI pass, native test, store publication or Console import is claimed by this supplement.
