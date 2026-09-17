# Mac setup and technical plan

> Archived setup plan from the supplied package. The game is implemented. Use ../README.md for current launch/export instructions and ../BUILD_STATUS.md for verified build status.

## Engine choice

Use the standard Godot 4 stable edition and GDScript. Godot is free and open source, has a dedicated 2D workflow, supports controllers on macOS, and exports Mac apps. GDScript has Python-like syntax but is its own language. The standard edition keeps this project independent of a .NET setup.

Official Mac download: https://godotengine.org/download/macos/

## Setup when implementation starts

1. Check the Mac model and macOS version against the current Godot requirements. Use the official standard macOS download, which supports Apple Silicon and Intel.
2. Extract Godot and open the editor. Create a project named Doodle Rumble in this package’s `game/` folder.
3. Choose the Compatibility renderer for this lightweight 2D project. Set a 1280 by 720 logical viewport with proportional scaling.
4. Create the shared input actions below in Project Settings, then build the first milestone in BUILD_ORDER.md.
5. Run from the editor during development. Install matching export templates from Editor > Manage Export Templates when a working build is ready.
6. Add the macOS export preset, choose a valid bundle identifier, and export to `builds/mac/`. Official Mac templates can create a Universal 2 app for Apple Silicon and Intel.
7. Test the exported app on a Mac. Configure signing and notarization for smooth downloaded-app distribution; an exported archive alone does not prove the Mac release is ready.

No terminal commands are needed for ordinary play after a Mac build has been packaged and tested.

## Controls

| Action | Player 1 keyboard | Player 2 keyboard | Controller |
| --- | --- | --- | --- |
| Move | A / D | Left / Right arrows | Left stick or D-pad |
| Jump | W or Space | Up arrow | Bottom face button |
| Basic attack | F | K | Left face button |
| Special | G | L | Right face button |
| Pause | Esc | Esc | Menu/Start |

Use Godot InputMap actions such as `p1_move_left`, `p1_jump`, and `p2_attack`. Bind physical keys, allow remapping, and show prompts for the active device. Assign gamepads by device ID so one controller does not drive both fighters. Set a sensible stick dead zone and pause on disconnect. Some keyboards miss certain simultaneous keys; verify the family keyboard and support remapping or controllers.

## Proposed project structure

| Planned item under game/ | Responsibility |
| --- | --- |
| project.godot | Project settings and input map |
| scenes/main.tscn | Start screen and transitions |
| scenes/arena.tscn | Floor, platforms, spawn points, and desktop scenery |
| scenes/fighter.tscn | Shared CharacterBody2D fighter and visual rig |
| scenes/hud.tscn | Health, round timer, cooldowns, and rematch |
| scripts/fighter.gd | Movement and combat states |
| scripts/weapon.gd | Attack timings and hit tracking |
| scripts/ai_controller.gd | Computer inputs through the same action interface |
| scripts/match_manager.gd | Round rules, scores, spawning, and restart |
| scripts/roster.gd | Character definitions and visual choices |

Keep authoritative movement and combat in fixed physics updates. Use separate hitboxes and hurtboxes. Fighter states should cover idle/run, airborne, attack, hurt, and defeated; hurt and defeated states must block inappropriate attacks. Keep camera shake and particles in presentation code. Avoid tying damage to the display frame rate.

Copy approved art and data into `game/assets/` and `game/data/` when implementing. The source planning folders remain outside the engine project. JSON loading code is still to be written; placing the current JSON files in Godot does not make a game run.

## Save settings

Use Godot’s user data location for sound level, reduced motion, chosen fighter, and control remapping. Keep play offline. All computer-desktop scenery, cursor actions, camera-bug effects, and glitch mechanics operate inside the game.

## Official references

- GDScript: https://docs.godotengine.org/en/stable/getting_started/step_by_step/scripting_languages.html
- Controllers: https://docs.godotengine.org/en/stable/tutorials/inputs/controllers_gamepads_joysticks.html
- Mac export: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_macos.html
- Engine license: https://godotengine.org/license/
