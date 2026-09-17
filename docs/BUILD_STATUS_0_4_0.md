# Build status — Doodle Rumble v0.4.0

Updated 2026-09-13. Standard Godot 4.7.2, GDScript, Compatibility renderer. Complete source and Universal Mac export included.

## Completed

- Six selectable fighters: Orange, Red, Green, Blue, Purple and Yellow; illustrated special-attack selection cards and saved preferences.
- New tactical moves: directional dodge, a precisely timed evasion that powers the next basic attack, and six airborne attack variants. Red drives targets down, Blue launches them up, Green lunges, Orange sweeps both sides, Purple shoots at jump height, and Yellow dives with a staff. Controls remain shared; Dodge is E/J or gamepad left shoulder and can be remapped.
- Distinct arena layouts and interactions: Desktop springboard, Quarry bridge that cracks and reforms, Glitch jump portals. The giant final boss has three reachable retreat ledges. Continuous safe floors and illustrated backgrounds preserved.
- Six-stage story: **Blue → Red → Green → Pac-Man → H4CK3R → Dark lord**. Pac-Man has four stronger attack patterns; H4CK3R has a monitor, cyan camera eye, cables, tablet and five patterns. Dark lord is 50% larger, with ragged black/purple art, five patterns and camera helpers. Each story stage has different music.
- Hazards default ON, with optional extra hazards controlled in selection. Cursor stamps, pink erasers, ink eruptions, beams and Dark rifts have visible warnings and limited hits. Boss signature attacks remain part of their fights.
- Handwritten title footer with Story Mode, Quick Match, 2P Battle, Doodle Rally, Settings and Quit; fighter selection in all three fighting modes, Practice inside Quick Match. Damage numbers, ink HUD, individual stances, marker bodies, oversized effects, grounded contact shadows and animation timed to attack windows.
- 90-second rounds, best of three, immediate rematches, pause, audio settings, reduced motion, controller assignment and remapping. Existing racing features and racing-specific code remain unchanged.

## Verified

**1,202 source checks and 949 exported-resource checks passed**, with clean final logs. Normal input bots completed the six-stage story and three local matches (18 combat rounds): Orange through H4CK3R, then Purple against Dark lord. The new dodge helped the bot beat Pac-Man. No forced health damage, shortened round timers or altered AI in these live matches; separate scoring fixtures do set health to isolate branches.

Actual Godot renders on Apple M1 were inspected for menus, all arenas, bosses, new aerial moves, dodge/counter, hazards and victory. A muted 12-second boss-render sample measured **10.98 ms mean / 16.65 ms p95** frame intervals; this one offscreen sample is not a hardware guarantee. The Universal arm64/x86_64 app passes strict local signature verification and a headless native launch/exit smoke check with isolated preferences.

## Limits and next steps

The newest standalone app has not been manually played; source rendering and exported resources were tested while the user's older running app remained untouched. Physical gamepads, Intel execution, first launch after transfer, keyboard rollover, sleep/wake, long sessions and family difficulty/fun still need verification. The build is ad-hoc signed, not Apple-notarized.

Story progress is session-only. Purple's shield is decorative. The game is closer to the poster but is not a finished commercial 10/10; human playtesting and finer animation/balance work remain. Racing stays on the backburner.

[Launch and controls](README.md) · [Validation details](docs/TESTING.md) · [Candid review](docs/DEVELOPER_AND_MARKET_REVIEW.md)
