# Build status — Doodle Rumble v0.7.6

Updated 2026-09-24. Godot 4.7.2 / GDScript. This build is prepared on an Apple M1 Mac.

## This update

- The match presentation now gives fighters 15% more screen presence without changing their collision capsules, weapon reach, attack timing, or damage. The HUD uses rougher ink swatches, and tutorial/control prompts clear after the opening seconds so the arena takes over.
- Removed the second, fully animated custom-fighter renderer from the tiny match HUD portraits. Custom art is split into articulated cached pieces, warmed during selection, and baked one piece per frame rather than building both fighters' artwork at once.
- Added optional, non-damaging movement routes to three later story arenas: catch a wind gust in Paper Canopy, jump off a bumper in Arcade Afterglow, and ride a data lift in Neon Switchyard. Each route has matching visual and sound cues and a short reuse cooldown.
- Restored full animated portraits in story scenes while keeping the lighter custom-doodle icon in the combat HUD.
- Updated the public source/download documentation and prepared a matching Universal Mac export and complete Godot project archive. Doodle Rally's gameplay and assets were not changed.
- The project owner reports that the requested family playtesting item is complete. No scored observation sheet was supplied for this update.

## Verification

- Godot 4.7.2 project import and the full source regression: **30 suites, 2,782 checks, zero failures**.
- Native Apple M1 capture of 12 drawn/photo poses: **34 checks, zero failures**. Imported skin and shirt colors were sampled from the rendered viewport and preserved; the small paper edge stayed enabled; segment caches completed before the contact sheet was judged.
- Custom-fighter native profile, two generated 906-stroke fighters after a selection warm-up, 300 frames in the main scene: mean **8.79 ms**, median **8.79 ms**, p95 **9.14 ms**, maximum **9.89 ms**. Match setup measured **18.38 ms**. The first sampled match frame peaked at **39.25 ms**, a brief entry spike; steady in-match p95 stayed below 10 ms in this run.
- The performance sample used a hidden 1280×720 SubViewport, Godot Compatibility renderer and Apple M1. It is not a test of every Mac, screen mode, or real family drawing.
- Native captures were rendered and inspected for fighter scale, attack framing, HUD legibility, imported cutout poses, and story routes. Story, ending, arena, custom combat, Workshop, AI, pause/rematch, and racing regression suites passed. Racing was not modified.
- `git diff --check`, six package-policy checks, Universal app slices, ad-hoc code signature, exported PCK boot, and archive integrity checks passed. The exported PCK was smoke-booted headlessly for 120 frames; a second Mac and GUI launch were not tested.

## Mac build and launch

- Version **0.7.6 / build 24**, Universal arm64/x86_64, Godot 4.7.2 Compatibility renderer. The exported executable was identified as containing both architecture slices and its signature verified locally.
- Local app: `builds/mac-v0.7.6/Doodle Rumble.app`.
- Download archives: `Doodle_Rumble_Mac_v0.7.6.zip` and `Doodle_Rumble_Project_v0.7.6.zip`. The Mac archive contains the app and launch notes; the project archive contains the complete runnable Godot project and its source art.
- Launch by double-clicking **Doodle Rumble.app**. From source, open `game/project.godot` in Godot 4.7.2 and press F5.

## Known limits

- This Mac has no Developer ID certificate. The app is ad-hoc signed and not notarized, so Gatekeeper may require **System Settings → Privacy & Security → Open Anyway** after download. This is a locally tested build, not a notarized public storefront release.
- Intel execution, transfer to another Mac, physical controller assignment/disconnect, keyboard rollover, sleep/wake, and external speaker/headphone behavior were not verified here.
- The native performance check shows a single entry-frame spike even after selection warm-up. Steady frames in the measured custom-fighter match were below 10 ms at p95 on this M1; unusually detailed artwork and other Mac hardware still need measurement.
