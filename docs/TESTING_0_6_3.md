# Doodle Rumble v0.6.3 verification

Tested on Apple M1, macOS, standard Godot 4.7.2. All QA used isolated preferences.

## Changes and checks

H4CK3R's size multiplier is 1.25 relative to v0.6.2. Tests check the actual body, rig and hurtbox scale; a native main-scene capture checks HUD/floor clearance. Dark lord retains its existing 1.5 size multiplier.

Hard hazard intervals and their minimum interval are divided by 1.30. Every story-stage base interval is checked against v0.6.2 for the exact scheduling-rate increase. Warnings are unchanged; one active zone still prevents overlapping damage regions. Actual optional event counts can be lower when a boss signature already occupies the zone.

A shared 1.25 damage multiplier covers H4CK3R and Dark lord. Melee, moving specials, boss projectiles and boss-owned marks are checked, including stable projectile damage across 30/60/120 Hz sampling, one-hit consumption, reflection and unowned hazard damage. Whole-number damage rounds upward (for example, 26 becomes 33; 32 becomes 40).

All 1,885 checks across 22 suites passed against both source and the exported Mac PCK. The real-input journey bot completes six stages and three local matches in 18 total rounds with no retries. It was updated to move inside Orange's actual attack reach and dodge H4CK3R's announced strike; no boss health or combat behavior was weakened for the test.

## Limits

The Universal app is locally ad-hoc signed, not notarized. Physical controllers, Intel execution, keyboard rollover, transferred launch and subjective difficulty with children still need device/family testing.

The Universal Mac export passed strict deep signature verification and booted headlessly for 120 frames. Native captures and source/packaged result summaries are in test-results/v063/.
