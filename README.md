# Doodle Rumble

**Small sticks. Big imaginations. Draw, fight, repeat.**

Doodle Rumble is a hand-drawn 2D arcade fighter for macOS, with an imaginative racing side game. Six hollow-headed doodles throw oversized weapons around a living computer desk while a funny six-battle story climbs from a gentle first fight to Pac-Man, H4CK3R and the Dark lord.

![Doodle Rumble title menu](docs/screenshots/01-title-menu.png)

## From my kids' drawing to a playable world

Doodle Rumble started with a drawing my kids made: little stick figures with hollow heads, huge tools, and enough attitude to look as if they were already arguing over who won. I wanted to keep that energy, not tidy it away. The first question was simple: what if these doodles could climb off the page and fight inside the computer they were drawn on?

I built the answer in Godot. The first Mac prototype proved the basics with a desk arena, movement, attacks, health and rematches. Then the kids' characters became a six-fighter cast with distinct specials. The desk became one stop in a bigger, sillier journey through quarries, paper worlds, arcades and a glitching computer core. The story now builds toward Pac-Man, H4CK3R and Dark lord, with each match raising the challenge and giving the doodles another reason to show off.

The art has grown alongside the game. Illustrated backgrounds set the scene; ink-style HUD and oversized effects make the action feel like the drawing is fighting back. The latest character pass uses **individual transparent pose and effect sprites** for all six fighters and three bosses. A small importer trims the source images' transparent safety borders, creates lighter runtime copies, and records each pose's pivot so the characters still meet the floor and their existing hitboxes. These are separate PNGs, rather than a conventional sprite sheet. Godot's fixed-step combat remains independent of the art. The original high-resolution pack images are preserved under `source_art/`.

## How it grew

| When | What changed |
| --- | --- |
| First playable build | Four fighters, a desktop arena, solo play, training, local battles and quick rematches established the game loop. |
| Cast and visual identity | Purple and Yellow joined Orange, Red, Green and Blue. The title poster, hand-drawn HUD, larger attacks and illustrated arenas gave the game its sketchbook-meets-computer look. |
| A journey worth finishing | The six-stage Save Star Saga added Pac-Man, H4CK3R and Dark lord, rising difficulty, hazards, new worlds, stage-specific music, a short ending and small jokes between fights. Doodle Rally became a separate racing side game. |
| Bringing the drawings closer | Nine transparent art packs now animate the playable cast and bosses in selection, story scenes and combat. The latest pass adds moving idle/run poses, clearer boss attack releases, better-fitting selection previews and visible round-result performances. |

The best design test is still the original one: does it feel like the kids' drawing came alive, and do they want another round?

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
| ![Orange versus Blue in Desktop Dojo](docs/screenshots/04-combat-desktop-dojo.png) | ![Dark lord celebrating while Red lies down with spinning stars](docs/screenshots/05-round-result.png) |

| Moving desk scenery | Moving quarry and glitch scenery |
| --- | --- |
| ![Desktop Dojo screens typing and drawing](docs/screenshots/06-desktop-dojo-motion.png) | ![Block Quarry crane and Glitch Core ambience](docs/screenshots/07-block-quarry-motion.png) · ![Glitch Core motion](docs/screenshots/08-glitch-core-motion.png) |

### The transparent character art pass

These are native captures from the running Godot project, after the nine new packs were connected to menus and fights.

| Fighter selection | Desktop Dojo fight |
| --- | --- |
| ![Transparent Orange, Red, Green, Blue, Purple and Yellow art in character selection](docs/screenshots/09-transparent-fighter-selection.png) | ![Purple's packed guard facing Red's hammer in Desktop Dojo](docs/screenshots/10-transparent-fighter-combat.png) |

| Pac-Man | H4CK3R | Dark lord |
| --- | --- | --- |
| ![Pac-Man in Arcade Afterglow](docs/screenshots/13-pac-man-pack.png) | ![H4CK3R in Neon Switchyard](docs/screenshots/12-h4ck3r-pack.png) | ![Dark lord in Glitch Core](docs/screenshots/11-dark-lord-pack.png) |

## Play on a Mac

The public repository contains the complete Godot source. Generated `.app` bundles and ZIP archives stay out of Git history; download the [v0.6.9 release](https://github.com/manynames3/doodle-rumble/releases/tag/v0.6.9) for the prebuilt Mac app or complete Godot project, or export your own build with [docs/RELEASE_BUILD.md](docs/RELEASE_BUILD.md).

To run a prebuilt app, open the extracted `Doodle_Rumble_Mac_v0.6.9` folder and double-click **Doodle Rumble.app**. The BenJam Games logo appears briefly, then the title menu opens. Choose **Story Mode**, **Quick Match**, **2P Battle** or **Doodle Rally**. Orange and a gentle opponent are ready by default.

The build is a Universal arm64/x86_64 app, locally ad-hoc signed and not Apple-notarized. macOS may require **System Settings → Privacy & Security → Open Anyway** after a transfer.

## Run from source

1. Install standard **Godot 4.7.2**; the .NET edition is unnecessary.
2. Import `game/project.godot` in the Godot Project Manager.
3. Press **F6** for the current scene or **F5** to run the project.

The project has no add-ons, external accounts or runtime package dependencies. `game/` contains the playable source, scenes and runtime assets. Build/export notes are in [`docs/RELEASE_BUILD.md`](docs/RELEASE_BUILD.md).

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
| Rendering | 2D `Node2D`/`CanvasItem` drawing, individual transparent RGBA pose/effect sprites with measured pivots, procedural ink/VFX fallbacks, layered PNG arena paintings, glows, shadows and animated UI |
| Asset pipeline | Pillow build script preserves 306 original PNGs outside Godot and creates 155 trimmed runtime copies with per-pose pivot metadata; no Python dependency is needed to play |
| Audio | Original synthesized WAV battle loops and sound effects, context crossfades, separate story/racing music and shared volume settings |
| Ending | Godot-authored storyboard with Ogg Theora/Vorbis playback |
| Platform | macOS Universal export for Apple Silicon and Intel |
| QA | Godot GDScript suites, isolated preference profiles, native 1280×720 captures and exported-PCK checks |

## Validation

The v0.6.9 validation archive records **24 source suites / 2,251 checks / 0 failures** and the same **24 packaged-PCK suites / 2,251 checks / 0 failures**. It also includes native menu/combat/boss/result captures, a four-point Godot playback check of the rebuilt ending, code-sign verification and Mac app launch smoke testing.

See [`BUILD_STATUS.md`](BUILD_STATUS.md) for the current feature and limitation list and [`docs/TESTING_0_6_9.md`](docs/TESTING_0_6_9.md) for the exact evidence. Physical controller behavior, Intel execution, transferred first launch, audio hardware and family playtesting still need verification on those devices.

## Repository map

```text
game/                 Godot project, scripts, scenes, assets and tests
source_art/           Untouched originals from all nine transparent character packs
docs/screenshots/     Curated public gameplay gallery
docs/                 Build, testing, audio, ending and provenance notes
```

The original private family drawing and planning files are intentionally excluded from the public repository. The nine owner-supplied transparent **production** packs are included, with their original PNGs preserved under `source_art/` and their use documented in [`docs/CHARACTER_PACK_MAPPING.md`](docs/CHARACTER_PACK_MAPPING.md). Origins plus third-party notices are in [`docs/ASSET_PROVENANCE.md`](docs/ASSET_PROVENANCE.md). The Doodle Rumble name, characters, art, audio and other creative assets remain reserved; this public repository is provided for viewing and play unless a separate license is granted.
