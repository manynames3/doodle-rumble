# Doodle Workshop weapon art

The first four current transparent sprites use `_v2` filenames and were restyled against `game/assets/intro_poster_v060.png`. The new Rubber Chicken and Jumbo Crayon sprites use `_v1` because they have no older version. All six use rough ink contours, saturated color, and neon-lit arcade illustration; existing source versions remain alongside them.

Style prompt: use the poster as the exact game-art reference and the existing sprite as the edit target; preserve each readable weapon silhouette and orientation, with transparent padding; add irregular charcoal ink, saturated poster colors, sparse sketch marks and restrained colored edge light; avoid photorealism, polished 3D shading, scenes, text, characters and baked-in attack trails. Generated with Codex's built-in ImageGen tool; no Google/Gemini credentials or external image service are required at runtime.

| Current sprite | Used for |
| --- | --- |
| `pixel_pickaxe_v2.png` | Pixel Pickaxe held art |
| `dinosaur_bone_v2.png` | Big Bone held art, menu preview and Fossil Fetch projectile |
| `baseball_bat_v2.png` | Slugger Bat held art |
| `soccer_ball_v2.png` | Bouncy Ball held art, menu preview and Swerve Shot projectile |
| `rubber_chicken_v1.png` | Rubber Chicken held art and Cluckquake special |
| `giant_crayon_v1.png` | Jumbo Crayon held art and Rainbow Ruckus special |

The hand anchors are in `game/scripts/weapon_art.gd`; projectile and preview references are in `custom_projectile.gd` and `custom_kit_preview.gd`. These values position artwork only. Kit damage, hitboxes, windup, recovery, cooldown, and projectile rules remain in game logic. New sprites were created with Codex's built-in ImageGen in the title-poster ink style; the game never calls an image service at runtime.
