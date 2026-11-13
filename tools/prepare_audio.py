"""Build Prism Quarry's original score and curate its supplied Kenney sound effects.

Requires NumPy (already bundled with Blender's Python); installs nothing.
Run with Blender's Python, or with Blender --background --factory-startup
--python tools/prepare_audio.py to additionally decode/measure the Ogg sources.
All writes are restricted to this project's assets/audio directory.
"""
from __future__ import annotations
import hashlib
import json
import math
from pathlib import Path
import shutil
import struct
import sys
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "audio"
SOURCE = ROOT.parents[1] / "AllOfKennysAssets"
SR = 32000

# Original eight-bar arrangements. The upper-register motifs leave space for SFX.
SCORES = {
    "menu": dict(title="Workshop Lanterns", bpm=60, root=50,
        chords=[[0,7,14,17],[5,12,16,21],[9,16,19,24],[7,14,17,21]],
        motif=[26,21,19,None,17,19,14,None,21,24,26,21,19,None,17,14],
        pan=.38, pad=.60, bell=.64, pulse=.22, warmth=.65),
    "amber_hollow": dict(title="Warm Veins", bpm=80, root=48,
        chords=[[0,7,14,16],[5,12,16,19],[9,12,19,23],[7,14,17,21]],
        motif=[24,28,31,28,26,None,24,19,21,24,28,26,24,19,None,21],
        pan=.31, pad=.55, bell=.72, pulse=.36, warmth=.88),
    "azure_grotto": dict(title="Blue Reflections", bpm=64, root=50,
        chords=[[0,7,10,17],[5,12,15,22],[3,10,14,19],[7,14,17,22]],
        motif=[24,None,31,29,26,None,22,24,29,26,None,22,19,22,None,17],
        pan=.56, pad=.72, bell=.55, pulse=.12, warmth=.30),
    "violet_vault": dict(title="The Quiet Vault", bpm=72, root=45,
        chords=[[0,7,10,14],[8,15,19,22],[3,10,14,17],[5,12,15,19]],
        motif=[31,26,None,22,24,None,19,22,29,None,26,24,22,19,None,17],
        pan=.48, pad=.70, bell=.50, pulse=.20, warmth=.42),
}

# Destination keys are stable runtime API; source paths preserve exact provenance.
SFX = {
    "gem": ("kenney_impact-sounds", "impactGlass_light_001.ogg", -9.0, "Short brittle crystal fracture"),
    "gem_alt": ("kenney_impact-sounds", "impactGlass_light_003.ogg", -9.0, "Alternate crystal fracture"),
    "ricochet": ("kenney_impact-sounds", "impactMetal_light_002.ogg", -12.0, "Small hard rail contact"),
    "shot": ("kenney_impact-sounds", "impactMining_002.ogg", -8.0, "Drill release with quarry texture"),
    "chain": ("kenney_impact-sounds", "impactGlass_medium_002.ogg", -11.0, "Fuller fracture for a growing chain"),
    "victory": ("kenney_interface-sounds", "confirmation_002.ogg", -6.0, "Positive completed-chamber cue"),
    "click": ("kenney_interface-sounds", "click_001.ogg", -7.0, "Quiet interface press"),
    "error": ("kenney_interface-sounds", "error_008.ogg", -10.0, "Soft unavailable-action cue"),
    "reward": ("kenney_rpg-audio", "handleCoins2.ogg", 0.0, "Physical collected-haul cue"),
    "upgrade": ("kenney_rpg-audio", "metalClick.ogg", -1.0, "Workshop rig fitting locks into place"),
    "back": ("kenney_interface-sounds", "back_001.ogg", -11.0, "Panel return cue"),
    "recall": ("kenney_interface-sounds", "minimize_003.ogg", -10.0, "Puck recall cue"),
}


def frequency(midi: float) -> float:
    return 440 * 2 ** ((midi - 69) / 12)


def metrics(data: np.ndarray) -> dict:
    data = np.asarray(data, dtype=np.float64)
    if data.ndim == 1:
        data = data[:, None]
    peak = float(np.max(np.abs(data)))
    rms = float(np.sqrt(np.mean(data * data)))
    return {"frames": int(len(data)), "channels": int(data.shape[1]),
        "peak": round(peak, 7), "peak_dbfs": round(20 * math.log10(max(peak, 1e-12)), 2),
        "rms_dbfs": round(20 * math.log10(max(rms, 1e-12)), 2),
        "clipped_samples": int(np.count_nonzero(np.abs(data) >= .9999)),
        "dc_offset": round(float(np.mean(data)), 8),
        "boundary_delta": round(float(np.max(np.abs(data[0] - data[-1]))), 8),
        "largest_adjacent_delta": round(float(np.max(np.abs(np.diff(data,axis=0)))), 8)}


