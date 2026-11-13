# Prism Quarry audio

The four original scores use warm sustained tones, sparse struck-glass/wood motifs,
rounded bass, and quiet stereo reflections. Every note and reflection wraps around
the eight-bar cycle. Each voice has an attack and a tail fade; loops contain no
recorded or third-party music samples.

| Runtime key | Composition | Tempo | Duration | Character |
| --- | --- | --- | --- | --- |
| `menu` | Workshop Lanterns | 60 BPM | 32 s | Welcoming, warm suspended harmony |
| `amber_hollow` | Warm Veins | 80 BPM | 24 s | Brighter major colors, gentle forward motion |
| `azure_grotto` | Blue Reflections | 64 BPM | 30 s | Spacious minor colors, wide quiet echoes |
| `violet_vault` | The Quiet Vault | 72 BPM | 26.667 s | Deeper register, suspended minor harmony |

`manifest.json` is the runtime and provenance source. Music files are 32 kHz,
stereo, signed 16-bit PCM WAV. In Godot, set `AudioStreamWAV.loop_mode = 1`,
`loop_begin = 0`, and `loop_end` to the manifest's frame count. Use separate
Music and SFX buses. Recommended music gain is -9 dB, with the per-effect gains
in the manifest. Fade between environment tracks and do not restart a track on
every menu redraw. Keep the loop muted while application focus is lost.

The 12 Ogg effects are exact, unmodified copies from the supplied Kenney Impact
Sounds, Interface Sounds, and RPG Audio packs. Their full source licenses are
preserved in `licenses/`; each mapping also records its original filename and
SHA256. Use `gem_alt` to vary repeated crystal contact; vary playback pitch gently
(about 0.96–1.06) for hits and cap overlapping impact voices. Chain audio should
trigger at a meaningful combo milestone rather than on every visual fragment.

`tools/prepare_audio.py` reproduces the scores and exact source copies. It needs
NumPy, which was already available in the installed Blender 4.3 Python. No
packages were installed. Running it with Blender's background Python context and
`--validate-only` additionally decodes the Ogg effects through Blender's `aud`
module. `validation.json` contains measured PCM statistics, source container
duration checks, and loop-boundary measurements. The music peaks at -9.9 dBFS,
contains zero clipped samples, and has negligible DC offset. Boundary sample
steps are smaller than the tracks' normal largest adjacent sample steps.

Validation is numerical. Subjective playback review on phone speakers and
headphones is still recommended; no listening session is claimed in this report.

Original composition, synthesis code, and rendered score: Apache-2.0. Kenney
sound effects: CC0-1.0, with exact notices retained.
