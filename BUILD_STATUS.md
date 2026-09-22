# Build status — Doodle Rumble v0.6.8

Updated 2026-09-22. Standard Godot 4.7.2 / GDScript.

## Completed

- Integrated all nine owner-supplied transparent character packs. All 306 original RGBA PNGs, manifests and READMEs are retained unchanged in `source_art/`; 155 smaller runtime pose/effect copies and pivot metadata are in `game/assets/character_art/`.
- Orange, Red, Green, Blue, Purple and Yellow use the new cutouts in fighter selection, live special previews, story scenes and battles. Pac-Man, H4CK3R and Dark lord use theirs in the appropriate story battles and scenes; they remain bosses, not selectable fighters.
- Existing movement, jump, basic attack, special, selected boss-cast and visual-effect states select the relevant pack art. Source padding is trimmed without shifting the ground pivot. The baked weapon in each character pose hides the older procedural weapon while the packed pose is shown. Damage, hitboxes and recovery timing remain fixed-step gameplay data.
- Re-rendered the 30-second ending movie from the updated storyboard and retained its original score. The title poster and arena backgrounds remain as designed. Doodle Rally was not changed.
- Added the pack mapping document, build-time importer, native screenshot gallery and a development-story section in the GitHub README.

## Verification

The complete source and exported-PCK suites each pass **23 suites / 2,169 checks / 0 failures**. Native 1280×720 captures were reviewed for selection, two-player combat, all three bosses and four decoded movie moments. The v0.6.8 Universal Mac export includes arm64 and x86_64 binaries and passes strict ad-hoc code-sign verification. See [TESTING_0_6_8.md](docs/TESTING_0_6_8.md) for the exact evidence.

## Known limits and next steps

The packs have no dedicated hit, dodge, victory or defeat frames, so existing pose transformations and procedural result animation remain. Unused turnarounds, head/tool details and non-Red heavy-smash poses are preserved as source for future art work. The Mac app is not Apple-notarized; physical controllers, Intel execution, transferred first launch and family playtesting still need verification on those devices.
