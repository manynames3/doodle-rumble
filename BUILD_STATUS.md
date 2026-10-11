# Build status — Doodle Rumble

Updated 2026-10-10. Godot 4.7.2 / GDScript. The Universal Mac build was prepared on an Apple M1 Mac.

## Local v0.7.11 — Fuse aggression follow-up

- Raised Fuse's attack damage multiplier from 1.375 to 2.0625, exactly **50%** before rounding. Shortened his hit stun from 0.18 to 0.10 seconds and replaced the full reload after a hit with a single 0.08-second restart. Damage invulnerability and full 0.85-second attack warnings remain intact.
- Added a fixed-aim three-shot burst spaced 0.18 seconds apart, reusing the existing missile, exhaust, impact and firing pose. Out-of-range bashes become the burst; all five attack choices remain available. Faster approach decisions, shorter rests and a 0.45-second vulnerable reload increase attack frequency.
- The new real held-bow test reproduces v0.7.10's hesitation and passes after the fix: longest post-stun restart fell from 64 to 7 frames, missile release events rose from three to twelve across four missile patterns, and damage to the shooter rose from 59 to 199 in the same 15-second scenario. In a separate 25-second passive sample, Fuse rose from 236 to 352 damage, between H4CK3R's 224 and Dark lord's 491.
- Source verification passed **eight suites / 1,001 checks / zero failures**, including the complete eight-fight journey with no retries at a fixed 60-Hz step. The bot reads Fuse's warnings and uses Purple's real shield dodge, winning the stronger fight with 42 HP; it no longer borrows Dark lord's stationary shooting strategy. Inspected 23 native captures, including the distinct burst train and its head-clear warning. An independent integrated review found no blockers. See [TESTING_0_7_11.md](docs/TESTING_0_7_11.md).
- Prepared Universal Mac **v0.7.11 / build 29** in `builds/mac-v0.7.11/`. The exact exported pack passed **110 checks / zero failures**, including the real held-bow and live dodge/counter scenarios. Both architecture slices, strict ad-hoc signature verification, ZIP integrity and actual exported-app startup passed. The app is not notarized.

## Published v0.7.10 — Crackle expansion and Dark lord upgrade

- Added **Crackle**, guided by the supplied drawing: a diamond helmet, huge crystal boots, firework launcher and spear. He appears after Green and immediately before Pac-Man. The eight-chapter story includes his dialogue and journal card. Version-one and version-two saves preserve existing checkpoints, completions and bonus stickers.
- Generated and integrated 13 authored poses, six effects and three projectile sprites. The single rocket, popping firecracker, three-lane firework fan and close-range spear strike have fixed tells and vulnerable recovery. Exact built-in image prompts and extraction geometry are preserved in `source_art/Crackle_Production_Assets/`; all 23 runtime PNG/JSON outputs reproduced byte-for-byte in an independent rebuild. The original private drawing remains outside the repository.
- Dark lord's attack damage multiplier rose from 1.50 to 1.95, exactly **30%** before rounding. Faster pursuit, ranged attack selection and the warned full-height pillar counter distant/elevated shooters. Shorter hit stun and controller recovery reduce hesitation while preserving existing damage tells and invulnerability. A real held-bow scenario fired 19 arrows while Dark lord closed from 1,080 to 438.3 pixels and dealt 203 damage.
- Focused source verification passed **19 suites / 2,379 checks / zero failures**, including the full eight-fight authored-art journey with no retries. Crackle's 15-second pressure was between Green and Pac-Man. Inspected 26 native captures covering combat, authored effects, results, reduced motion, story dialogue and the eight-card journal. This is automated and visual verification; the new fights have not received family playtesting.
- Published **v0.7.10 / build 28** as the latest [GitHub release](https://github.com/manynames3/doodle-rumble/releases/tag/v0.7.10), with the [playable Universal Mac ZIP](https://github.com/manynames3/doodle-rumble/releases/download/v0.7.10/Doodle_Rumble_Mac_v0.7.10.zip) and matching source commit `feee642`. Local copies remain in `builds/mac-v0.7.10/`. Both architecture slices, strict ad-hoc signature verification, ZIP integrity and a 120-frame exported-app startup passed. The exact exported PCK passed **654 asset, story and boss checks / zero failures**. GitHub's uploaded asset digest matches the local SHA-256. See [TESTING_0_7_10.md](docs/TESTING_0_7_10.md). The app is not notarized.

## Local Fuse expansion (not yet released)

- Added **Fuse**, a missile-wielding stick-figure boss after H4CK3R and before Dark lord. The story now has seven chapters, with new dialogue, journal entry, fixed-aim missile volleys, a launcher bash and visible reload windows. Existing saves keep their old Dark lord checkpoint, completion and bonus stickers.
- Generated and integrated 13 authored poses, six effects and a separate missile. Original atlases, exact prompts and extraction geometry are preserved in `source_art/Fuse_Production_Assets/`; the three earlier concepts remain in `source_art/Fuse_Concept_Renderings/`. All 21 runtime PNG/JSON outputs reproduced byte-for-byte in an independent rebuild. The nine supplied packs remain unchanged.
- Focused source verification passed **16 suites / 2,076 checks / zero failures**, including the full seven-stage live-bot journey with no retries. Fuse's 25-second passive pressure measured 236 damage, between H4CK3R's 224 and Dark lord's 376. Native captures cover the missile warning, launch, reload, impact, results, reduced motion, seven-card journal and before/after dialogue. This is automated and visual verification; the new fight has not received family playtesting.
- Prepared the local **v0.7.9 / build 27** Universal Mac app and app-only ZIP in `builds/mac-v0.7.9/`. Both architecture slices, strict ad-hoc signature verification, archive integrity and a 120-frame exported-app startup passed. The exact exported PCK passed another **499 asset, story and Fuse combat checks / zero failures**. See [TESTING_0_7_9.md](docs/TESTING_0_7_9.md). The app is not notarized. No GitHub release was created.

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

## Earlier v0.7.7 Mac build and launch

- Earlier app: **v0.7.7 / build 25**, Universal arm64/x86_64, Godot 4.7.2 Compatibility renderer at `builds/mac-v0.7.7/Doodle Rumble.app`. The executable contains both architecture slices; strict local signature verification passed. Its embedded game pack boots headlessly for 120 frames and exits without errors.
- Public archives: `Doodle_Rumble_Mac_v0.7.7.zip` and `Doodle_Rumble_Project_v0.7.7.zip`, available from the [v0.7.7 GitHub release](https://github.com/manynames3/doodle-rumble/releases/tag/v0.7.7). The [v0.7.6 release](https://github.com/manynames3/doodle-rumble/releases/tag/v0.7.6) remains available as an earlier version.
- Launch the local build by double-clicking **Doodle Rumble.app** in the v0.7.7 folder. From source, open `game/project.godot` in Godot 4.7.2 and press F5.

## Known limits

- Photo cutouts remain a manual assisted workflow. Page-white cleanup does not find or separate the character automatically; children trace the six body parts. Overlapping or faint photos may still need adult help.

- This Mac has no Developer ID certificate. The app is ad-hoc signed and not notarized, so Gatekeeper may require **System Settings → Privacy & Security → Open Anyway** after transfer. This is not a notarized public storefront release.
- Intel execution, transfer to another Mac, physical controller assignment/disconnect, keyboard rollover, sleep/wake, and external speaker/headphone behavior were not verified here.
- The native performance check shows a single entry-frame spike even after selection warm-up. Steady frames in the measured custom-fighter match were below 10 ms at p95 on this M1; unusually detailed artwork and other Mac hardware still need measurement.
