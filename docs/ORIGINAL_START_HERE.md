# Doodle Rumble for Mac

An easy-to-learn 2D arcade fighter starring the kids’ interpretations of characters from Animator vs. Animation, with oversized tools and block environments inspired by Minecraft.

This is a planning starter folder. It contains the design, original drawing, proposed roster, weapon settings, and development instructions. It does not contain a playable game, a Godot project, or a compiled Mac app yet.

## Start here

1. Read `docs/Doodle_Rumble_Mac_Plan.docx` (Word or Pages) for the complete plan.
2. Review the original sketch in `reference/kids_original_drawing.jpeg` with the kids. Let them confirm names and pick their favorite four characters.
3. Use `docs/BUILD_ORDER.md` to build one small playable version at a time.
4. Follow `docs/MAC_SETUP.md` for Godot setup and the eventual Mac export.
5. Keep proposed character and weapon settings in `data/`. These JSON files are design data, not executable game code.

## First playable target

Four fighters: Orange, Red, Green, Blue. One desktop arena. Move, jump, attack, and one optional special. Solo play against a gentle computer opponent plus two-player battles on the same Mac. Ninety-second rounds, readable health bars, immediate rematches. Cartoon knockback and celebration effects.

The first session starts with Orange already selected, an easy opponent, and a large Play button. A player can have fun with movement, jump, and attack alone.

## Folder map

| Folder | Purpose |
| --- | --- |
| docs/ | Design, build order, art instructions, and Mac setup |
| reference/ | Original drawing and reference links |
| data/ | Proposed roster and weapon tuning |
| art/characters/ | Future character sprites, body parts, and portraits |
| art/weapons/ | Future separate weapon art |
| art/arenas/ | Future desktop and block arena art |
| audio/ | Future hit, jump, UI, and celebration sounds |
| game/ | Location for the Godot project when implementation begins |
| builds/mac/ | Future exported and tested Mac builds |

## Decisions carried forward

- Animator vs. Animation is the main motif. The desktop, cursor, sketch tools, and animated stick movement should be visible from the first arena.
- Preserve the children’s proportions, hollow heads, uneven lines, exaggerated weapons, and unusual shapes.
- Alan Becker is treated as the animator/cursor role. All listed names remain in the design data.
- Green was listed twice; the duplicate is recorded, with a single fighter planned unless the kids mean two versions.
- H4ck3r and the linked Victim reference stay together for review. No second fighter is inferred from that link.
- Abilities and starting weapons are proposals for this game, not a canon guide.
