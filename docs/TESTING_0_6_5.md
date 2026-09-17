# Doodle Rumble v0.6.5 verification

Tested on Apple M1, macOS, with standard Godot 4.7.2 and the Compatibility renderer. Automated runs use isolated preferences and silent audio. Native captures use a hidden rendering viewport so they do not take focus from a player's game.

## Selection and story presentation

The fighter showcase now grounds the real preview rig with a small dark ink contact shadow. The bright per-fighter floor rule that crossed the feet and the “SPECIAL PREVIEW” footer has been removed. Native 1280×720 selection captures include easy and hard fighter pages plus Green/Yellow previews; the cards were checked for complete silhouettes, weapon bounds and clear footer text.

Story scenes select a dedicated looped paper-and-desktop music bed. Each scene opening, page/line, character beat, and close uses a short generated Foley cue chosen from page turn, pencil, bonk, magic, glitch, chomp, swish and spark sounds. Next, skip, hover and close controls also use story cues. The audio suite checks that every story cue is a bounded mono WAV, that the story bed loops for more than ten seconds, and that story↔racing/title crossfades release their old streams correctly.

## Automated suites and export

The 22 source suites passed **1,907 checks** with zero failures. The exported Mac PCK was exercised with the same suites and **1,907 checks** with zero failures. Results are in `test-results/v065/source-logs/results.json` and `test-results/v065/packaged-logs/results.json`.

The Universal Mac app is locally ad-hoc signed; strict deep signature verification passed. The exported application was launched headlessly for 120 frames. ZIP integrity and a clean extracted-copy launch were checked before delivery.

## Limits

The app is not notarized. Physical gamepad input, Intel Mac execution, keyboard rollover, transferred first launch and family playtesting have not been performed. Automated audio checks validate generated stream structure and routing; speakers and mix balance still need a listening pass on the target Mac.
