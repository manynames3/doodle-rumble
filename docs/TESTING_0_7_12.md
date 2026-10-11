# Menu motion release verification — v0.7.12

2026-10-11. Godot 4.7.2, Universal Mac build 30. Source, native and export verification ran on Apple M4 with isolated preferences. Publication is in progress.

## Change

Added The Underline Heist to the existing title menu: larger hand-inked Blue and Yellow, expressive anticipation/reactions, skating and faceplant, a premature celebration followed by a stolen-back star, double-take and sheepish grin. The poster and six menu controls retain their layout and behavior. Static reduced motion remains available. No gameplay, saves, bosses, dependencies or racing changes. See [TESTING_MENU_MOTION.md](TESTING_MENU_MOTION.md) for implementation details and reproduction.

## Source and native results

| Verification | Result |
| --- | --- |
| Headless import | Passed, no errors/warnings |
| Source menu suite | 168 checks, zero failures |
| Native menu animation | 42 checks, 612 captures, zero failures |
| Actual 854×480 window | Two checks, one capture, zero failures |
| Archive-policy suite | Six tests passed |
| Independent current-source/native review | No blockers |
| Diff whitespace | Passed |

Native captures include the complete greeting and two loops, mirrored staging, all focus states, reduced motion and scene reentry. Source/runtime checks cover GUI navigation, hover, activation, stable hitboxes, rapid focus and node cleanup. Native images were inspected. The small-window check uses the actual resized root Window, not an offscreen transform. The QA sound shutdown now waits for stopped playback to clear the mix thread; final QA runs have no exit warnings. No production audio code was changed.

A 1,620-frame local native profile measured mean 6.902 ms, median 6.062 ms, p95 11.675 ms and maximum 45.358 ms, with a separate live preview left running. Cosmetic update averaged 0.0226 ms. This is a single local render/scheduling sample, not a controlled cross-version benchmark or guarantee on other hardware.

## Exact Mac export

Exported `builds/mac-v0.7.12/Doodle Rumble.app` as v0.7.12 / build 30 with matching Godot 4.7.2 templates. Both arm64 and x86_64 executable slices are present. Strict local ad-hoc signature verification passed; the actual app executable completed an isolated 120-frame headless startup without errors or warnings.

The exact embedded PCK passed **175 checks / zero failures**: `test_menus.gd` (168) and `test_game.gd --live-fuse-only` (five), and the actual native small-window fixture (two). The unchanged live fight completed two rounds, score 2–0, Purple at 42 HP, with no retries. Physical controller input, Intel execution, transfer to another Mac and family fun/playtesting were not performed in this release pass. The app is ad-hoc signed and not Apple-notarized.

Archive integrity, source revision, ZIP digest and public download verification will be added after publication.
