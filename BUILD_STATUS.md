# Build status — Doodle Rumble

Updated 2026-09-24. Godot 4.7.2 / GDScript. The Universal Mac build was prepared on an Apple M1 Mac.

## Local project follow-up (not yet released)

- Imported fighters now show the selected weapon on both **Weapon** and **Try it!** while body cutouts are still being finished. The Try It page can preview the selected special; a clear note explains that all six cutouts are needed for the paper fighter to animate.
- Cutout connectors now take their tint from nearby opaque ink inside the traced part and skip pale gray paper. This avoids stretching a sampled paper color into a gray strip behind the face or neck.
- Focused checks cover incomplete and complete photo rigs, the selected weapon, its special preview, and paper-colored connector rejection. The latest full source regression for this local tree passes: **30 suites / 2,867 checks / zero failures**, including Workshop, music, and premium-audio coverage. Native Workshop screenshots using the supplied yellow doodle were captured and inspected.
- These fixes are in the local Godot project. They are not included in the published v0.7.7 app or archives.

## Local audio polish (not yet released)

- Reworked all six stage scores into distinct, developed 61–73 second arrangements so a 60-second round ends before a full loop repeats. Each keeps tempo-aligned intro, battle and climax versions; generated climax mixes now have a consistently stronger measured level while retaining waveform headroom.
- Story chapters now play the corresponding arena's lighter music arrangement. The story journal keeps its quieter paper-desk theme. Pac-Man, H4CK3R and Dark lord have distinct basic attack sounds; fighter specials, custom weapon kits and boss patterns receive their own short signature cues. Heavy combat cues gently lower the score for a moment and release it smoothly.
- Music assets were regenerated with the deterministic local composer. All 18 WAVs passed repeated byte-for-byte regeneration, mono/16-bit/22.05 kHz format checks, 61–73 second duration checks, peak levels below 0.75, and intro < battle < climax RMS checks for every stage. Godot 4.7.2 source regression passed **30 suites / 2,867 checks / zero failures**, including the focused music (114 checks) and premium audio (188 checks) suites. Automated checks do not audition the mix; speakers/headphones, external audio hardware and family listening feedback remain unverified.
- A local Universal Mac app was exported as **v0.7.8 / build 26** to `builds/mac-v0.7.8/Doodle Rumble.app`; an app-only ZIP was created in the workspace outputs folder, outside this repository. The exported pack passed the focused music (114 checks) and premium-audio (188 checks) suites, and the app completed a 120-frame headless startup smoke test. It is ad-hoc signed and not notarized. No project archive or GitHub release was created.

## v0.7.7 Workshop and photo cleanup

- Photo import now explains that it removes page white but does not auto-detect limbs. The complete original photo stays in the preview until all six body-part cutouts are valid, rather than showing a misleading fragment after the first partial outline.
- Cutout validation rejects very small, narrow, malformed or untriangulatable outlines. Save redirects the player to the first bad outline and explains how to trace that whole part. The footer and instructions now match whether **Trace cutouts** or **Move joints** is selected.
- Draw mode has separate **Fighter** and **Pen** color palettes. Changing the fighter color only recolors starter-body marks; the pen independently colors new strokes. Both colors survive saves and undo/redo, and older creations without a saved pen color keep their previous palette behavior.
- Photo cleanup now handles warm-gray paper such as the supplied test image at its default strength, while preserving the yellow marker. The slider updates a visible cutout preview and stays independent from the **White edge** sticker-border setting. Keep/Erase corrections now apply in brush order.
- Complete source regression: **30 suites / 2,794 checks / zero failures**, including the targeted Workshop suite (**60 checks**). Export verification and remaining device checks are recorded in [TESTING_0_7_7.md](docs/TESTING_0_7_7.md). Native screenshots were captured and inspected.
- Published Universal Mac app: `builds/mac-v0.7.7/Doodle Rumble.app`, build 25. The bundle is ad-hoc signed; strict signature verification and an isolated 120-frame launch smoke test passed. It is not notarized.
- The app remains ad-hoc signed and not notarized.

## Published v0.7.6 feature set

