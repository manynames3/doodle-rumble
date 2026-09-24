# Doodle Workshop

A fighter can now start as a drawing made in the game, or as a photo of a drawing on paper. The original six fighters and the six story opponents keep their existing roles. Custom fighters use the same movement, collision size, health and controls; drawing a bigger body does not create a stronger fighter.

## Make a fighter

1. Open **Story Mode**, **Quick Match**, **2P Battle**, or Practice's fighter selection.
2. Choose the player slot, then **My Doodles → Draw a fighter**.
3. Draw the head, body, two arms and two legs. **Fighter color** recolors the starter figure and sets the color for new strokes; existing marks keep their own colors. Use Details to attach extra marks to the chosen part. Three pen sizes, a drag eraser, undo/redo, guide toggle and zoom are available.
4. In **Bring to life**, put the joint dots on the drawing's bends. Watch the animated preview and go back whenever something looks wrong.
5. Choose one of six weapon kits: Pixel Pickaxe, Dinosaur Bone, Baseball Bat, Soccer Ball, Rubber Chicken or Jumbo Crayon. Try walking, jumping, basic/special attacks, celebrating and falling. **Try in Practice** saves the fighter and opens a real practice match; **Back to workshop** returns to editing.
6. Name the fighter. **Save fighter** stores it in My Doodles and leaves you in the Workshop; **Save & Fight!** stores it and continues to battle. Quick Match and 2P continue to stage selection; Story continues its selected chapter.

There are six local slots. The library supports **Edit**, **Make a Copy** and confirmed **Delete**. Both players can use the same doodle while keeping separate health, attacks and animation state. A custom opponent can also be computer-controlled.

## Import a paper drawing

Use **Import → Choose photo** for a local PNG, JPEG, HEIC or HEIF. On macOS the HEIC conversion uses the system's `sips` utility. JPEG orientation is read before editing; manual quarter-turn rotation remains available.

Frame the paper with the four corner dots, adjust paper-removal sensitivity, and use **Keep** and **Erase** to correct the transparent preview. In **Bring to life**, choose **Cutout shapes** and tap at least three points around the outside edge of each body part (head, body, two arms and two legs). Then choose **Move joints** to place the bend dots at elbows, knees and other joints. The two dot tools do different jobs: cutout dots define the paper pieces; joint dots define where those pieces bend. If a save finds missing shapes, it automatically switches to **Cutout shapes** and selects the first missing part. This is an assisted workflow: faint pencil, shadows and overlapping limbs often need corrections or an adult's help. It is not automatic pose recognition. Wings, horns, clothes and tails can travel with a chosen body part; they do not gain separate creature locomotion.

The game keeps an untouched local source copy plus the editable cleanup settings, masks, cutouts and joint coordinates. It does not upload or regenerate the artwork.

### A small paper edge that follows the action

Imported parts are first animated into **one transparent composite**. A shader expands that composite's alpha to add a warm-white paper margin (about 2.5 pixels in unscaled fighter coordinates). The **White edge** checkbox in the Import step switches the effect on or off and is saved with the fighter. Because the edge is calculated from the current pose, it follows walking, jumps, swings and result poses. Padding around the offscreen image leaves room for lifted hands and heads. The source photo and cleanup mask stay untouched.

## Weapon kits

| Kit | Ordinary / aerial attack | Special |
| --- | --- | --- |
| Pixel Pickaxe | Diagonal chip / descending strike, 14 damage | **Ore Pop:** three marked eruptions, 22 damage total per opponent per cast |
| Dinosaur Bone | Broad bonk / rising swing, 15 damage | **Fossil Fetch:** an outward-and-returning bone, 22 damage; the held weapon disappears during flight |
| Baseball Bat | Ground / airborne swing, 16 damage | **HOME RUN!:** a 24-damage launcher with a short window for reflecting eligible projectiles |
| Soccer Ball | Close kick / aerial volley, 12 damage | **Swerve Shot:** a predictable curved kick, up to two surface bounces, 22 damage |
| Rubber Chicken | Squeaky side-slap / descending peck, 15 damage | **Cluckquake:** a two-sided comic squeak pulse, 22 damage; each opponent can be hit once per cast |
| Jumbo Crayon | Wax bonk / airborne scribble, 14 damage | **Rainbow Ruckus:** a telegraphed rainbow floor-sweep, 22 damage; jump or move clear before the color lands |

Cluckquake and Rainbow Ruckus follow the nearest platform beneath the fighter, so they work from the Desktop Dojo's upper desks as well as the main floor. The effects are signaled before their active window and their damage areas use the same fixed physics timing as the original kits.

Custom fighters have 100 health and a six-second special cooldown. Ordinary attacks use 0.16 seconds of windup, 0.14 active and 0.36 recovery. Specials have at least 0.32 windup and 0.55 recovery. Counter bonuses and existing hit protection still apply. Rendering never determines damage. A reflected projectile changes ownership without duplicating the effect; a projectile disappearing or a round ending restores the original thrower's weapon.

The bone, bat, pickaxe, ball, rubber chicken and crayon use transparent poster-matched ink sprites in hand poses and previews; the thrown bone and soccer ball reuse those same illustrations. Separate pivots keep transparent padding from shifting the grip, and art size never changes the combat boxes. The source PNGs are retained under `game/assets/workshop/weapons/`.

## Local data and implementation

- `custom_library.gd`: versioned six-slot library under `user://doodles/`, stable IDs, validation, owned source/matte copies, atomic writes and backup recovery. Only kit IDs are saved; combat statistics are game-owned.
- `doodle_workshop.gd`, `workshop_canvas.gd`, `workshop_photo.gd`: editor, separate stroke layers, erasing, undo/redo, photo cleanup and native file picking.
- `custom_art.gd`, `custom_paper_edge.gdshader`: articulated stroke/photo rendering and the animated paper perimeter. No runtime AI or cloud dependency.
- `custom_pose.gd`, `custom_kit_preview.gd`: shared kit poses and damage-free menu demonstrations.
- `custom_kits.gd`, `custom_projectile.gd`: fixed combat data, returning/bouncing effects and reflection ownership.
- The fighter registry exposes `playable_ids()` / `is_playable()`. The original `ORDER` stays fixed for the original cast and story ensemble.

Saved selections resolve after the library loads. A missing or damaged custom fighter falls back to a selectable original without resetting chapter progress. Deleting a fighter removes the library entry; owned image versions can remain locally to protect older backups. These user-created files are not placed in the source repository or exported application.

The original ending film remains intact. A completed custom-fighter run adds a separate animated **Drawn by you** celebration afterward. Reduced motion and shared volume settings apply throughout.

## Verification still needed with families

Automated tests and native render captures are documented in the versioned `TESTING_0_7_*.md` reports. The [v0.7.4 report](TESTING_0_7_4.md) includes screenshots of both new specials on elevated platforms. These checks do not establish that a seven-year-old can finish the creation flow unaided. Test that with children, and check actual controller navigation, unusual real-world photos, long editing sessions and low-end/Intel Macs before calling this broadly release-ready.
