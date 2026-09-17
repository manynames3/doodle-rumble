# Doodle Rumble v0.6.2 verification

Tested 2026-09-14 on Apple M1 with standard Godot 4.7.2 and the Compatibility renderer. Every QA run used isolated preferences. The player's game process and save files were left alone.

## Source and exported game

All **22 suites / 1,867 checks** passed from the editable source. The same **22 suites / 1,867 checks** passed while loading scripts and assets from the exported Mac PCK. The runner rejected engine script errors and warnings, and both result files are in [test-results/v062](test-results/v062/). The Mac executable itself also ran headlessly for 120 frames and exited successfully. Strict deep local signature verification passed; `file` identified both arm64 and x86_64 slices.

The input-driven game suite completed the six-stage story and three local matches in **18 rounds, no retries**. Racing regression completed **six two-lap races**; racing code and assets were unchanged. Story profile checks include legacy saves containing the retired badge choice, checkpoint restore across a process restart, atomic backup recovery, and bonus-sticker persistence.

## Boss and difficulty evidence

H4CK3R now cycles seven warned patterns, including the checksum fan and firewall. Checks verify all seven actually release, the volley travels in the committed direction, the cursor lunge cannot turn after its tell, firewall damage has a full harmless warning and one-hit cap, projectile damage is independent of render sampling, and interrupting a cast still grants recovery. The firewall uses the existing single-zone queue so a stage hazard cannot hide its warning.

In identical 40-second stationary-target simulations with optional arena hazards disabled, Pac-Man dealt **146**, H4CK3R **279**, and Dark lord **359** damage. The scripted moving story player finished Pac-Man with **38 HP** and H4CK3R with **28 HP**, then cleared the final stage. This supports the requested boss ordering for the scripted routes; human win rates remain unmeasured.

Compared with the shipped v0.6.1 factors, Medium and Hard have **1.20× / 1.50× attack-readiness and optional-hazard rates**. Their warning times were not shortened. A 3.6-second hazard-interval floor and one active zone remain. With actual fixed attack windups and warnings, an ordinary AI issued **22 / 27 / 36** attacks over 45 seconds on Easy / Medium / Hard; its v0.6.1 results were **22 / 24 / 28**. This is evidence of stronger pressure, while avoiding a misleading claim that landed-hit rate or player difficulty increases by an exact percentage.

## Native visual checks

Hidden native 1280×720 SubViewport captures used the actual main scene, arena and HUD. The three boss fights and their cues were inspected in [Pac-Man charge](test-results/v062/match_pacman_charge.png), [H4CK3R checksum](test-results/v062/match_hacker_checksum.png), [H4CK3R firewall](test-results/v062/match_hacker_firewall.png), [Dark lord reaper](test-results/v062/match_darklord_reaper.png) and [Dark lord camera mark](test-results/v062/match_darklord_camera.png). The boss details, effects and warning regions remained readable without HUD or floor clipping. H4CK3R's reduced-motion firewall panel retained its mark. These are staged cast frames in a live Godot render, complemented by the input-driven combat tests.

The revised story journal was also rendered from the **exported PCK** with completed and empty progress; [completed journal](test-results/v062/Story_progress.png) has no badge picker or win-screen badge prompt. [Quick Match stage page](test-results/v062/Stages_quick.png) still presents large arena cards.

## Reproduce

Import `game/project.godot` in Godot 4.7.2, or run:

```sh
python3 game/tools/run_tests.py --godot /absolute/path/to/Godot --logs test-logs
godot --headless --fixed-fps 60 --main-pack '/absolute/path/to/Doodle Rumble.pck' --script res://tests/test_boss_update.gd -- --isolated-qa --silent-qa
```

The Mac app is locally ad-hoc signed, not Apple-notarized. Intel execution, physical controllers, keyboard rollover, transferred first launch, long play sessions and family difficulty/fun remain unverified on their respective devices. The painted title poster remains more detailed than the procedural game actors.
