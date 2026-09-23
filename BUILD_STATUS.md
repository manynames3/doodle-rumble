# Build status — Doodle Rumble v0.6.11

Updated 2026-09-23. Godot 4.7.2 / GDScript. Universal macOS app exported as build 18 and verified with an ad-hoc signature; it is not Developer ID signed or notarized.

## Completed

- Hard-mode computer Orange, Red, Green, Blue, Purple and Yellow now attack more often, move 10% faster, and choose specials 25% more often than before. In the fixed-seed 45-second controller test, Hard produced 47 attack decisions versus the v0.6.10 baseline of 36 (+31%).
- Hard regular fighters clear stale thinking and recovery waits while hit-stun plays, then begin a new visible attack tell within 0.05 seconds in the focused re-engagement test. The regular 0.18-second hit-stun and protection window remain intact.
- Easy and Medium pacing, boss AI, hazard timing, damage, attack warnings and Doodle Rally were not changed by this update.
- The six playable fighters, six-stage story, arenas, modes, settings and rematches remain available. The exported app reports version 0.6.11 / build 18 and contains the updated difficulty logic.

## Verification

- Source project: **24 suites / 2,280 checks / 0 failures**.
- Exported Mac PCK: **24 suites / 2,280 checks / 0 failures**.
- The packaged app launched its main scene for 120 headless frames using an isolated user-data directory. `codesign --verify --deep --strict` passed, and `file` reports a Universal arm64/x86_64 executable.
- The updated app bundle is at `builds/mac-v0.6.11/Doodle Rumble.app`. No v0.6.11 ZIP was created because this machine ran out of free disk space while compressing it; the existing v0.6.10 download remains intact. The current Godot source is ready in the public repository.
- Package-policy tests: **6 passed**. Targeted difficulty checks confirm the 31% attack-decision increase and prompt post-hit re-engagement while preserving readable tells.
- Evidence is in [TESTING_0_6_11.md](docs/TESTING_0_6_11.md) and [docs/test-results/v0611](docs/test-results/v0611/).

## Known limits and next steps

- The 31% figure is a deterministic AI decision-count comparison, not a claim that every match is exactly 31% harder. Family playtesting is still needed to judge whether Hard feels challenging without being frustrating.
- This Mac has no Developer ID signing identity. The app is ad-hoc signed; a transferred copy may require **System Settings → Privacy & Security → Open Anyway**. Notarization requires a Developer ID certificate and Apple Developer account.
- Physical controller behavior, Intel execution, transferred first launch, keyboard rollover, speaker listening tests, long sessions and family playtesting remain unverified on those devices.
