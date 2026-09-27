# Stage music

All battle music is original synthesized audio with lead, bass, harmony and percussion. Each stage arrangement lasts about 61–73 seconds, so a normal 60-second round finishes before its full loop repeats. The form moves through A, B, A-return and a transformed closing section instead of cycling a short four-bar backing. Every stage has its own B-theme, alternate harmony, arpeggio motion and instrumental identity.

Each stage also has synchronized `intro`, `battle`, and `climax` arrangements. The intro begins with a deliberately lighter texture. The climax adds counter-lines, B-section octave support, denser kick patterns, section fills and chord stabs rather than relying on a simple gain increase. All three phase files retain identical sample counts at the same tempo, so `Sound.set_music_phase()` can crossfade at the matching musical position over 0.75 seconds. The closing mix is measurably more present than battle while retaining headroom for warnings and impacts. Big hits, specials and boss tells briefly duck the score, then release it smoothly.

| Context | Musical character | Tempo |
| --- | --- | ---: |
| Desktop / Blue | Playful toy-keyboard lead and light groove | 112 BPM |
| Quarry / Red | Adventurous reed lead and driving bass/drums | 138 BPM |
| Journey Green | Nimble bell melody and arpeggios | 126 BPM |
| Pac-Man | Fast pixel chase theme | 158 BPM |
| H4CK3R / Glitch Core quick match | Tense digital pulse and pixel melody | 142 BPM |
| Dark lord | Dramatic brass-like lead and heavier bass | 132 BPM |

Title and Doodle Rally keep the original toy-keyboard loop. Switching between these two contexts preserves its playback position. Story chapters use the corresponding arena's lighter intro arrangement, while the journal uses its softer paper-desk bed. Chapter music then gives way to the same arena's battle arrangement when the match begins.

The WAV files and deterministic composition/rendering source are in `game/assets/music/`. They are 22,050 Hz, mono, 16-bit PCM, with import compression disabled to preserve exact sample alignment. To regenerate them, use Python with NumPy and run `generate_stage_music.py`; this is optional authoring tooling. The game itself needs only Godot. Combat effects are synthesized in `game/scripts/audio.gd`: original fighters and custom weapon kits have signature special cues, bosses have pattern-specific launch sounds, and impacts combine weapon body, hit weight and paper/metal/magic accents. Pac-Man, H4CK3R and Dark lord also have distinct short basic-attack cues. Guard, warning, menu, victory and story-page Foley have their own motifs. Music ducking is cosmetic and does not alter combat timing.

Automated audio tests measure file format, duration, peak headroom, signal activity, phase loudness, unique stage data, cue coverage and crossfade routing. These checks do not replace a listening session on speakers or headphones; external audio devices and a family comfort/fun pass remain unverified for this local update.