def compose(spec: dict) -> np.ndarray:
    beat = 60 / spec["bpm"]
    n = round(32 * beat * SR)
    mix = np.zeros((n, 2), dtype=np.float64)

    def add(midi, start, seconds, amp, pan=0., kind="bell"):
        count = round(seconds * SR)
        t = np.arange(count, dtype=np.float64) / SR
        f = frequency(midi)
        if kind == "pad":
            # Slow breath, rounded spectrum, gentle beating, no sampled source.
            env = np.minimum(t / .55, 1) * np.minimum((seconds - t) / .9, 1)
            env = np.maximum(env, 0) ** 1.6
            signal = (np.sin(2*np.pi*f*t) + .22*np.sin(2*np.pi*f*2*t + .3)
                      + .10*np.sin(2*np.pi*(f*1.0022)*t + .9)) * env
        elif kind == "bass":
            env = (1-np.exp(-t*20)) * np.exp(-t/(seconds*.42))
            signal = (np.sin(2*np.pi*f*t) + .16*np.sin(2*np.pi*f*2*t)) * env
        elif kind == "pulse":
            env = (1-np.exp(-t*100)) * np.exp(-t*12)
            signal = np.sin(2*np.pi*(f*t + 5*(1-np.exp(-t*20)))) * env
        else:
            # Soft struck glass/wood: a rounded fundamental and short inharmonics.
            env = (1-np.exp(-t*240)) * np.exp(-t/(.65 + spec["warmth"]*.32))
            signal = (np.sin(2*np.pi*f*t) * env
                      + .26*np.sin(2*np.pi*f*2.002*t) * env*np.exp(-t*2)
                      + .10*np.sin(2*np.pi*f*3.98*t+.5) * env*np.exp(-t*4))
        signal *= np.clip((seconds-t)/.09, 0, 1)
        # Every event and tail wraps on the musical boundary, yielding a real loop.
        idx = (round(start*SR) + np.arange(count)) % n
        lg = math.sqrt((1-pan)*.5)
        rg = math.sqrt((1+pan)*.5)
        np.add.at(mix[:, 0], idx, signal*amp*lg)
        np.add.at(mix[:, 1], idx, signal*amp*rg)

    for bar in range(8):
        chord = spec["chords"][bar % 4]
        start = bar*4*beat
        for k, interval in enumerate(chord):
            add(spec["root"]+interval, start-.18, 4*beat+.8,
                .105*spec["pad"], (k-1.5)*.25, "pad")
        add(spec["root"]+chord[0]-12, start, beat*3.6, .105, -.08, "bass")
        if bar % 2 == 0:
            add(33, start+beat*2, .55, .040*spec["pulse"], 0., "pulse")
        for step in range(4):
            note = spec["motif"][(bar*2+step) % len(spec["motif"])]
            if note is None or (bar % 2 and step == 3):
                continue
            onset = start+(step*.875+.5)*beat
            pan = spec["pan"] * (-1 if (bar+step)%2 else 1)
            add(spec["root"]+note, onset, 2.8, .090*spec["bell"], pan)
            # Answering octave note on the second phrase only.
            if bar in (3, 7) and step == 1:
                add(spec["root"]+note-12, onset+beat*.5, 2.1, .025, -pan)
    dry = mix.copy()
    # Circular stereo reflections make the room audible without a dead seam.
    for delay, gain in [(beat*.375,.23),(beat*.75,.16),(beat*1.5,.105),(beat*2.25,.065)]:
        mix += np.roll(dry[:, ::-1], round(delay*SR), axis=0)*gain
    mix -= mix.mean(axis=0)
    peak = np.abs(mix).max()
    mix *= .32/max(peak, 1e-9)
    # A few samples interpolate the mathematically periodic edge only if needed.
    # This removes numerical residuals while retaining the musical tail across zero.
    return mix


def write_wav(path: Path, data: np.ndarray):
    pcm = np.clip(np.rint(data*32767), -32768, 32767).astype("<i2")
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(SR)
        wav.writeframes(pcm.tobytes())
    return pcm.astype(np.float64)/32768


def inspect_ogg(path: Path) -> dict:
    raw = path.read_bytes()
    ident = raw.find(b"\x01vorbis")
    assert ident >= 0, f"Missing Vorbis header: {path}"
    channels = raw[ident+11]
    sr = struct.unpack_from("<I", raw, ident+12)[0]
    pos = 0
    granule = 0
    pages = 0
    while pos < len(raw):
        assert raw[pos:pos+4] == b"OggS", f"Invalid Ogg page at {pos}: {path}"
        count = raw[pos+26]
        sizes = raw[pos+27:pos+27+count]
        value = struct.unpack_from("<Q", raw, pos+6)[0]
        if value != 0xffffffffffffffff:
            granule = max(granule, value)
        pos += 27+count+sum(sizes)
        pages += 1
    assert pos == len(raw) and granule > 0
    result = {"sample_rate": sr, "channels": channels, "duration_seconds": round(granule/sr, 5),
              "ogg_pages": pages, "decoded_pcm_metrics": "not_available_in_standalone_python"}
    try:
        import aud
        data = aud.Sound(str(path)).data()
        result["decoded_pcm_metrics"] = metrics(data)
    except ImportError:
        pass
    return result


