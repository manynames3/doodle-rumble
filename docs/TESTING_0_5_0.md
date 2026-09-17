# Verification — v0.5.0

September 13, 2026. Standard Godot 4.7.2, Apple M1, Compatibility renderer.

## Source tests

1347 checks passed across 18 suites. Latest suite logs contain no errors or warnings.

| Suite | Checks |
| --- | ---: |
| test_arena_variety | 64 |
| test_boot_audio | 18 |
| test_boss_strength | 28 |
| test_boss_update | 74 |
| test_combat_depth | 205 |
| test_controls_depth | 41 |
| test_core | 112 |
| test_ending | 27 |
| test_game | 133 |
| test_menus | 134 |
| test_music | 82 |
| test_new_fighters | 162 |
| test_pacman | 29 |
| test_pacman_pressure | 26 |
| test_racing | 48 |
| test_rally_library | 21 |
| test_rally_sim | 72 |
| test_story_worlds | 71 |

The input-driven journey completed all six stages with optional hazards ON and no retries; Orange fought through H4CK3R and Purple fought Dark lord. Three two-player input-bot matches completed as well, totaling 18 combat rounds. Those live paths used real combat rather than forced health changes. Separate score/reward tests intentionally use fixtures to isolate transitions.

Rally completed six two-lap races covering solo, local, cup and custom-course flows. Persistence, corrupt-save handling, car traits, drift/turbo/hops, stamp collection, pause and settings have focused checks.

The audio teardown suite runs on wall-clock timing so the audio mixer can release playback resources. Physics suites use fixed sampling; tests for damage and hazards cover multiple step sizes. All tests use isolated preferences.

## Visual/runtime review

Godot captures were inspected for all three new fighting arenas, active hazards and warning readability, six-arena selection, Rally garage/courses/local play/editor/results, the BenJam introduction and the ending. Corrections included menu text contrast, layering over result panels, warning overlap, cinematic floor alignment and final-result focus order.

The encoded 30-second Ogg movie was played in Godot from start to finish. Skip, replay, still-page reduced-motion mode, music ownership and single-reward behavior passed 27 ending checks.

## Mac export

The v0.5.0 app is Universal arm64/x86_64 and passes strict local signature verification. A headless native startup/exit smoke check passed with isolated preferences. The release executable does not provide the editor's script-test runner; exported-resource tests use standard Godot with the actual exported game pack. Core, Rally, ending and story-world suites passed against that pack: 258 checks.

The exported GUI has not been manually played. Physical controllers, Intel execution, macOS first launch after transfer, keyboard rollover, sleep/wake, long-session performance and family difficulty/fun remain unverified. The build is ad-hoc signed, not notarized.
