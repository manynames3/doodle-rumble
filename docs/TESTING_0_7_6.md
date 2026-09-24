# Verification — Doodle Rumble v0.7.6

Tested on macOS with Godot 4.7.2, Apple M1 and the Compatibility renderer. Automated tests used isolated QA profiles; the running user game was not controlled.

## Regression and gameplay

- Full source regression: **30 suites / 2,782 checks / zero failures**. Individual logs are kept in the local `docs/test-results/` folder; they are excluded from the distributable source archive.
- Story-arena movement routes passed **85 focused checks** for trigger edges, jump release, cooldown, platform alignment and fixed-step behavior. Routes add no damage and do not change attacks.
- H4CK3R/Dark lord pressure, attack patterns, 25%/50% gameplay scale, hurtboxes and collision capsules passed **101 boss-update checks**. Existing combat, custom-fighter, Workshop, story, ending, pause/rematch, AI, racing and settings suites were included in the full run.
- The owner reports that family playtesting is complete. That is owner-reported feedback, not a separately observed or scored session in this report.

## Custom-fighter performance and rendering

- Native Mac capture exercised a drawn fighter and an imported six-part photo fighter through six poses each, plus the My Doodles selection and an actual local match. **34 checks passed**. The rendered photo retained sampled skin/shirt colors, joined torso/neck and bend joints, and the paper margin. The complete contact sheet was inspected after all segment pages finished baking.
- Stress profile: two generated 906-stroke fighters, 300 rendered frames after warming the selection screen. On this M1/Compatibility renderer: mean **8.79 ms**, median **8.79 ms**, p95 **9.14 ms**, maximum **9.89 ms**; physics CPU p95 **0.29 ms**. Match construction took **18.38 ms**. The first sampled match frame reached **39.25 ms**, so a brief entry-frame hitch remains measurable. Steady in-match frames were below 10 ms at p95 in this run.
- Frames were measured in a hidden 1280×720 SubViewport, not on every display/GPU or during a family session. Dense art and other Macs may behave differently.
- A native combat screenshot was inspected and added to the README gallery. The updated render makes fighters more prominent and retains attack framing; tutorial/control prompts fade after the opening seconds. Character scaling affects rendered art only; collision and attack systems remain game-owned.

## Mac export and distribution

- Version **0.7.6 / build 24**, exported from Godot 4.7.2. The app executable contains arm64 and x86_64 slices (`file` inspection); `codesign --verify --deep --strict` passed. The exported PCK booted headlessly for 120 frames and quit without errors. A graphical launch and execution on a second Mac were not tested.
- Release archive policy: **6 policy checks passed**. Both ZIPs passed CRC verification; the source archive passed required-project, source-art, licensing and private-file checks. SHA-256 receipts were generated alongside the Mac app and complete Godot project archives.
- This Mac has no Developer ID identity. The bundle is ad-hoc signed and not notarized; Gatekeeper behavior after transfer, Intel execution, physical controller handling and external audio hardware remain unverified.
