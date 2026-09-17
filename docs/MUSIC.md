# Stage music

All battle music is original synthesized audio with lead, bass, harmony and percussion. Each arrangement has eight bars with variation and a seamless loop. Each stage now has synchronized `intro`, `battle`, and `climax` arrangements: the intro leaves space for the opening, and the climax adds a melodic answer and percussion fill. `Sound.set_music_phase()` crossfades at the same sample position over 0.75 seconds. Master/music settings and pause ducking apply throughout.

| Context | Musical character | Tempo |
| --- | --- | ---: |
| Desktop / Blue | Playful toy-keyboard lead and light groove | 112 BPM |
| Quarry / Red | Adventurous reed lead and driving bass/drums | 138 BPM |
| Journey Green | Nimble bell melody and arpeggios | 126 BPM |
| Pac-Man | Fast pixel chase theme | 158 BPM |
| H4CK3R / Glitch Core quick match | Tense digital pulse and pixel melody | 142 BPM |
| Dark lord | Dramatic brass-like lead and heavier bass | 132 BPM |

Title and Doodle Rally keep the original toy-keyboard loop. Switching between these two contexts preserves its playback position.

The WAV files and deterministic composition/rendering source are in `game/assets/music/`. They are 22,050 Hz, mono, 16-bit PCM, with import compression disabled to preserve exact sample alignment. To regenerate them, use Python with NumPy and run `generate_stage_music.py`; this is optional authoring tooling. The game itself needs only Godot. Combat effects are synthesized in `game/scripts/audio.gd` from a weapon body, impact weight, and paper/metal/magic accent. Guard and threat-warning cues have separate short motifs, with warning repetition limited in time.
