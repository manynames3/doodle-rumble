# Doodle Rumble

**Small sticks. Big imaginations. Draw, fight, repeat.**

Doodle Rumble is a hand-drawn 2D arcade fighter for macOS, with an imaginative racing side game. Six hollow-headed doodles throw oversized weapons around a living computer desk while a funny six-battle story climbs from a gentle first fight to Pac-Man, H4CK3R and the Dark lord.

![Doodle Rumble title menu](docs/screenshots/01-title-menu.png)

## What is in the game

- Six playable fighters: Orange, Red, Green, Blue, Purple and Yellow.
- Distinct basic attacks and specials, including spin arcs, hammer quakes, pixel slashes, block blasts, signal shots and swarm summons.
- Six-stage story ladder: **Blue → Red → Green → Pac-Man → H4CK3R → Dark lord**.
- Story, Quick Match and local 2P Battle, with fighter selection and a separate readable stage-selection page.
- Chill Doodles, Spicy Scribbles and Doodle Mayhem difficulty choices. Computer opponents attack more often and hazards become more active as the challenge rises.
- Six illustrated arenas with optional hazards, reachable platforms and animated scenery.
- 60-second rounds, best-of-three scoring, damage numbers, cooldown indicators, rematches and celebratory round results.
- Doodle Rally, the separate imaginative racing game, with its own cars, courses, saves and music while sharing settings and controls.

## Screenshots

The gallery contains native 1280×720 captures from the running game. More context is in [`docs/screenshots/README.md`](docs/screenshots/README.md).

| Fighter selection | Stage selection |
| --- | --- |
| ![Six fighter selection cards](docs/screenshots/02-fighter-select.png) | ![Six readable stage cards](docs/screenshots/03-stage-select.png) |

| Desktop Dojo combat | Round result |
| --- | --- |
| ![Orange versus Blue in Desktop Dojo](docs/screenshots/04-combat-desktop-dojo.png) | ![Winner celebration and downed loser](docs/screenshots/05-round-result.png) |

| Moving desk scenery | Moving quarry and glitch scenery |
| --- | --- |
| ![Desktop Dojo screens typing and drawing](docs/screenshots/06-desktop-dojo-motion.png) | ![Block Quarry crane and Glitch Core ambience](docs/screenshots/07-block-quarry-motion.png) · ![Glitch Core motion](docs/screenshots/08-glitch-core-motion.png) |

## Play on a Mac

The public repository contains the complete Godot source. Generated `.app` bundles and ZIP archives stay out of Git history so the repository remains easy to clone; use the v0.6.7 Mac deliverable from the project handoff for the prebuilt app, or export your own build with [docs/MAC_SETUP.md](docs/MAC_SETUP.md).

To run a prebuilt app, open the extracted `Doodle_Rumble_Mac_v0.6.7` folder and double-click **Doodle Rumble.app**. The BenJam Games logo appears briefly, then the title menu opens. Choose **Story Mode**, **Quick Match**, **2P Battle** or **Doodle Rally**. Orange and a gentle opponent are ready by default.

The build is a Universal arm64/x86_64 app, locally ad-hoc signed and not Apple-notarized. macOS may require **System Settings → Privacy & Security → Open Anyway** after a transfer.

## Run from source

1. Install standard **Godot 4.7.2**; the .NET edition is unnecessary.
2. Import `game/project.godot` in the Godot Project Manager.
3. Press **F6** for the current scene or **F5** to run the project.

The project has no add-ons, external accounts or runtime package dependencies. `game/` contains the playable source, scenes and runtime assets. Build/export notes are in [`docs/MAC_SETUP.md`](docs/MAC_SETUP.md).

## Controls

| Action | Player 1 | Player 2 |
| --- | --- | --- |
| Move | A / D | Left / Right |
| Jump | W or Space | Up |
| Attack | F | K |
| Special | G | L |
| Dodge / Purple guard | E | J |
| Pause | Esc | Esc |

Settings supports remapping, available controllers, music/effects volume, reduced motion and hold-to-attack. Gamepads use the left stick/D-pad, south button to jump, west to attack, east to special, left shoulder to dodge/guard and Start to pause.

## Tech stack

| Area | Implementation |
| --- | --- |
| Engine | Godot 4.7.2, GDScript, Compatibility renderer |
| Gameplay | Fixed 60 Hz physics, reusable fighter/weapon data, deterministic hit phases, recovery protection and shared AI controllers |
| Rendering | 2D `Node2D`/`CanvasItem` drawing, procedural ink outlines, layered PNG arena paintings, particles, glows, shadows and animated UI |
| Audio | Original synthesized WAV battle loops and sound effects, context crossfades, separate story/racing music and shared volume settings |
| Ending | Godot-authored storyboard with Ogg Theora/Vorbis playback |
| Platform | macOS Universal export for Apple Silicon and Intel |
| QA | Godot GDScript suites, isolated preference profiles, native 1280×720 captures and exported-PCK checks |

## Validation

The v0.6.7 validation archive records **22 source suites / 1,907 checks / 0 failures** and the same **22 packaged-PCK suites / 1,907 checks / 0 failures**. It also includes native title/PCK captures, code-sign verification, ZIP integrity checks and an extracted-app launch smoke test.

See [`BUILD_STATUS.md`](BUILD_STATUS.md) for the current feature and limitation list and [`docs/TESTING_0_6_7.md`](docs/TESTING_0_6_7.md) for the exact evidence. Physical controller behavior, Intel execution, transferred first launch, audio hardware and family playtesting still need verification on those devices.

## Repository map

```text
game/                 Godot project, scripts, scenes, assets and tests
docs/screenshots/     Curated public gameplay gallery
docs/                 Build, testing, audio, ending and provenance notes
```

Supplied family/reference artwork and planning files are intentionally excluded from the public repository. Runtime art is included, and its origins plus third-party notices are documented in [`docs/ASSET_PROVENANCE.md`](docs/ASSET_PROVENANCE.md). The Doodle Rumble name, characters, art, audio and other creative assets remain reserved; this public repository is provided for viewing and play unless a separate license is granted.
