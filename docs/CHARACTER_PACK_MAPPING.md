# Transparent character pack integration

Nine supplied packs are installed under `source_art/`, with all 306 original RGBA PNGs, their READMEs, and their manifests unchanged. `game/tools/import_character_packs.py` reads each source manifest, trims only transparent border from **runtime copies**, downsizes the copies to at most 896 pixels on their longest side, and records each pose's source-pixel offset and scale in `game/assets/character_art/<id>/art.json`. The originals stay available for future re-imports. Source packs are outside `game/`, so Godot does not waste export space importing the 306 originals. No poster, reference sheet, or opaque background is used as a character sprite.

| Pack | Game role | Visible integration |
| --- | --- | --- |
| Orange | Selectable | Selection card, live special preview, story scenes, ending, fights; spin pose and orange effects. |
| Red | Selectable | Same contexts; basic horizontal hammer impact and special heavy smash/shockwave pose. |
| Green | Selectable | Same contexts; lightning-dash pose and green effects. |
| Blue | Selectable | Same contexts; block-blast pose and blue effects. |
| Purple | Selectable | Same contexts; signal-shot pose and purple effects. |
| Yellow | Selectable | Same contexts; swarm-summon pose and yellow effects. |
| Pac-Man | Story boss, stage 4 | Story portrait, arcade fight and ending; bite impact and yellow effects. No selection card. |
| H4CK3R | Story boss, stage 5 | Story portrait, arcade fight and ending; system-scan pose during the existing firewall-scan cast, cyan effects. No selection card. |
| Dark lord | Final story boss, stage 6 | Story portrait, arcade fight and ending; void-sigil pose during the existing void-orb/rift casts, violet effects. No selection card. |

For each character, `ground_idle`, alternating run anticipation/full-speed poses, jump takeoff/apex/landing, attack anticipation/follow-through, and the pack's named attack impact are selected from existing fighter state. A small idle sway and running lean keep the individual frames moving without changing collision. Red's heavy-smash anticipation/impact illustrates its existing ground shockwave. All five separated effect images are connected: speed lines for movement, swing trail for active attacks, impact burst at release, debris during specials, and dust on landing or a heavy strike. Existing procedural trails, local light spill, hit sparks, and telegraph marks remain in place. Boss impact poses wait for the actual attack release; Purple's released arrow switches to an empty-bow pose. Effects are visual and do not alter physics, damage, recovery, or hitboxes. Reduced motion suppresses moving pack effects.

The packs do **not** include hit, dodge, victory, or defeat frames. Hurt and dodge reuse the nearest supplied action pose with a small visual transform. Result animation transforms the packed pose into a jump/cheer or a fallen body and keeps the existing hand-drawn stars above the loser, so characters do not switch art styles at the end of a round. The packs provide no separate projectile, swarm-helper, or boss hazard frames, so those existing game systems keep their current art. The generic `heavy_smash` pair has no direct mechanic for eight of the nine characters and is preserved only in `source_art/`. Turnarounds, head studies, and separated weapon/ability views and details are likewise preserved as source/reference material; placing them over the full-body pose would duplicate its head or weapon. No new mechanics or frames were invented to use them.

The title poster and arena backgrounds remain their own illustrated assets. The new pack art is used where a character is rendered, rather than replacing an environment image.
