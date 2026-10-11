# Crackle and Dark lord verification — v0.7.10

Verified October 10, 2026 using Godot 4.7.2 on Apple M1. Published as the [v0.7.10 GitHub release](https://github.com/manynames3/doodle-rumble/releases/tag/v0.7.10) with matching source commit `feee642`. Automated runs used `--isolated-qa` profiles.

## Source checks

| Suite | Checks | Failures |
| --- | ---: | ---: |
| `test_premium_story` | 150 | 0 |
| `test_story_worlds` | 73 | 0 |
| `test_menus` | 168 | 0 |
| `test_new_fighters` | 165 | 0 |
| `test_music` | 118 | 0 |
| `test_premium_audio` | 192 | 0 |
| `test_boss_strength` | 47 | 0 |
| `test_boss_update` | 101 | 0 |
| `test_ending` | 45 | 0 |
| `test_game` | 157 | 0 |
| `test_custom_integration` | 56 | 0 |
| `test_character_art_packs` | 436 | 0 |
| `test_result_geometry` | 22 | 0 |
| `test_combat_depth` | 343 | 0 |
| `test_core` | 112 | 0 |
| `test_crackle_boss` | 50 | 0 |
| `test_dark_lord_pressure` | 18 | 0 |
| `test_difficulty` | 92 | 0 |
| `test_fuse_boss` | 34 | 0 |
| **Total** | **2,379** | **0** |

The live-bot journey with authored character art cleared all eight fights with no retries in 13,713 frames. The roster is Blue, Red, Green, Crackle, Pac-Man, H4CK3R, Fuse, Dark lord. Over 15 seconds against a passive target, pressure was Green 92, Crackle 101, Pac-Man 146 damage. These checks support the intended placement before Pac-Man, but do not replace human playtesting.

Crackle coverage includes the single rocket, firecracker arc with eight pop sparks, three-lane firework fan, spear thrust, fixed warning aim/facing, visible release and vulnerable recovery, authored muzzle, reflection and score ownership, impact effects, and reduced motion. Version-one and version-two save fixtures preserve existing checkpoints, completions and bonus stickers without falsely awarding Crackle completion. Separate process save/reload checks passed. The journal displays eight chapters.

Dark lord's attack multiplier increased from 1.50 to 1.95: exactly 30% before per-hit integer rounding. Pursuit speed also increased 30%; hit stun decreased from 0.18 to 0.12 seconds and controller recovery after a hit decreased from 0.28 to 0.10 seconds. Existing damage tells, cast recovery and hit invulnerability remain intact. Ranged orb selection and a warned full-height pillar counter distant and elevated shooters. The deterministic 40-second passive pressure check increased from 593 to 774 damage (30.5% after rounding). In a 12-second actual held-bow scenario, 19 arrows fired; Dark lord closed from 1,080 to 438.3 pixels, released six spells and dealt 203 damage. The regression exercises the real bow cooldown.

## Assets and native rendering

- Generated seven atlases using the built-in image tool, guided by the supplied drawing and existing game art. Exact prompts and extraction geometry are preserved in `source_art/Crackle_Production_Assets/generation.json` and `extraction.json`. The private original drawing remains outside the repository.
- Integrated 13 authored poses, six effects and three separate projectiles. The runtime manifest maps 16 pose states through these authored poses. An independent rebuild reproduced all 23 Crackle runtime PNG/JSON outputs byte-for-byte. The nine supplied character packs were not regenerated.
- The importer passed Python compilation and Godot imported the new assets. `git diff --check` passed.
- Captured and inspected 26 named native 1280×720 views of combat patterns, rocket impact, firecracker pop, spear strike, victory/defeat, reduced motion, the eight-card journal and before/after/final dialogue. Fallen feet stay on the floor; warnings clear the helmet; story text and journal cards fit the viewport. The final capture run completed cleanly; one earlier run reported an intermittent Godot exit resource warning.
- The curated gameplay capture is [15-crackle-pack.png](screenshots/15-crackle-pack.png). Other local QA captures are under `docs/test-results/crackle/` and are ignored by Git. Reproduce them with `game/tests/capture_crackle.gd` using the native renderer.

## Mac package

The app and app-only ZIP are under `builds/mac-v0.7.10/`. Info.plist reports v0.7.10 / build 28. The executable contains arm64 and x86_64 slices. Strict ad-hoc signature verification, ZIP integrity and a 120-frame headless startup of the actual exported executable passed.

The [published playable ZIP](https://github.com/manynames3/doodle-rumble/releases/download/v0.7.10/Doodle_Rumble_Mac_v0.7.10.zip) is 261,111,576 bytes. GitHub reports the same SHA-256 as the verified local ZIP: `f0a85d11ce2bb2a21140057b00231b8fc2ffd7d000cf7c867f0c0c59916eca6c`.

The exact exported PCK passed `test_character_art_packs` (436 checks), `test_premium_story` (150 checks), `test_crackle_boss` (50 checks) and `test_dark_lord_pressure` (18 checks): **654 checks / zero failures**, run through Godot's editor executable with `--main-pack`. The release export template does not support standalone `--script` execution. Packaged 15-second pressure was Green 82, Crackle 101, Pac-Man 146; Green varied from the source sample, while the intended ordering remained intact. Packaged held-bow pursuit matched the source result: 19 arrows, six spells, 203 damage and 438.3 pixels closest distance.

The app is not notarized. Intel execution, transfer to another Mac, physical gamepads and family playtesting of the new fights were not verified. Source native captures and automated tests do not establish those results.
