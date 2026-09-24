# Verification — Doodle Rumble v0.7.4

## New weapon kits

Rubber Chicken adds **Cluckquake**, a two-sided, comic squeak burst. Jumbo Crayon adds **Rainbow Ruckus**, a telegraphed rainbow sweep that opponents can jump or dodge. Their transparent weapon art is used in held poses, the Workshop preview and signature effects. Each special deals its authored 22 damage, has a six-second cooldown, and can hit each opponent once per cast.

The ground effects resolve to the nearest walkable surface below the caster. This fixes platform casts that previously spawned at the arena floor. Damage boxes extend slightly below the platform surface to overlap the existing fighter hurtboxes; fighter collision, hit protection and fixed-tick timing remain unchanged.

## Automated verification

- Godot 4.7.2 source import completed successfully.
- Source regression: **30 suites / 2,740 checks / zero failures**. Raw results are retained locally under `docs/test-results/v074/source-regression/`.
- Exported PCK regression: **30 suites / 2,740 checks / zero failures**. Raw results are retained locally under `docs/test-results/v074/exported-pack-regression/`.
- Release archive policy tests: **6/6 passed**; no archive packages were created.
- The custom combat suite reports **340 checks / zero failures** across 30, 60 and 120 Hz. It covers all six kits' ground and air attacks, specials, cooldowns, AI decisions and bot pairings, projectile cleanup/reflection, and elevated-platform specials.
- Existing racing tests passed as part of the full suite; no racing code or content was modified for this feature.

## Native render and performance checks

The native capture ran on an Apple M1 with Godot 4.7.2's macOS Compatibility renderer at 1280×720. It passed **38 checks / zero failures** using isolated QA creations: one 51-stroke drawing and one synthetic six-part photo cutout. Captures show the Workshop selection, a match, six animation poses, and both new specials in Desktop Dojo:

- [My Doodles selection](screenshots/workshop/my-doodles.png)
- [Actual match](screenshots/workshop/custom-fighters-in-match.png)
- [Rubber Chicken and Jumbo Crayon specials on elevated platforms](screenshots/workshop/custom-weapon-specials.png)
- [Six animation poses](screenshots/workshop/six-poses.png)

The two-rig, 300-frame sample measured 10.03 ms median, 13.46 ms p95, and 34.51 ms maximum frame wall time. Pose CPU time was 0.155 ms median and 0.201 ms p95. This is a controlled sample, not a low-end-Mac benchmark or a full family play session. The complete capture report remains local under `docs/test-results/v074/weapon-art/rubber_chicken-giant_crayon/`.

## Mac app

- Exported with the matching official Godot 4.7.2 macOS template to `builds/mac-v0.7.4/Doodle Rumble.app` in the developer workspace; the generated app is not in Git.
- The app is Universal (arm64 and x86_64), version 0.7.4, build 22, about 309 MB. `codesign --verify --deep --strict` passed.
- The exported app completed a **120-frame headless boot** with isolated QA arguments. The app was not given a separate double-click playthrough on another Mac.
- This is an ad-hoc local signature. There is no Developer ID certificate or notarization; Gatekeeper may require a local override after transferring the app.

## Still needs human testing

Try the new kits with children to check whether their effects are funny, readable and fair. Also check controller navigation, speaker output, Intel execution, first launch after transfer, low-end hardware and detailed user-created drawings. The screenshots use QA-made art, not private family artwork.
