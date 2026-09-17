# Art guide

> Archived guidance from the supplied planning package. The implemented art now includes the user's later poster and gameplay references; see ASSET_PROVENANCE.md and ../BUILD_STATUS.md for the current build.

The drawing is the art direction. Keep the oversized heads and tools, angular blades, uneven pencil character, circular eye details, and strange silhouettes. Make the movement readable while preserving the children’s choices.

## Review the original

Use `reference/kids_original_drawing.jpeg`. Ask the kids to point to each character and identify its color, weapon, special move, and funniest victory pose. Several figures overlap and the block-armored figure is unlabeled. Record those answers instead of guessing.

For the main four, the proposed roles are Orange/pitchfork, Red/hammer, Green/sword, and Blue/pickaxe. Green and Blue visibly carry angular sword-like weapons in the drawing; Blue’s pickaxe is a proposed gameplay variation that the children can change.

## Production steps

1. Keep the source photo unchanged.
2. Make one separate working crop per identified character. Maintain a mapping to the original drawing.
3. Create a clean transparent PNG or SVG while preserving the original head shape, silhouette, and weapon proportions. Add the intended colors.
4. For stick figures, separate head, torso, arms, legs, and weapon for simple joint animation. Use Sprite2D parts or Line2D limbs with a hand pivot. For unusual shapes such as Pac-man and the camera bug, use a short sprite sequence.
5. Use the same feet baseline and a consistent body scale. Keep weapons separate and allow their visual size to remain exaggerated.
6. Make idle, run, jump/fall, attack, hurt, and victory animations for the first approved fighter before processing the rest.
7. Show the result to the kids in motion. Preserve details they care about before polishing the rest of the roster.

## File conventions

- `art/characters/orange/portrait.png`
- `art/characters/orange/head.png`
- `art/characters/orange/body.png`
- `art/characters/orange/arms.png`
- `art/characters/orange/legs.png`
- `art/weapons/pitchfork.png`
- `art/arenas/desktop/background.png`

Start at a 1280 by 720 logical game canvas with the fighter body about 110 to 130 pixels tall. A 512 by 512 transparent working canvas per character gives room for clean source art; trim or place parts deliberately when importing. These sizes are production starting points, not hard requirements.

## Child review card

Character name:

Color:

Which figure on the page:

Favorite weapon:

Special move:

One detail we must keep:

Victory pose or sound:

This character looks right to me:
