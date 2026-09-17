# Doodle Rumble — v0.4.0

A playable Mac arcade fighter and a doodle racing detour, built from the children's drawings. Six substantial, animated ink fighters swing oversized tools through illustrated sketchbook worlds; Doodle Rally turns spiky little cars and winding pencil roads into a playable race.

## Play on Mac

1. Quit any earlier copy of the game. Unzip **Doodle_Rumble_Mac.zip** and double-click **Doodle Rumble.app** inside. In the full working folder, the v0.4.0 app is at `builds/mac-v0.4.0/Doodle Rumble.app`.
2. Choose **Story Mode**, pick your fighter, then **LET'S RUMBLE**. The six-stage journey starts against a very easy opponent; a fresh profile selects Orange.
3. **Quick Match** and **2P Battle** also open fighter selection. **Doodle Rally**, **Settings**, and **Quit** complete the six-option title menu. Practice is available from Quick Match selection.

The Mac export targets both Apple Silicon and Intel and uses a local ad-hoc signature. It is **not notarized by Apple**. After downloading or transferring it, macOS may require **System Settings → Privacy & Security → Open Anyway**. The v0.4.0 source and exported game pack were checked on Apple M1; the release app has not been manually played. See [BUILD_STATUS.md](BUILD_STATUS.md) for current verification and remaining hardware checks.

**Doodle_Rumble_Project.zip** contains the complete source, assets, references, docs and screenshots, without the Mac app or Godot's generated cache. To run the source, install **standard Godot 4.7.2** for macOS; the .NET edition is unnecessary. In Godot's project manager, choose **Import**, select `game/project.godot`, open the project, then press **F5**. No add-ons or external services are required.

To export again, install the matching 4.7.2 export templates through **Editor → Manage Export Templates**, then use **Project → Export → macOS → Export Project**. The supplied preset builds a Universal app; choose an output ending in `.app`. Export credentials and signing identities are not required for the local ad-hoc build.

## Fighting controls

All fighters use the same controls. Keyboard bindings can be changed in **Settings**.

| Action | Player 1 | Player 2 |
| --- | --- | --- |
| Move | A / D | Left / Right arrows |
| Jump | W or Space | Up arrow |
| Basic attack | F | K |
| Special | G | L |
| Dodge / counter setup | E | J |
| Pause | Esc | Esc |

Press jump and basic attack in the air for a fighter-specific move: Orange sweeps with the fork, Red drops the hammer, Green cuts diagonally, Blue uppercuts with the pickaxe, Purple fires an aimed arrow, and Yellow dives with the staff. Hold attack for repeat swings; specials refill automatically. **F11** switches fullscreen/windowed; Macs with media-key defaults may need **Fn–F11**.

Gamepads use the left stick or D-pad to move, bottom/south button to jump, left/west button to attack, right/east button for the special, left shoulder to dodge, and Start to pause. Settings can assign two detected controllers independently. Physical controller hardware still needs verification. Existing saved key layouts keep their bindings; the game assigns each new dodge action an unused key, with E/J as defaults on a fresh layout.

A dodge is a 0.32-second sidestep with protection from 0.05 to 0.21 seconds and a 1.15-second cooldown. If it actually avoids a hit, your next basic attack within 2.5 seconds gains 25% damage (rounded up to a whole point). Specials do not receive this bonus.

## Fighting modes and characters

- **Orange:** pitchfork and a broad spin. **Red:** giant hammer and a ground wave. **Green:** pixel sword and a dash slash. **Blue:** pickaxe and a flying block fragment.
- **Purple:** bow arrows and a long-range **Signal shot**. **Yellow:** quick staff swings and **Swarm summon**, sending three little doodle helpers forward together. Each summon lands one hit. Both are available immediately in every fighting mode and use the same controls as the original four. Purple’s shield is part of the artwork, not a separate blocking control.
- **Quick Match**, **Practice**, and **2P Battle** use Desktop Dojo, Block Quarry, or Glitch Core. Training has no time limit and refills the passive opponent after a knockout.
- **Story Mode:** Blue (very easy) → Red (easy) → Green (medium) → **Pac-Man** (hard) → **H4CK3R** (very hard) → **Dark lord** (final boss). Each stage increases opponent pressure. Early rivals react sooner, pursue faster, recover faster, and use specials more often. Pac-Man has 150 health and four warned patterns: bite, charged rush, pellet fan and leap chomp. H4CK3R has 190 health, a cyan camera-monitor rig with lens, cables and tablet, and five patterns: cursor strike, packet blast, cursor stamp, ink eruption and eraser drop. The 50% larger Dark lord has 240 health, a larger ragged black scythe, and five patterns: reaper sweep, ground wave, void orbs, rift and camera marks.
- Win two rounds to advance. Losing allows unlimited retries of the current stage. Changing fighters during a journey preserves the stage you have earned. **Story Mode** on the title selects a fighter for a new journey; current journey progress lasts for the app session. Defeating the final Dark lord unlocks Rainbow and Sparkle victory effects in Settings. All fighters start each round at full health.
- Battles have 90-second rounds and require two round wins. Timeouts compare the percentage of health remaining. Ties and double knockouts replay without awarding a win. Continue into the next round or rematch immediately.
- Extra marked hazards are **on by default** and can be switched off in selection; the bosses' own warned patterns still run. Cursor stamps, falling erasers, ink eruptions and camera beams have warning regions and one hit per event. Arena boundaries and a continuous floor keep play on screen. Each arena has a different reachable platform route and a visible optional tactic: jump from the Desktop eraser pad for extra height, cross Quarry's loose bridge before it crumbles and reforms over the safe floor, or press jump on either Glitch floor panel to teleport to a checked exit. The Dark lord's arena keeps three one-way retreat ledges while its portal panels are inactive.

## Doodle Rally

Racing is preserved from the previous build. Further racing changes are on the backburner until requested.

Choose **Dragon Wagon**, **Rocket Bug**, or **Cloud Cruiser**, then paint it Tangerine, Sky blue, Pea green, or Berry pink. Race **two laps against two friendly rivals** on **Wiggly Way** or **Sky Scribble**.

Your car drives forward and follows the bends automatically. Steer across the road to collect inspiration stars, hop over cones and erasers, and boost when it refills. Obstacles cause a brief slowdown; cars stay safely on the course.

| Racing action | Default keyboard | Gamepad |
| --- | --- | --- |
| Steer across the road | A / D | Left stick / D-pad |
| Hop | W or Space | Bottom / south button |
| Funny horn | F | Left / west button |
| Boost | G | Right / east button |
| Pause | Esc | Start |

Boost refills six seconds after use. Racing follows Player 1's remapped controls and device prompts. Pause freezes the countdown, race clock, cars, and boost timer; losing focus or disconnecting the assigned controller also pauses the race. Results show place, time, and stars, with **Race again!** and **Dream garage** buttons. Racing is single-player.

Choose **Sketch a course** to click **6–20 dots** inside the drawing guide. Leave about a car length between neighboring dots and spread the loop across the page. **Undo dot** and **Clear paper** let you revise it; **Build & race!** smooths and closes the loop. Crossings are welcome. **Your Scribble** stays available when you return to the title and reopen racing during the same app session. It is not saved after quitting the app. Drawing a course requires a mouse or trackpad.

## Look, sound, and comfort

The supplied poster opens the game with a six-entry handwritten footer menu. Every successful hit displays a damage number; reduced motion keeps the number still as it fades. Illustrated selection cards show each special against its own colored scene, with subtle focus animation. The six fighters use thick marker bodies, expressive stances, broken ink rims around their hollow heads and fewer joint dots to carry the poster's silhouettes into combat. They retain their 45% enlargement; Dark lord is another 50% larger. Compact paint-swatch HUD, hand lettering, illustrated desktop/quarry/glitch backgrounds, hand-drawn walkable ledges, layered foreground props, local color spill and large luminous specials carry the same sketchbook look into play. The fighting rigs, oversized weapons, racing cars, and courses are drawn in code from the supplied ideas. Racing keeps its cream sketchbook page, little roadside signs, and Wobble Castle.

Settings provides separate master, music, and sound-effects volumes, reduced motion, hold-to-attack, key remapping, controller assignments, and saved fighter preferences. Six original layered battle tracks use different melodies, percussion, bass and instruments. Each journey match gets its own music, including the return to Desktop Dojo; H4CK3R uses the digital Glitch score, which also plays in Glitch Core quick matches. Changes crossfade and rematches keep their current track. Music and sound effects are synthesized. See [art and audio sources](docs/ASSET_PROVENANCE.md) for the poster, generated backgrounds, fonts, and licenses.

## Project contents

- `game/`: complete Godot project, fighter/weapon data, shared gameplay, art, racing/editor, and thirteen automated test suites.
- `builds/mac-v0.4.0/`: v0.4.0 Universal Mac export location.
- `reference/`: supplied drawings and interpretation notes.
- `docs/`: planning material, [test instructions and results](docs/TESTING.md), and asset/license information. The original plan is background; [BUILD_STATUS.md](BUILD_STATUS.md) describes the implemented build.
- [Future roster](docs/FUTURE_ROSTER.json): implemented characters and retained expansion concepts. The six selectable fighters, Pac-Man, H4CK3R and Dark lord bosses, and camera-bug helper are implemented; the other entries remain proposals.