def main():
    for folder in [OUT, OUT/"music", OUT/"sfx", OUT/"licenses"]:
        folder.mkdir(parents=True, exist_ok=True)
    if "--audit-candidates" in sys.argv:
        for pack, pattern in [("kenney_interface-sounds","error_*.ogg"),
                              ("kenney_interface-sounds","click_*.ogg"),
                              ("kenney_rpg-audio","metal*.ogg")]:
            for path in sorted((SOURCE/pack/"Audio").glob(pattern)):
                print(path.name, json.dumps(inspect_ogg(path)), flush=True)
        return
    if "--validate-only" in sys.argv:
        validation = json.loads((OUT/"validation.json").read_text(encoding="utf-8"))
        for key in SFX:
            validation["sfx"][key] = inspect_ogg(OUT/"sfx"/(key+".ogg"))
            print("Decoded:", key, validation["sfx"][key], flush=True)
        (OUT/"validation.json").write_text(json.dumps(validation,indent=2)+"\n", encoding="utf-8")
        return
    validation = {"sample_rate": SR, "music": {}, "sfx": {},
        "method": "Numerical PCM validation; original Ogg container checks and optional Blender aud decode. No subjective listening claim."}
    manifest = {"schema_version": 1, "music_bus": "Music", "sfx_bus": "SFX",
        "recommended_music_volume_db": -9.0, "music": {}, "sfx": {},
        "notes": "Music is original, seamless stereo PCM. Set AudioStreamWAV.loop_mode=1, loop_begin=0, loop_end=frames. Do not restart current track on every UI redraw. Per-cue gain assumes SFX bus 0dB; cap repeated impacts and pitch-vary gems gently."}
    if "--sfx-only" in sys.argv:
        validation = json.loads((OUT/"validation.json").read_text(encoding="utf-8"))
        manifest = json.loads((OUT/"manifest.json").read_text(encoding="utf-8"))
    for key, spec in ({} if "--sfx-only" in sys.argv else SCORES).items():
        path = OUT/"music"/(key+".wav")
        pcm = write_wav(path, compose(spec))
        stat = metrics(pcm)
        stat["duration_seconds"] = round(len(pcm)/SR, 5)
        stat["seam_delta_dbfs"] = round(20*math.log10(max(stat["boundary_delta"], 1e-12)), 2)
        assert stat["clipped_samples"] == 0
        assert stat["peak"] < .33 and stat["rms_dbfs"] > -35
        assert stat["boundary_delta"] < .025, (key,stat)
        validation["music"][key] = stat
        manifest["music"][key] = {"path": f"res://assets/audio/music/{key}.wav", "title": spec["title"],
            "bpm": spec["bpm"], "bars": 8, "frames": len(pcm), "sample_rate": SR,
            "loop": True, "gain_db": -9.0, "license": "Apache-2.0", "source": "Original procedural composition in tools/prepare_audio.py"}
        print("Music complete:", key, stat, flush=True)
    packs = set()
    for key, (pack, filename, gain, description) in SFX.items():
        src = SOURCE/pack/"Audio"/filename
        dst = OUT/"sfx"/(key+".ogg")
        assert src.is_file(), src
        shutil.copyfile(src, dst)
        source_hash = hashlib.sha256(src.read_bytes()).hexdigest()
        assert hashlib.sha256(dst.read_bytes()).hexdigest() == source_hash
        stat = inspect_ogg(dst)
        decoded = stat["decoded_pcm_metrics"]
        if isinstance(decoded, dict):
            assert decoded["clipped_samples"] == 0, (key, decoded)
            stat["peak_at_recommended_gain_dbfs"] = round(decoded["peak_dbfs"]+gain, 2)
        validation["sfx"][key] = stat
        manifest["sfx"][key] = {"path": f"res://assets/audio/sfx/{key}.ogg", "gain_db": gain,
            "description": description, "license": "CC0-1.0", "source_pack": pack,
            "source_file": "Audio/"+filename, "sha256": source_hash, "modifications": "None; exact source bytes"}
        packs.add(pack)
    for pack in sorted(packs):
        shutil.copyfile(SOURCE/pack/"License.txt", OUT/"licenses"/(pack+".txt"))
    (OUT/"licenses"/"ORIGINAL_MUSIC.txt").write_text(
        "Prism Quarry original score\nCopyright 2026 Ethann Yakabuski\n\n"
        "Workshop Lanterns, Warm Veins, Blue Reflections, and The Quiet Vault\n"
        "are original procedural compositions and synthesized performances created for\n"
        "Prism Quarry. They use no recorded samples, melodies, or third-party music.\n"
        "The note arrangements, synthesis code, and rendered music are licensed under\n"
        "the Apache License, Version 2.0; see the repository LICENSE.\n\n"
        "Kenney sound effects are separate CC0 assets; their source licenses are preserved\n"
        "in this folder and the exact source filenames and SHA256 hashes are in manifest.json.\n",
        encoding="utf-8")
    (OUT/"manifest.json").write_text(json.dumps(manifest,indent=2)+"\n", encoding="utf-8")
    (OUT/"validation.json").write_text(json.dumps(validation,indent=2)+"\n", encoding="utf-8")
    print("Wrote", OUT/"manifest.json", flush=True)


if __name__ == "__main__":
    main()
