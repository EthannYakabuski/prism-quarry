# Art and audio production notes

Production date: 2026-11-13. These assets belong to Prism Quarry only.

## Ten-biome expansion, November 14

The expanded development source keeps the original branding and audio provenance.
Those illustrated assets are not new gameplay evidence. Ten scenery configurations
use the same readable rail inset, with distinct perimeter geometry:

| Biome | Scenery identity |
| --- | --- |
| Amber Hollow | Timber workings, bushes and log stacks |
| Azure Grotto | Mushroom beds and hanging moss |
| Violet Vault | Violet crystal clusters and a rock arch |
| Copper Foundry | Pressure tanks, chimney columns and forged braces |
| Jade Canopy | Plateau trees, hanging moss and fallen timber |
| Frostglass Caverns | Low stepped shelves and faceted ice spires |
| Ember Rift | Split basalt peaks and static emissive fissures |
| Moonstone Archive | Tiered stone shelves, columns and a ruin gateway |
| Obsidian Crown | Tall asymmetric basalt crowns and buttresses |
| Prismatic Depths | Raised geode beds and multicolour crystal ridges |

The added source models are the supplied Kenney City Kit Industrial 2.0
`detail-tank.glb` and `chimney-small.glb`, their required colormap, and Nature Kit
`tree_plateau_dark.glb`. Files are copied unchanged from the supplied local library.
Exact paths, bytes, hashes and texture dependencies are in
[biome-props-provenance.json](../assets/biome-props-provenance.json). Both packs are
CC0; the Industrial pack's original license is preserved in
[LICENSES](../LICENSES/kenney_city-kit-industrial_2.0.txt), alongside the existing
Nature Kit notice. Other props reuse already bundled cave/nature models or simple
project-authored meshes. Model materials are shared per biome; only two unshadowed
local lights are used. Scenery is static, including the fissures; no ambient camera
motion or particle animation was added. All 42 fresh desktop viewport captures
were visually reviewed: ten biomes plus home/map/workshop/results at three sizes.
Their [provenance](../marketing/screenshots/provenance.json) records actual pixels
and source hashes. A few pale background details reduce heading contrast without
hiding text. Existing foreground table/bracket props slightly overlap the lower
board edge but hide no ore, bumper or launcher in the checked frames. These
fixtures do not establish native device performance or physical-device behavior.

## Brand direction and deliverables

The original art direction uses faceted sapphire cave walls, luminous teal crystals,
amber ore and workshop light, and one dark metallic drill puck with an illuminated
cyan diamond core and three amber inserts. Cream angular title lettering remains
legible at feature-graphic size. The illustration communicates the ricochet/mining
fantasy; it is branding artwork and **must not be represented as a gameplay capture**.

| Purpose | File | Dimensions |
| --- | --- | --- |
| Play app icon | `marketing/app-icon-512.png` | 512 × 512 |
| Play feature graphic | `marketing/feature-graphic-1024x500.png` | 1024 × 500 |
| Portrait splash master | `marketing/splash-1080x1920.png` | 1080 × 1920 |
| Runtime app icon | `assets/brand/icon.png` | 512 × 512 |
| Runtime landscape art | `assets/brand/feature.png` | 1024 × 500 |
| Runtime portrait art | `assets/brand/splash.png` | 720 × 1280 |
| 20 achievement import icons | `marketing/achievements/{key}.png` | 512 × 512 |
| 3 leaderboard icons | `marketing/leaderboards/{key}.png` | 512 × 512 |
| 23 matching runtime emblems | `assets/badges/{key}.png` | 256 × 256 |

The five source PNGs and their exact final prompts are in `marketing/branding/`:
`feature`, `icon`, `splash`, `achievements`, and `leaderboards`.
Each has a `*-source.png` and a `*.prompt.txt`. Generation used the built-in
`image_gen` tool through the imagegen skill; no API/CLI fallback was used.
The brand images are original generations; icon and splash use the earlier
generated artwork as style references. Leaderboards use the achievement atlas as
a material/style reference. No third-party image, logo, photo, or existing game's
artwork was incorporated.

The achievement atlas is a single 1402 × 1122 source, divided into five columns
and four rows; its approximately 280-pixel cells are resampled to the required
512-pixel import size. Leaderboards come from a 2172 × 724 three-column source.
Source dimensions and exact crop rectangles are recorded honestly in
`marketing/branding/art-manifest.json`. The splash source is 916 × 1717 and was
center-cropped to 9:16 before the two output sizes. Original generated sources
are retained, so no production resizing is irreversible.

`tools/prepare_art_audio.ps1` reproduces all 52 output PNGs using .NET
System.Drawing, high-quality bicubic scaling, and opaque RGB PNG encoding.
It performs only deterministic production cropping/resizing and review-sheet
assembly; all illustration content came from imagegen. The script also records
SHA256 hashes, dimensions, byte lengths, source files, and crop rectangles.
It requires no package installation.

