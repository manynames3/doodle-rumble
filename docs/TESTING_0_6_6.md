# Doodle Rumble v0.6.6 verification

Tested on Apple M1, macOS, with standard Godot 4.7.2 and the Compatibility renderer. Automated runs use isolated preferences and silent audio. Native captures use a hidden 1280×720 rendering viewport so they do not take focus from a player's game.

## Ambient arena motion

The arena ambience layer is deterministic immediate-mode drawing behind the platforms and fighters. It does not own collision, damage, hazard timing or combat clocks. Reduced motion freezes the layer at its neutral pose.

- **Arcade Afterglow:** prize-machine plush doodles bob, blink and lean toward the match; the claw makes a slow pass while marquee bulbs and the distant wheel twinkle.
- **Desktop Dojo:** both monitors reveal typed handwritten lines, blinking cursors, scanlines and incrementally drawn doodles; a loose sheet drifts across the room.
- **Block Quarry:** the main crane trolley sways and lifts its cargo; three birds cycle through flight, a short rest on the ledges and departure. Waterfall streaks remain secondary.
- **Glitch Core:** the central monitor receives moving scan bars and broken status text, while the neon sign flickers between “GLITCH” and “GL1TCH” and the portal pixels orbit softly.
- **Paper Canopy:** hanging jars breathe with warm light, paper cranes bob and flap, and leaves/plants lean during occasional gusts with small drifting wind lines.

Native captures in `test-results/v066/arena-ambience/` include a rest frame and a six-second motion frame for each arena. Pixel-difference checks found visible changes in every pair while keeping changes confined to the scenery layer; visual review confirmed the fighters, health HUD and platform tops remain readable.

## Automated suites and export

The 22 source suites passed **1,907 checks** with zero failures. The exported Mac PCK was exercised with the same suites and **1,907 checks** with zero failures. Results are in `test-results/v066/source-logs/results.json` and `test-results/v066/packaged-logs/results.json`.

The Universal Mac app is locally ad-hoc signed; strict deep signature verification passed. The exported application was launched headlessly for 120 frames. ZIP integrity and a clean extracted-copy launch were checked before delivery.

## Limits

The app is not notarized. Physical gamepad input, Intel Mac execution, keyboard rollover, transferred first launch and family playtesting have not been performed. Ambient animation was reviewed through native still captures; continuous motion and perceived contrast should receive a final listening/playing pass on the target display with motion settings checked.
