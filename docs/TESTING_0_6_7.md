# Validation archive — Doodle Rumble v0.6.7

Updated 2026-09-17. Standard Godot 4.7.2, Compatibility renderer, Apple M1/macOS 26.6.2. This release replaces the intro poster texture used by `main.gd` and verifies the title screen at the game's native 1280×720 layout.

## Source suites

The complete source run used `game/tools/run_tests.py` with `--isolated-qa --silent-qa`, serial execution, a separate per-process preferences directory, and no user game process. Every suite exited cleanly:

| Suite | Passed | Failed |
| --- | ---: | ---: |
| `test_arena_variety.gd` | 64 | 0 |
| `test_boot_audio.gd` | 18 | 0 |
| `test_boss_strength.gd` | 35 | 0 |
| `test_boss_update.gd` | 99 | 0 |
| `test_combat_depth.gd` | 343 | 0 |
| `test_controls_depth.gd` | 41 | 0 |
| `test_core.gd` | 112 | 0 |
| `test_difficulty.gd` | 87 | 0 |
| `test_difficulty_live.gd` | 28 | 0 |
| `test_ending.gd` | 45 | 0 |
| `test_game.gd` | 138 | 0 |
| `test_menus.gd` | 164 | 0 |
| `test_music.gd` | 99 | 0 |
| `test_new_fighters.gd` | 164 | 0 |
| `test_pacman.gd` | 29 | 0 |
| `test_pacman_pressure.gd` | 26 | 0 |
| `test_premium_audio.gd` | 135 | 0 |
| `test_premium_story.gd` | 68 | 0 |
| `test_racing.gd` | 48 | 0 |
| `test_rally_library.gd` | 21 | 0 |
| `test_rally_sim.gd` | 72 | 0 |
| `test_story_worlds.gd` | 71 | 0 |
| **Total** | **1,907** | **0** |

The game integration suite reports 18 live rounds with zero retries. Racing remains a dedicated subsystem and its existing integration/library/simulation checks still pass.

The same 22 suites were rerun against the exported `Doodle Rumble.pck` with `work/run_packaged_tests.py`; they also report **1,907 checks, 0 failures**. Per-suite logs and the JSON result are in `docs/test-results/v067/packaged-logs/`.

## Poster and native render evidence

- `docs/test-results/v067/title/poster_clean.png` is an asset-level 1280×720 capture of `assets/intro_poster_v060.png`.
- `docs/test-results/v067/title/title_clean.png` is the full title menu rendered through `scenes/main.tscn` at 1280×720.
- `docs/test-results/v067/title/packaged/poster_clean.png` loads the poster directly from the exported Mac PCK and shows the same clean corner.
- The lower-right `STICKS FIGHT FOREVER / INSERT COIN` block is absent from both captures. The title, Dark Lord, H4CK3R, six fighter illustrations, lighting and rubble remain visible.
- Capture scripts run with the native renderer (not dummy `--headless` rendering), isolated QA preferences and `--silent-qa`; no gameplay process is controlled.

## Export checks

The v0.6.7 Universal Mac app at `builds/mac-v0.6.7/Doodle Rumble.app` is exported with matching Godot 4.7.2 templates, includes arm64 and x86_64 executables, and passes `codesign --verify --deep --strict`. A headless launch/exit smoke test passes against both the local app and an extracted copy with isolated native profiles. ZIP archives pass `unzip -t` and the extracted source contains the cleaned poster asset.

The app is ad-hoc signed and not Apple-notarized. Physical controllers, Intel execution, transferred first launch, keyboard rollover, display scaling, audio hardware and family playtesting remain device checks.