## Badge mapping and review

The atlas follows the machine-readable catalog's stable keys, in row-major order:

1. `first_fracture`, `cascade`, `chain_reaction`, `clean_sweep`, `steady_hand`
2. `amber_cartographer`, `azure_explorer`, `vault_keeper`, `star_pocket`, `constellation`
3. `master_miner`, `crystal_collector`, `crystal_connoisseur`, `bank_shot`, `spectacular`
4. `deep_diver`, `daily_spark`, `week_of_wonder`, `workshop_whiz`, `seasoned_miner`

Leaderboards are `best_score`, `endless_depth`, and `miner_xp`.
The 23 supplied store icons are all text-free, colorful, opaque, square, and unique
by SHA256. Every store badge is under 1,000,000 bytes. Catalog and import metadata
remain owned by the achievement packaging workflow; these images are the actual
source icons for its archive.

Visually inspected the generated sources, the final 512 × 512 icon, final runtime
portrait splash, final 1024 × 500 feature graphic, and
`marketing/branding/badge-contact-sheet.jpg`, which is assembled from the
final runtime PNGs. Review confirmed the title spelling, complete emblem crops,
consistent gold/sapphire materials, distinct symbols and legible contrast.
The contact sheet's labels are reviewer aids; labels are absent from every
individual badge file. No generated image is offered as runtime-test evidence.
Re-read and matched all 52 final image SHA256 values against the manifest.

## Audio

`assets/audio/manifest.json` supplies the runtime mapping, source provenance,
hashes, frame counts, buses, and recommended gains. `assets/audio/README.md`
provides integration details. Four original eight-bar scores use warm sustained
tones, sparse struck-glass/wood motifs, rounded bass, and restrained stereo echoes:

| Runtime key | Original title | Tempo | Length |
| --- | --- | --- | --- |
| `menu` | Workshop Lanterns | 60 BPM | 32 s |
| `amber_hollow` | Warm Veins | 80 BPM | 24 s |
| `azure_grotto` | Blue Reflections | 64 BPM | 30 s |
| `violet_vault` | The Quiet Vault | 72 BPM | 26.667 s |

Music is 32 kHz, stereo, signed 16-bit PCM WAV. Notes and delay tails wrap around
the composition cycle. The tracks contain no third-party music samples.
Set Godot's `AudioStreamWAV.loop_mode = 1`, `loop_begin = 0` and `loop_end`
to the manifest frame count. Respect the Music/SFX toggles, use separate buses,
fade between environments, and pause/mute on lost focus. Recommended music gain
is -9 dB before any user volume adjustment.

The 12 curated effects come first from the supplied Kenney Impact Sounds,
Interface Sounds, and RPG Audio packs. They are exact unmodified copies:
gem, alternate gem, ricochet, shot, chain, victory, click, error, reward,
upgrade, back, and recall. Exact cue names and paths are in the manifest.
Use per-cue gains and limited polyphony; pitch variation for repeated gem impacts
should be small. Chain audio is intended for combo milestones.

Preserved source licenses:

- `assets/audio/licenses/kenney_impact-sounds.txt`
- `assets/audio/licenses/kenney_interface-sounds.txt`
- `assets/audio/licenses/kenney_rpg-audio.txt`
- `assets/audio/licenses/ORIGINAL_MUSIC.txt`

Kenney sound effects are CC0-1.0. Original composition/synthesis code and rendered
music follow the project's Apache-2.0 license. Original project art and art
production tooling are distributed under the project license.

`tools/prepare_audio.py` reproduces the music and exact source copies with the
already-installed Blender Python/NumPy environment. Nothing was installed.
`assets/audio/validation.json` records numerical checks; all 12 Ogg effects were
decoded using Blender's existing `aud` module. All 16 audio files had zero
full-scale/clipped samples, all source checksums matched, and all four music
tracks had negligible DC. Music peak is -9.9 dBFS; RMS ranges from -22.31 to
-21.01 dBFS. Loop-boundary sample steps are smaller than each track's normal
largest adjacent sample step. The audio package totals approximately 14.55 MB.

Numerical checks and provenance review passed. Subjective listening on headphones
and phone speakers remains unverified; this document makes no listening-session
claim. Runtime integration and device audio behavior are separate game QA tasks.

## Rebuild

From the project root in PowerShell:

```powershell
./tools/prepare_art_audio.ps1
```

See `assets/audio/README.md` and `tools/prepare_audio.py` for the existing Blender
Python command line and optional decoded-audio validation. Regeneration writes
only this project's owned asset/output paths. No other game was modified.

