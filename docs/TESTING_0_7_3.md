# Verification — Doodle Rumble v0.7.3

## Art update

Four transparent Doodle Workshop weapons were restyled against the intro poster. `*_v2.png` variants now supply held art, workshop previews, and the bone/ball projectiles; the previous sprites remain in the source tree. Sprite pivots affect positioning only. No damage, timing, cooldown, hitbox, projectile, or protection values changed.

## Source and visual checks

- Godot 4.7.2 imported all four v2 PNGs.
- Source regression passed **30 suites / 2,483 checks / zero failures** with isolated QA data. Raw results are retained locally under `docs/test-results/v073/weapon-art/source-regression/`. This includes the four workshop combat kits, projectile bounces/reflection, hit windows, custom art, story, menus, bosses, audio, and existing game modes.
- Native renderer captures passed **34 checks / zero failures** for each pair: Bat/Bone and Pickaxe/Soccer Ball. I inspected My Doodles and actual main-scene match renders at 1280×720 on an Apple M1. Raw captures remain local under `docs/test-results/v073/weapon-art/`; the reproducible capture script is in `game/tests/`.
- The captures show controlled scene renders, not a full family play session. The additional custom-fighter frame timings in the capture report are not a benchmark of weapon sprite performance.

## Mac app and exported-pack checks

- Exported a fresh PCK from the v0.7.3 source and inserted it into a separate copy of the existing verified Godot 4.7.2 Universal app runtime. The v0.7.2 app remains unchanged.
- The final PCK passed **30 suites / 2,483 checks / zero failures**; packaged regression results remain local under `docs/test-results/v073/weapon-art/packaged-regression/`. The rebuilt app completed a **120-frame headless boot** using an isolated user-data directory, with no runtime errors.
- `codesign --verify --deep --strict` passed. `file` confirms the app executable contains both arm64 and x86_64 slices. Only the Apple Silicon renderer was exercised; Intel execution and transferred first launch were not tested.
- Packaging-policy tests passed **6/6**. No new ZIP archives were created in this update; the current Godot source project remains in the workspace folder.
- The app is ad-hoc signed, with no Developer ID signature or notarization. A double-click GUI play session on a separate Mac remains unverified. The complete Godot project remains available in this repository folder; no additional project ZIP was created in this update.
