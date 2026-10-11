# Fuse aggression verification — v0.7.11

Verified October 10, 2026 with Godot 4.7.2 on Apple M1. Automated runs used `--isolated-qa`; the family profile was not used.

Published as the [v0.7.11 GitHub release](https://github.com/manynames3/doodle-rumble/releases/tag/v0.7.11) with matching source commit `cacb248`. The [playable Mac ZIP](https://github.com/manynames3/doodle-rumble/releases/download/v0.7.11/Doodle_Rumble_Mac_v0.7.11.zip) is 261,117,521 bytes; GitHub reports the same SHA-256 as the verified local archive. The public download returned HTTP 200.

## Behavior and regression

Fuse's attack multiplier increased from 1.375 to 2.0625, exactly 50% before final per-hit rounding. Single missiles deal 38 damage, fan and burst missiles 23, high/low missiles 27 and launcher bash 42. Health remains 215. Hit stun decreased from 0.18 to 0.10 seconds while the existing 0.68-second hit invulnerability remains intact. A distinct stagger state replaces the former full 0.65-second reload after a hit with one 0.08-second restart; continued stun ticks do not restart the pause.

The reload window decreased from 0.65 to 0.45 seconds, the rest between patterns from 0.16 to 0.08 seconds, and the approach decision cap from 1.20 to 0.65 seconds. The full 0.85-second warning remains unchanged at every difficulty. Fuse now has five attacks: single missile, three-lane fan, high/low pair, launcher bash and a timed three-missile burst. Burst shots fire 0.18 seconds apart with fixed warned aim and direction; interruption cancels remaining shots. A distant or elevated opponent receives the burst instead of an unreachable launcher bash.

The new held-bow regression was first run against the exact published v0.7.10 pack, where it reproduced the hesitation and failed the restart/cadence assertions. The same 15-second scenario then passed against the updated source:

| Actual held-bow scenario | v0.7.10 | v0.7.11 source |
| --- | ---: | ---: |
| Arrows fired at real bow cadence | 23 | 23 |
| Frames of Fuse hit stun | 99 | 35 |
| Longest wait from end of stun to next warning | 64 frames | 7 frames |
| Missile release events (a simultaneous fan counts once) | 3 | 12 |
| Distinct missile patterns released | 3 | 4 |
| Damage to the shooter | 59 | 199 |

The damage difference in this scenario includes shorter pauses and more attacks; it is not a claim that overall difficulty can be measured as an exact percentage.

In the separate 25-second passive pressure test, the published v0.7.10 pack dealt 236 Fuse damage and the updated source dealt 352: a 49.2% increase in that sample. H4CK3R remained 224 and Dark lord remained 491, preserving the late-stage pressure ordering.

## Source and visual checks

| Suite | Checks | Failures |
| --- | ---: | ---: |
| `test_fuse_boss` | 50 | 0 |
| `test_fuse_pressure` | 7 | 0 |
| `test_boss_strength` | 48 | 0 |
| `test_premium_audio` | 192 | 0 |
| `test_combat_depth` | 343 | 0 |
| `test_difficulty` | 92 | 0 |
| `test_core` | 112 | 0 |
| `test_game` | 157 | 0 |
| **Total** | **1,001** | **0** |

The first general-game run's old Purple bot reused Dark lord's stationary shooting strategy against Fuse and lost; its two journey-completion assertions failed. The test bot now uses Fuse-specific spacing, Purple's actual directional shield dodge, and grounded attacks during reload. Production balance was not reduced to accommodate it. The final full `test_game` run passed all 157 checks using `--fixed-fps 60`, which keeps the authored 60-Hz step and disables real-time synchronization. It cleared all eight fights with no retries in 14,107 frames; Fuse's match ended 2–0 with Purple at 42 HP. The held-bow and original passive pressure comparisons used normal real-time synchronization.

The focused Fuse suite also checks full warnings across all three difficulties, real short hit stun, burst spacing/fixed aim/facing, cancellation, single restart, distance-aware selection, punishable reload, authored release/recovery frames, bash commitment and reflection. New CLI scopes `--live-fuse-only` and `--live-journey-only` allow targeted reruns of the game test.

Captured and inspected 23 native 1280×720 views of the four missile patterns, warning/release/reload, timed burst train, missile impact, results, reduced-motion result, eight-card journal and story dialogue. The burst warning clears Fuse's head and its three sequential missiles are readable. The existing firing muzzle, missile, exhaust and impact art are reused. [16-fuse-burst.png](screenshots/16-fuse-burst.png) is the curated native gameplay capture. An independent integrated review found no blockers in hit recovery, cancellation, death/reset/round cleanup, damage scaling, scoring or reflection. `git diff --check` passed.

## Mac package

Exported Universal Mac v0.7.11 / build 29 to `builds/mac-v0.7.11/`. Both arm64 and x86_64 slices are present. Strict ad-hoc signature verification and a 120-frame isolated startup of the actual exported executable passed. The final app-only ZIP's SHA-256 is `5dc2f5c757f01ec9b4caedb83c91e1078ac8cb54503b4e6d110208d514a6ced3`.

The exact final exported PCK passed `test_fuse_boss` (50 checks), `test_fuse_pressure` (7 checks), `test_boss_strength` (48 checks) and `test_game --live-fuse-only` (5 checks): **110 checks / zero failures**, run with the editor executable's `--main-pack` option. The boss and live-fight suites used the fixed 60-Hz step; held-bow ran with normal real-time synchronization. Packaged passive pressure matched source (H4CK3R 224 / Fuse 352 / Dark lord 491), and the packaged live fight ended 2–0 with Purple at 42 HP. Its held-bow test also matched source: 23 arrows, 35 hurt frames, five resumptions, a longest restart of seven frames, 12 missile release events through four patterns and 199 damage. ZIP integrity passed.

The app is ad-hoc signed and not notarized. Intel execution, transfer to another Mac, physical controllers and human playtesting of the upgraded fight remain unverified.
