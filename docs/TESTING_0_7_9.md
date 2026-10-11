# Fuse expansion verification — local v0.7.9

Verified October 10, 2026 using Godot 4.7.2 on Apple M1. This is a local build, not a published GitHub release. Automated runs used `--isolated-qa` profiles.

## Source checks

| Suite | Checks | Failures |
| --- | ---: | ---: |
| `test_premium_story` | 79 | 0 |
| `test_story_worlds` | 72 | 0 |
| `test_menus` | 166 | 0 |
| `test_new_fighters` | 164 | 0 |
| `test_music` | 116 | 0 |
| `test_premium_audio` | 191 | 0 |
| `test_boss_strength` | 46 | 0 |
| `test_boss_update` | 101 | 0 |
| `test_ending` | 45 | 0 |
| `test_game` | 148 | 0 |
| `test_custom_integration` | 53 | 0 |
| `test_character_art_packs` | 386 | 0 |
| `test_result_geometry` | 20 | 0 |
| `test_combat_depth` | 343 | 0 |
| `test_core` | 112 | 0 |
| `test_fuse_boss` | 34 | 0 |
| **Total** | **2,076** | **0** |

The live-bot journey cleared all seven fights with no retries. The focused Fuse suite exercised each missile pattern, fixed warning duration across all difficulties, committed facing/aim, elevated targets, reflection, real firing-muzzle placement, authored warning/fire/reload poses and bash guard timing. Over 25 seconds against a passive target, pressure was H4CK3R 224, Fuse 236, Dark lord 376 damage. This supports the intended ordering, but does not replace human playtesting.

Version-one save fixtures preserved the former finale checkpoint, completion and bonus sticker at the new Dark lord index. Fuse receives no false completion record. Journal totals and menus use seven chapters.

## Assets and native rendering

- An independent rebuild in a temporary directory reproduced all 21 Fuse runtime PNG/JSON files byte-for-byte. The importer and its integration passed Python compilation; `git diff --check` passed.
- Inspected the 13-pose contact sheet, transparent atlas extraction, hollow-head proportions, loaded aim, empty firing muzzle and vulnerable reload pose.
- Captured 19 native 1280×720 views from the actual Godot scene: idle, three missile patterns across tell/release/reload, collision impact, victory, defeat, reduced-motion victory, seven-card journal and before/after dialogue. The warning sits above the head, fallen feet remain on the floor, and text/cards fit the viewport.
- The curated gameplay capture is [14-fuse-pack.png](screenshots/14-fuse-pack.png). Other local QA captures are under `docs/test-results/fuse/` and are ignored by Git. Reproduce them using `game/tests/capture_fuse.gd` with the native renderer.

## Local Mac package

The app and app-only ZIP are under `builds/mac-v0.7.9/`. Info.plist reports v0.7.9 / build 27. The executable contains arm64 and x86_64 slices. Strict ad-hoc signature verification, ZIP integrity and a 120-frame headless startup of the actual exported executable passed.

The exact exported PCK passed `test_character_art_packs` (386 checks), `test_premium_story` (79 checks) and `test_fuse_boss` (34 checks): **499 checks / zero failures**, run through Godot's editor executable with `--main-pack`. The release export template does not support standalone `--script` execution. Exported Fuse pressure matched the source result exactly.

The app is not notarized. Intel execution, transfer to another Mac, physical gamepads and family playtesting of the new fight were not verified. Source native captures and automated tests do not establish those results.
