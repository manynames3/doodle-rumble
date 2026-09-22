# Validation archive — Doodle Rumble v0.6.8

Updated 2026-09-22. Godot 4.7.2, Compatibility renderer, Apple M1/macOS 26.6.2. Automated QA used isolated preferences and silent audio; it did not control a player's running game instance.

## Asset integrity and state wiring

- All nine supplied archives were present and passed ZIP integrity checks. Their manifests identify 34 individually transparent PNGs each.
- All **306 copied source PNGs matched the supplied originals byte-for-byte**. All **155 runtime PNGs** were verified as RGBA with transparent corners; no reference poster or opaque sheet was imported as a sprite.
- The new `test_character_art_packs.gd` checks every pack's pose/effect resource paths, role-appropriate animation state, source-to-runtime manifest availability in both source and PCK, hidden duplicate weapons, and result fallback: **262 checks, 0 failures**.
- The six playable fighters render their new art in selection and match captures. Pac-Man, H4CK3R and Dark lord render theirs in their actual story stages. Pack mapping and retained unused source images are documented in [CHARACTER_PACK_MAPPING.md](CHARACTER_PACK_MAPPING.md).

## Gameplay regression

The complete source run and exported-PCK run each passed **23 suites / 2,169 checks / 0 failures**. Existing suites cover movement, collisions, attack timing and damage, specials, boss patterns, AI difficulty, hazards, menus, story progression, audio, the ending, local battles and Doodle Rally. The live game suite exercised 18 rounds with zero retries. Source and packaged per-suite logs and machine-readable results are in `docs/test-results/v068/` in the delivery archive.

## Native visual review

The Godot native renderer captured 1280×720 fighter selection, Orange-versus-Blue combat, Pac-Man in Arcade Afterglow, H4CK3R in Neon Switchyard and Dark lord in Glitch Core. Those images were inspected for transparency, placement, silhouette, layering and effect visibility. Curated captures are in [the screenshot gallery](screenshots/README.md). The ending was re-rendered as a 30.00-second, 24 fps Ogg Theora/Vorbis movie with its existing original score. Godot decoded the shipped video at four sample positions (3, 11, 21 and 27 seconds), including a packed-art scene and the desk return; the resulting frames were inspected.

## Mac export

The v0.6.8 `.app` was exported with the matching Godot templates and contains both arm64 and x86_64 executables. `codesign --verify --deep --strict` passed. The app executable launched and exited cleanly with isolated QA preferences; a native selection capture loaded its transparent art directly from the exported PCK. The source and Mac ZIP deliveries passed archive integrity checks, and an extracted-app launch was smoke-tested.

This is a locally ad-hoc signed, non-notarized build. Physical controller behavior, Intel execution, transferred first launch, keyboard rollover, display scaling, audio hardware and family playtesting remain device checks.
