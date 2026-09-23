# Build status — Doodle Rumble v0.6.9

Updated 2026-09-22. Standard Godot 4.7.2 / GDScript. This is a locally tested Mac release candidate; public one-click installation still needs Apple Developer ID signing and notarization.

## Completed

- Six selectable fighters, six rising story stages, Pac-Man, H4CK3R and Dark lord boss encounters, Quick Match, local 2P Battle, and Doodle Rally remain playable. The shared controls, audio and settings are preserved.
- All nine supplied transparent art packs are wired to their proper roles. The 306 original PNGs stay unchanged in `source_art/`; 155 trimmed runtime cutouts and pivot metadata live in `game/assets/character_art/`. Bosses remain story opponents.
- Packed fighters now use responsive idle and run poses, visible attack phases and better-scaled selection previews. Illustrated selection cards still show each fighter's special. Purple's projectile art no longer appears after release, and the H4CK3R/Dark lord attack art changes at the actual release phase.
- The round camera stays fixed. Winners keep celebrating; fallen fighters and orbiting stars remain in frame even at stage edges. Result animation and the 30-second ending movie use the updated art without changing combat hit timing.
- Public screenshots and development notes were refreshed. Packaging now keeps the nine production packs but omits the family's private drawings, original planning files, caches, credentials and AppleDouble metadata.

## Verification

The complete source and final exported-PCK suites each passed **24 suites / 2,251 checks / 0 failures**. Native selection, combat, boss, result and ending captures were reviewed. Release evidence, archive checks and Mac launch results are in [TESTING_0_6_9.md](docs/TESTING_0_6_9.md).

## Known limits and next steps

- No dedicated hit, dodge, victory or defeat PNGs were supplied, so the game uses its existing pose transformations and result effects for those moments. Unused art remains in the original packs for a future animation pass.
- This Mac has no Apple Developer Program account or Developer ID certificate. The Universal app is ad-hoc signed, **not notarized**; a transferred copy may need macOS **Privacy & Security → Open Anyway**. Do not present it as a frictionless public installer.
- Physical controller behavior, Intel execution, a transferred first launch, keyboard rollover, audio on different hardware, long sessions and family playtesting still require those devices and players. Balance and fun cannot be established by automated checks alone.
