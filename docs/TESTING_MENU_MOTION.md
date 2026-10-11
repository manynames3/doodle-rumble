# The Underline Heist — menu implementation and verification

Godot 4.7.2, 2026-10-11. Native Apple M4 Compatibility renderer. Release verification is recorded in [TESTING_0_7_12.md](TESTING_0_7_12.md).

## Implementation

`game/scripts/title_motion.gd` draws procedural hollow-headed Blue and Yellow with larger, consistent silhouettes, uneven overlapping ink contours, pupils/eyebrows, expressive poses and restrained handwritten reaction marks. A 2.6-second greeting leads into an 11.9-second gag: Blue pulls a star from the selection underline, skates into a faceplant, Yellow catches it and celebrates too early, Blue intercepts the celebratory toss, Yellow discovers its empty hands, and Blue gives a sheepish grin before returning the star. Focus changes adapt the choreography safely. Blue retreats to his original perch for the interception; the main reaction faces occupy separate label gaps.

`game/scripts/title_menu.gd` adds one input-transparent motion child before the hint and buttons and routes existing focus events to it. Button positions, hitboxes, callbacks, sounds and focus neighbors are preserved. The original illustrated poster remains in place. Gameplay, progression, family saves, combat and racing were not modified. There are no new dependencies or raster assets.

The animation owns no timers or tweens. Cosmetic delta is capped at 0.05 seconds; particles have 28 fixed slots and rings have three. Reduced motion presents a static punchline, retains immediate selection and avoids continuous redraw. The scene owns all motion state, so leaving the menu removes it.

## Verification

- Source import: passed without errors or warnings.
- Existing source menu suite: 168 checks / zero failures.
- Native motion fixture: 42 semantic checks / 612 saved captures / zero failures.
- Actual 854×480 root Window: two checks / one capture / zero failures; keep-aspect content rounds to 853×480.
- Independent current-source and native art review: no release blockers.
- Exact exported pack: 168 menu checks, five live game checks and two native small-window checks / zero failures.

The native fixture covers the greeting and two complete loops, stable button positions, all six focus targets, left/right wrap, activation through actual GUI action events, mouse hover, 90 rapid focus changes, a complete mirrored capture, byte-identical reduced-motion renders over 90 frames, immediate focus in reduced motion, Story Mode activation without animation delay, menu disposal on navigation, and 20 reentries with stable child/scene-node counts. Native images were inspected for the principal comedy poses, readable labels, clean wheels, mirrored staging and actual small-window readability.

The preview-first refinement was shown before packaging. Claude wrote the refinement, then hit its subscription quota before its handoff; Codex completed the geometry adjustment and validation. Initial capture/profile shutdown warned about two WAV playback references. Verbose diagnosis identified the audio mix thread's deferred release, not leaked motion nodes. QA tools now wait 150 ms after stopping sound before exiting; final capture/profile runs completed without warnings. Production audio was not changed.

## Native performance

1,620 sampled native frames after 60 warm-up frames, hidden 1280×720 SubViewport, vsync disabled, Apple M4 Compatibility renderer. Cosmetic time advances manually by 1/60 second per render while automatic motion processing is disabled. The existing separate live preview was left open to preserve the user's running instance.

| Measurement | Milliseconds |
| --- | ---: |
| Frame mean | 6.902 |
| Frame median | 6.062 |
| Frame p95 | 11.675 |
| Frame maximum | 45.358 |
| Cosmetic update mean | 0.0226 |
| Cosmetic update p95 | 0.037 |
| Cosmetic update maximum | 0.149 |

Frame cost includes scheduling and drawing; update cost covers only `_process`. These are local measurements with another preview open, not a controlled comparison with the earlier design or an FPS guarantee. Physical controllers, Intel execution, a second Mac, and family/virality playtesting were not performed for this menu change.

## Reproduction

Run from the repository root with Godot 4.7.2 as `godot`:

```sh
godot --headless --editor --path game --import --quit
godot --headless --fixed-fps 60 --path game --script res://tests/test_menus.gd -- --isolated-qa
godot --fixed-fps 60 --path game --script res://tools/capture_title_motion.gd -- --isolated-qa --capture-dir=/tmp/doodle-menu-qa
godot --fixed-fps 60 --path game --script res://tools/capture_title_motion.gd -- --isolated-qa --small-window-only --capture-dir=/tmp/doodle-menu-qa
godot --path game --disable-vsync --script res://tools/profile_title_motion.gd -- --isolated-qa
godot --headless --path game --export-release macOS
```

All game QA uses isolated preferences. Fixed-fps captures are native render evidence with deterministic cosmetic time, not family playtest recordings. Local loop GIFs remain under ignored `docs/test-results/menu-motion-refined/`; the curated native image is [17-menu-heist.png](screenshots/17-menu-heist.png).
