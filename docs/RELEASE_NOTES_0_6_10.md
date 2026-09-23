# Doodle Rumble v0.6.10

Pac-Man's bite art had picked up a second eye in the runtime poses. This update gives him one clear eye from every angle and through every mapped action, while keeping the original supplied pack intact. The corrected transparent PNGs are kept as a separate runtime override set, and the importer and regression suite now know about them.

Dark lord now feels like the last fight in the story. His attack rotation expands from five patterns to eight: in addition to his reaper, quake, void-orb, rift and camera attacks, he can send a five-shard eclipse volley, a floor-wide wave you can jump and a vertical void pillar you must dodge sideways. Heavy attacks keep their warning phase before release. The boss also advances and follows players who stay on raised platforms.

The 40-second fixed-step attack-pressure probe now records Dark lord at 593 damage, H4CK3R at 357 and Pac-Man at 146. Dark lord's incoming damage multiplier is 1.5×. These are automated balance signals, not a replacement for playtesting with kids.

The exported app is a Universal Apple Silicon/Intel build made with Godot 4.7.2. It is locally ad-hoc signed, not notarized; see [BUILD_STATUS.md](../BUILD_STATUS.md) for Mac distribution limits and [TESTING_0_6_10.md](TESTING_0_6_10.md) for verification.
