# Easier Dark Lord on Easy — v0.7.14

2026-10-11. Godot 4.7.2, Universal Mac build 32. Automated tests used isolated QA preferences.

## Change

Dark lord's outgoing melee, special, projectile, shockwave and signature-hazard damage is reduced to 70% on Easy, rounded to whole damage points. Medium and Hard keep their existing tuning. Other fighters and ordinary arena hazards are unchanged. This changes damage only; Dark lord's attack pace and warnings remain intact.

## Source results

| Verification | Result |
| --- | --- |
| Headless Godot import | Passed |
| Full source regression | 34 suites, 3,164 checks, zero failures |
| Easy damage regression | 59 checks, zero failures |
| Difficulty suite | 92 checks, zero failures |
| Boss pressure suite | 101 checks, zero failures |
| Fuse boss suite | 50 checks, zero failures |
| Story-world hazard suite | 73 checks, zero failures |
| Release archive-policy tests | Six passed |
| `git diff --check` | Passed |

## Mac export

The Universal app contains both arm64 and x86_64 slices. Strict local ad-hoc signature verification passed, and the exported executable completed an isolated 120-frame headless startup. The exact embedded PCK passed five combat-relevant suites—boss strength, Fuse boss, boss update, difficulty and game—for **459 checks / zero failures**. The app is ad-hoc signed and not Apple-notarized. Intel execution on an Intel Mac, physical controllers, transfer to another Mac and family playtesting were not tested.
