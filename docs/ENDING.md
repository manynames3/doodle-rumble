# The Save Star comes home

The 30-second ending is an original, captioned 2D movie. It plays after the final boss's after-stage comic, then returns to the final results. Watch the ending replays it; replaying never grants another reward. Escape or the Skip button exits. Reduced motion uses six still pages and a Next button instead of the movie.

The Save Star tumbles out of Dark lord's crown, travels through the six friends, and returns to a shared page on the desk. Pac-Man and H4CK3R join the celebration. Dark lord earns his requested starring role as Assistant Manager of Purple, cape included. The final page leaves the next adventure for the player to draw.

## Editable source

- `game/scripts/ending_storyboard.gd`: deterministic actors and worlds.
- `game/scripts/ending_captions.gd`: foreground titles and captions.
- `game/scripts/ending_player.gd`: playback, still-page alternative, volume and skip.
- `game/tools/render_ending.gd`: 24 fps offline capture.
- `game/tools/capture_ending_review.gd`: six native-rendered review stills from the same storyboard.
- `game/assets/cinematics/generate_ending_music.py`: original synthesized closing score (NumPy only for regeneration).

To regenerate, render `render_ending.gd` with Godot Movie Maker at 24 fps, then encode exactly 720 frames with FFmpeg's libtheora encoder using `-q:v 5 -g 48 -pix_fmt yuv420p`. The short keyframe interval is intentional: an earlier higher-bitrate encode decoded correctly in FFmpeg but displayed incorrect late frames in native Godot playback. Map the included `ending_music.wav` as the only audio stream using libvorbis at 22,050 Hz stereo. The shipped `ending.ogv` is 1280×720, 24 fps, and 30.00 seconds; regeneration tools are not needed by players. Godot's documentation covers [movie recording](https://docs.godotengine.org/en/stable/tutorials/animation/creating_movies.html) and [VideoStreamPlayer](https://docs.godotengine.org/en/stable/classes/class_videostreamplayer.html).

The final encode passed a full native Godot playback check with six visually inspected timestamps, including the desk return and studio closing card. Regenerated movies should be checked this way as well as decoded with FFmpeg. The movie temporarily owns the music channel, and its modal controls contain keyboard focus until returning to results.