- The match presentation now gives fighters 15% more screen presence without changing their collision capsules, weapon reach, attack timing, or damage. The HUD uses rougher ink swatches, and tutorial/control prompts clear after the opening seconds so the arena takes over.
- Removed the second, fully animated custom-fighter renderer from the tiny match HUD portraits. Custom art is split into articulated cached pieces, warmed during selection, and baked one piece per frame rather than building both fighters' artwork at once.
- Added optional, non-damaging movement routes to three later story arenas: catch a wind gust in Paper Canopy, jump off a bumper in Arcade Afterglow, and ride a data lift in Neon Switchyard. Each route has matching visual and sound cues and a short reuse cooldown.
- Restored full animated portraits in story scenes while keeping the lighter custom-doodle icon in the combat HUD.
- Updated the public source/download documentation and prepared a matching Universal Mac export and complete Godot project archive. Doodle Rally's gameplay and assets were not changed.
- The project owner reports that the requested family playtesting item is complete. No scored observation sheet was supplied for this update.

## Verification — published v0.7.6 baseline

- The original Godot 4.7.2 project import and full regression for v0.7.6: **30 suites, 2,782 checks, zero failures**. The newer v0.7.7 results are listed above and in [TESTING_0_7_7.md](docs/TESTING_0_7_7.md).
- Native Apple M1 capture of 12 drawn/photo poses: **34 checks, zero failures**. Imported skin and shirt colors were sampled from the rendered viewport and preserved; the small paper edge stayed enabled; segment caches completed before the contact sheet was judged.
- Custom-fighter native profile, two generated 906-stroke fighters after a selection warm-up, 300 frames in the main scene: mean **8.79 ms**, median **8.79 ms**, p95 **9.14 ms**, maximum **9.89 ms**. Match setup measured **18.38 ms**. The first sampled match frame peaked at **39.25 ms**, a brief entry spike; steady in-match p95 stayed below 10 ms in this run.
- The performance sample used a hidden 1280×720 SubViewport, Godot Compatibility renderer and Apple M1. It is not a test of every Mac, screen mode, or real family drawing.
- Native captures were rendered and inspected for fighter scale, attack framing, HUD legibility, imported cutout poses, and story routes. Story, ending, arena, custom combat, Workshop, AI, pause/rematch, and racing regression suites passed. Racing was not modified.
- `git diff --check`, six package-policy checks, Universal app slices, ad-hoc code signature, exported PCK boot, and archive integrity checks passed. The exported PCK was smoke-booted headlessly for 120 frames; a second Mac and GUI launch were not tested.

## Mac build and launch

- Current app: **v0.7.7 / build 25**, Universal arm64/x86_64, Godot 4.7.2 Compatibility renderer at `builds/mac-v0.7.7/Doodle Rumble.app`. The executable contains both architecture slices; strict local signature verification passed. Its embedded game pack boots headlessly for 120 frames and exits without errors.
- Public archives: `Doodle_Rumble_Mac_v0.7.7.zip` and `Doodle_Rumble_Project_v0.7.7.zip`, available from the [v0.7.7 GitHub release](https://github.com/manynames3/doodle-rumble/releases/tag/v0.7.7). The [v0.7.6 release](https://github.com/manynames3/doodle-rumble/releases/tag/v0.7.6) remains available as an earlier version.
- Launch the local build by double-clicking **Doodle Rumble.app** in the v0.7.7 folder. From source, open `game/project.godot` in Godot 4.7.2 and press F5.

## Known limits

- Photo cutouts remain a manual assisted workflow. Page-white cleanup does not find or separate the character automatically; children trace the six body parts. Overlapping or faint photos may still need adult help.

- This Mac has no Developer ID certificate. The app is ad-hoc signed and not notarized, so Gatekeeper may require **System Settings → Privacy & Security → Open Anyway** after transfer. This is not a notarized public storefront release.
- Intel execution, transfer to another Mac, physical controller assignment/disconnect, keyboard rollover, sleep/wake, and external speaker/headphone behavior were not verified here.
- The native performance check shows a single entry-frame spike even after selection warm-up. Steady frames in the measured custom-fighter match were below 10 ms at p95 on this M1; unusually detailed artwork and other Mac hardware still need measurement.
