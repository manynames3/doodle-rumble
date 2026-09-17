# Build status — Doodle Rumble v0.6.7

Updated 2026-09-17. Standard Godot 4.7.2 / GDScript.

## Completed

- Round results keep the same arena camera and the actual gameplay-size fighters. The larger stand-in portraits and result ribbon scale animation are gone.
- The winner hops, waves and shows off with character-specific weapon poses and small glints. The loser lies on the floor with four stars orbiting above their hollow head, including when a round ends by the clock rather than a knockout. Bosses have result poses too.
- The title poster now has a clean lower-right corner: the old “STICKS FIGHT FOREVER / INSERT COIN” arcade copy was removed from the source texture while the title, cast, lighting and rubble remain intact.
- Reduced motion holds the winner and stars in still, readable poses. Rematch and next-round resets clear the result state.
- Story, quick match, local battles, six playable fighters, the six-stage journey, hazards, Doodle Rally and saves remain available.
- Character showcase cards use a quiet ink floor and per-fighter contact shadow, so the special preview is no longer crossed by a bright horizontal color line at the feet.
- Story scenes have their own 12-second paper-desk music bed and contextual Foley: page turns, pencil scratches, bonks, swishes, sparks, chomps, glitches, magic stingers and softer next/skip/hover/close cues. Story audio respects the shared volume and reduced-motion settings.
- Arena ambience now has deterministic, cosmetic motion for every requested story world: blinking/bobbing arcade prizes and claw, typed and drawn Desktop Dojo monitors, a lifting/swaying quarry crane with fly/perch/depart bird cycles, glitching neon signs and screens, and Paper Canopy lantern twinkles, paper-crane wing motion, leaves and plants that lean during passing gusts. The layer remains behind platforms and fighters and never changes collision, damage or hazard timing.

## Verification

The complete source and exported Mac gameplay suites are recorded in [TESTING_0_6_7.md](docs/TESTING_0_6_7.md). Native 1280×720 captures verify the cleaned poster as an asset, through the title menu, and directly from the exported PCK. The prior v0.6.6 archive retains the arena rest/motion and selection captures. KO, timeout, tie, next round and rematch paths were exercised. The Mac build is locally ad-hoc signed and its signature was checked.

## Remaining limits

The app is not Apple-notarized. Physical controllers, Intel execution, transferred first launch, keyboard rollover and family playtesting remain outstanding. Celebration animation is visual only and does not affect damage or scoring.
