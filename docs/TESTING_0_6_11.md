# Validation archive — Doodle Rumble v0.6.11

## Difficulty change

- The fixed-seed, 45-second regular-fighter AI simulation records **22 / 27 / 47** attack decisions on Easy / Medium / Hard. Hard's 47 decisions are 31% above the v0.6.10 baseline of 36 and fall within the requested 30–50% increase.
- The Hard post-hit test starts with stale think, tell and rest timers, simulates the 0.18-second fighter hit-stun, and verifies that the controller begins another readable tell within 0.30 seconds. The observed time was **0.05 seconds**.
- The same suite checks that Easy retains its existing recovery pacing, Hard keeps its full warning tell, and the extra pressure is scoped to the regular-fighter controller. H4CK3R and Dark lord continue to use their separate boss controllers.
- The existing live-difficulty suite passes for Easy, Medium and Hard; hazard windows and boss move pressure remain under their existing tests.

## Build and regression

- Godot 4.7.2 ran all **24 source suites**: **2,280 checks, 0 failures**. Detailed output is in [`test-results/v0611/source/`](test-results/v0611/source/).
- All **24 suites** also passed against the exported Mac PCK: **2,280 checks, 0 failures**. Detailed output is in [`test-results/v0611/packaged/`](test-results/v0611/packaged/).
- The Universal Mac app is version **0.6.11 / build 18**. Its executable contains **arm64** and **x86_64** slices. `codesign --verify --deep --strict` passed with an ad-hoc signature.
- The exported app booted the main scene for 120 headless frames with a fresh isolated Godot user-data directory and no errors.
- `game/tools/test_package_release.py`: **6 tests passed**.

## Limits

These are automated controller and packaged-build checks. They do not replace a human match or family playtest. This machine cannot test a transferred download on another Mac, the Intel runtime, physical controllers, keyboard rollover or real speakers. The app is not Developer ID signed or notarized; Gatekeeper may require **Open Anyway** after transfer.
