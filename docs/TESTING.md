# Validation archive — v0.4.0

The current release evidence is [TESTING_0_6_7.md](TESTING_0_6_7.md), including the cleaned title-poster capture, latest arena-ambience captures and the 1,907-check source/PCK runs. This file is retained as the original v0.4.0 validation record for historical comparison.

Updated 2026-09-13. Godot 4.7.2 standard, Apple M1 / macOS 26.6.2, Compatibility renderer.

## Final source results

| Suite in `game/tests/` | Passed | Failed |
| --- | ---: | ---: |
| `test_core.gd` | 112 | 0 |
| `test_game.gd` | 133 | 0 |
| `test_menus.gd` | 134 | 0 |
| `test_racing.gd` | 112 | 0 |
| `test_pacman.gd` | 29 | 0 |
| `test_new_fighters.gd` | 162 | 0 |
| `test_music.gd` | 82 | 0 |
| `test_boss_update.gd` | 74 | 0 |
| `test_pacman_pressure.gd` | 26 | 0 |
| `test_boss_strength.gd` | 28 | 0 |
| `test_combat_depth.gd` | 205 | 0 |
| `test_arena_variety.gd` | 64 | 0 |
| `test_controls_depth.gd` | 41 | 0 |
| **Total** | **1,202** | **0** |

All final source logs are clean of errors and warnings. Suites run serially against a copy with a separate `DoodleRumbleAutomatedQA` preferences directory. Preferences are restored by tests, but isolation also protects against an interrupted test. The user's existing game process was not stopped or controlled.

## Gameplay evidence

The full-scene suite exercises real mapped input, movement/collision, attacks, projectiles, AI, health, pause, rounds and rematches. Three complete local matches cover Orange/Blue, Purple/Yellow and Yellow/Purple. Six story matches use Orange for Blue, Red, Green, Pac-Man and H4CK3R, then Purple against Dark lord. This is 18 combat rounds, with no retries in the final run. The story took 8,014 simulated frames. Countdown screens were skipped by the harness; the fights use full health, normal timers and actual attack damage. No shortened fight timers, forced KOs or AI changes are used in these live matches. Separate scoring-path fixtures deliberately set health to isolate KO/timeout/draw/reward branches.

The test player spaces attacks, reads visible boss tells, jumps, avoids marked hazards and now dodges Pac-Man's committed charge. This is evidence the loop is playable with these strategies, not proof every fighter is equally balanced or that children will understand the tactics. Early-stage pressure produced 6/7/8 attack decisions and first attacks at frames 162/133/112 in identical fixtures.

Combat-depth tests verify finite dodge startup/invulnerability/recovery/cooldown, no attack- or stun-cancel, no boss dodge, one perfect-evade reward, counter expiry and interruption, 25% basic-only damage, different airborne hit regions and launch directions, and 30/60/120-step consistency. Integration tests verify old remapped E/J keys survive migration, independent new Dodge keys/controller inputs, settings focus, correct per-player prompts, pause-frozen counter timing, a 15-damage Purple counter arrow followed by a normal 12-damage arrow, and unchanged Signal shot damage.

Arena checks cover distinct collision layouts, reachable ledges, explicit spring jump, cracking/reforming bridge collision, safe portal exits, no held-input teleport loops, no teleport during hurt/attack/dodge, reset state and the giant boss's retreat ledges. Arena interactions never deal damage. Extra hazards default ON, have visible tells, do not stack into simultaneous damaging fields and respect reduced-motion presentation. Boss guards take full damage and expire before punishable recovery.

Menu tests cover the six title entries, six fighter cards, selection for both players, modes, rematches, settings focus, remapping and persistence. Music tests inspect distinct PCM loops, sample bounds, loops, context changes, crossfades, pause/volume and shutdown. Audio preference, mixing quality and fatigue require listening tests.

## Exported resources and Mac app

The Universal app was exported with matching 4.7.2 standard templates. It includes arm64 and x86_64 executables and passes `codesign --verify --deep --strict`. The latest version is `builds/mac-v0.4.0/Doodle Rumble.app`, version 0.4.0, build 5. It is locally ad-hoc signed and not notarized.

Ten suites also ran against the exported `.pck`, loaded by the matching editor runtime using a separate `DoodleRumblePackedQA` directory: game 133, menus 134, new fighters 162, music 82, boss update 74, Pac-Man pressure 26, boss strength 28, combat depth 205, arena variety 64 and controls depth 41: **949 checks, zero failures**. This checks the exported resources rather than claiming the release executable supports a standalone script-test runner. The release executable also passes a headless 120-frame launch/exit smoke test with `--isolated-qa`, using a separate `DoodleRumbleNativeQA` profile. The latest standalone app has not been manually played.

## Graphical review

Real Godot OpenGL viewport captures were inspected for title, selection, all three arena layouts and interactions, H4CK3R and its tablet attack, Pac-Man and Dark lord attacks, damage numbers, dodge/counter, all six air attacks, settings and victory. Contact shadows now project onto actual floor/platform surfaces. Weapon windup/active timing drives swing animation; effects do not own damage. Capture/profile scripts use a hidden unfocusable viewport, separate graphical preferences and `--silent-qa`, which disables audio playback for that process only. Final capture logs exit cleanly.

A 12-second live boss scene on the M1 produced 1,081 rendered frames (1,002 intervals after warmup), mean 10.98 ms, p95 16.65 ms, peak 1,376 draw calls. The stress harness refills health to sustain activity; it is a rendering sample, not a completed-match test. It is muted and offscreen, not a measurement of full standalone audio/display performance or other Macs.

Racing-specific runtime scripts were compared byte-for-byte with the previous delivered ZIP and remain unchanged. The existing 112-check racing suite still completes both preset races and one custom two-lap race.

## Repeating checks safely

Use a COPY of `game/`. In that copy's `project.godot`, add these lines below `[application]`:

```ini
config/use_custom_user_dir=true
config/custom_user_dir_name="DoodleRumbleManualQA"
```

Import the copy in standard Godot 4.7.2. Run each suite serially using the editor executable (adjust paths):

```sh
DOODLE_GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
"$DOODLE_GODOT" --headless --editor --path "/path/to/qa_game" --import --quit
"$DOODLE_GODOT" --headless --fixed-fps 60 --path "/path/to/qa_game" --script res://tests/test_game.gd
```

Replace `test_game.gd` with each suite from the table. Each prints a `TEST_RESULT` marker and fails on assertions. Inspect the entire log for `ERROR` and `WARNING` as well as the exit code: Godot can return zero after script errors. Test-source and exported-resource logs are included in `docs/test-results/`.

## Human/device checks remaining

Play this exact app using the family's keyboards/controllers; assess the full story with every fighter, simultaneous local inputs, readability and fairness. Test Intel, physical controller assignment/disconnect, keyboard rollover, fullscreen, sleep/wake, first launch after transfer, speakers/headphones and long-session performance. Observe voluntary rematches and where children stop or ask for help. Automated success does not establish replay value or commercial demand.
