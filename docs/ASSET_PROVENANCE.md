# Art and audio sources

The original owner-supplied Stick Souls / Dark Lord poster is preserved in `game/assets/intro_poster.png`. The title uses `game/assets/intro_poster_v060.png`, a generated edit that replaces the title lettering with Doodle Rumble and, in v0.6.7, clears the old lower-right arcade copy; see the exact prompts below. Characters visible in the poster beyond the implemented roster are illustration, not locked playable content.

The original implementation used procedural Godot drawings for fighters, weapons, particles and UI brushwork. The original four fighters preserve the children's silhouettes; Purple and Yellow follow the later user-supplied special-attack illustrations. Those illustrations also guide the neon ink, special effects and scene lighting. Racing cars and racing courses remain procedural. Combat collision and damage are independent of artwork.

The September 2026 character-art pass adds nine owner-supplied transparent production packs: Orange, Red, Green, Blue, Purple, Yellow, Pac-Man, H4CK3R and Darklord. Each original pack has 34 separate RGBA PNGs plus its README and manifest, retained unchanged in `source_art/`. `game/tools/import_character_packs.py` creates trimmed, resized runtime copies in `game/assets/character_art/` and records source-pixel pivots in per-character JSON. It does not crop character art from a poster or use reference sheets as sprites. The six playable packs appear in selection and combat; all nine appear in story/fight scenes. The older procedural rig remains for result poses and game elements that the packs do not cover. See [CHARACTER_PACK_MAPPING.md](CHARACTER_PACK_MAPPING.md) for exact state mappings and preserved, unmapped source images.

Three illustrated arena backgrounds were generated using the built-in image-generation tool, then copied into `game/assets/arenas/desktop_v2.png`, `quarry_v2.png`, and `glitch_v2.png`. They use the corresponding user-supplied September 10 gameplay renderings as style references. Godot aligns each background floor with the physics surface.

Sound effects and the retained title/racing loop are synthesized in `scripts/audio.gd`. Six original battle arrangements were rendered to `game/assets/music/*.wav` with the included deterministic `generate_stage_music.py` (NumPy is only needed to regenerate assets, not to play). They use original note patterns, bass, harmony and synthesized percussion/instruments; no external audio recordings, samples or borrowed melodies are used. The music controller crossfades contexts. See [MUSIC.md](MUSIC.md).

Six illustrated special-attack cards were generated with the built-in image-generation tool using the user's special-attack sheet as a style reference. The finished files are `game/assets/selection/orange_action.png`, `red_action.png`, `green_action.png`, `blue_action.png`, `purple_action.png`, and `yellow_action.png`. The new transparent canonical cutouts now take priority in selection, while these earlier menu paintings remain available as fallbacks. Godot adds live labels, selection feedback and restrained movement. The exact prompt set is in [SELECTION_ART_PROMPTS.json](SELECTION_ART_PROMPTS.json).

Pac-Man is the user's requested fourth-stage opponent, before H4CK3R and Dark lord. Its original code-drawn yellow chomp creature was inspired by the supplied poster's Byte Chomp; its new transparent pack supplies the current bite art. Its bite and charge use the existing combat rules. No third-party sprite or audio recordings were copied.

The Kalam font is by Indian Type Foundry, distributed under the SIL Open Font License. Source: https://github.com/google/fonts/tree/main/ofl/kalam. License: `docs/licenses/KALAM_OFL.txt`.

Godot and its bundled components have notices in `docs/licenses/`; engine license: https://godotengine.org/license/.

## Background prompts

### desktop_v2

Use case: stylized-concept. Asset type: finished2D side-scrolling platformfighting game environment, wide16:9. Reference image is style/environment guidance; create a clean playable BACKGROUND ONLY version of its setting. Desktop Dojo: an imaginative child's actual desk/drawing room. Large computer windows with blank sketchbook canvases, a real window looking onto sunset clouds, pencils in mugs, taped tiny doodles, stacked sketchbooks below the desk. Keep the warm creative workroom feeling of the reference, muted lavender/blue-grey room and warm pale peach window light. Continuous desk tabletop at86percent height. No fortress. Preserve reference's painterly outlined/sketchy edges, layered depth, handmade character, light and colors. REMOVE ALL CHARACTERS, fighters, weapons, attacks, effects bursts, gameplay HUD, healthbars, labels, logos, lettering, menus and controllerprompts. NO floating foreground gameplay platforms (engine draws these), NO furniture/obstacles in the lower-half action area. Compose a straight continuous horizontal foregroundfloor acrossfullwidth at86percent imageheight, no gaps or stairs. Bottomhalf abovefloor is unobstructed and moderately subdued so smallbrightstickfigures read clearly. Detail strongest in upperhalf andextremeedges. No new characterlike shapes, no readabletext. Rasterillustration matching suppliedstyle rather than flatvector. Fullbleedlandscape.

### quarry_v2

Use case: stylized-concept. Asset type: finished2D side-scrolling platformfighting game environment, wide16:9. Reference image is style/environment guidance; create a clean playable BACKGROUND ONLY version of its setting. Block Quarry: sunlit stepped stoneblock cliffs, grassy tufts, tiny waterfalls down distant blocktowers, hanging cranes, timber hanging bridges in distant background, peachgold afternoon clouds and blueviolet shadows. Friendly adventurous handmade miniature blockworld, like the reference, not lava or burning fortress. Continuous level stone ledge at86percent height. Background gaps are scenery only. Preserve reference's painterly outlined/sketchy edges, layered depth, handmade character, light and colors. REMOVE ALL CHARACTERS, fighters, weapons, attacks, effects bursts, gameplay HUD, healthbars, labels, logos, lettering, menus and controllerprompts. NO floating foreground gameplay platforms (engine draws these), NO furniture/obstacles in the lower-half action area. Compose a straight continuous horizontal foregroundfloor acrossfullwidth at86percent imageheight, no gaps or stairs. Bottomhalf abovefloor is unobstructed and moderately subdued so smallbrightstickfigures read clearly. Detail strongest in upperhalf andextremeedges. No new characterlike shapes, no readabletext. Rasterillustration matching suppliedstyle rather than flatvector. Fullbleedlandscape.

### glitch_v2

Use case: stylized-concept. Asset type: finished2D side-scrolling platformfighting game environment, wide16:9. Reference image is style/environment guidance; create a clean playable BACKGROUND ONLY version of its setting. Glitch Core: a fictional desktop room corrupted by playful purple glitch magic. Several big dark computer drawing windows, scribbled crown emblems without text, layered slate blue sketchpaper walls, violet pixel clusters and magenta edge lights, a large purple circular energy portal upperright. Mood like the reference's digital drawing room, not a castle. Continuous level dark deskstone floor at86percent height. Preserve reference's painterly outlined/sketchy edges, layered depth, handmade character, light and colors. REMOVE ALL CHARACTERS, fighters, weapons, attacks, effects bursts, gameplay HUD, healthbars, labels, logos, lettering, menus and controllerprompts. NO floating foreground gameplay platforms (engine draws these), NO furniture/obstacles in the lower-half action area. Compose a straight continuous horizontal foregroundfloor acrossfullwidth at86percent imageheight, no gaps or stairs. Bottomhalf abovefloor is unobstructed and moderately subdued so smallbrightstickfigures read clearly. Detail strongest in upperhalf andextremeedges. No new characterlike shapes, no readabletext. Rasterillustration matching suppliedstyle rather than flatvector. Fullbleedlandscape.

The September 12 fighting pass adds procedural book/ruler/drawer platforms, foreground desk props, irregular HUD fills, larger procedural fighters/effects and a separate additive glow layer. No changes were made to racing-specific artwork.

## v0.3.0 additions

H4CK3R’s monitor/camera rig and cursor wand are original procedural ink drawings based on the cyan character in the supplied intro poster. New cursor, eraser and liquid-ink hazards, title footer and damage numerals are drawn with the existing Godot/Kalam assets. No new third-party art or recordings were added. H4CK3R uses the existing original Glitch score; all six story matches have distinct tracks. Racing implementation and assets remain unchanged.

## v0.4.0 procedural combat pass

No new bitmap illustrations were introduced in this pass. Existing poster, action cards and arena paintings are preserved. H4CK3R's monitor/camera eye/cables/tablet, Dark lord's torn black silhouette, Pac-Man's jagged yellow maw, six fighter stances, solid marker strokes, broken highlights, air/dodge poses, projected contact shadows, HUD bristles and interactive platforms are drawn in GDScript. `fighter_pose.gd` provides reusable acting poses; authoritative attack phases drive the animation. Racing-specific artwork and runtime files remain unchanged.

## Current development additions (September 13)

BenJam Games uses the owner-supplied studio logo unchanged in `game/assets/benjam_games.png`. Paper Canopy, Arcade Afterglow and Neon Switchyard are new generated background paintings in the existing illustrated ink style. Their distant birds, lights, paper planes, packets and portal details are procedural Godot scenery; collision remains independent.

The Rally upgrade adds original procedural notebook scenery, cars, course cards and podium artwork. Three original synthesized music tracks are in `game/assets/rally/music/`; `generate_music.py` records their deterministic generation. No recordings or sampled melodies were imported. Racing work is now explicitly authorized; historical statements about its freeze apply only to older releases.

The v0.5.0 ending movie is an original 30-second Godot animation assembled from the game’s existing painted worlds, procedural character rigs, the supplied studio logo and new narrative captions. The editable source is `ending_storyboard.gd` / `ending_captions.gd`; `tools/render_ending.gd` records it at 24 fps. The included `generate_ending_music.py` synthesizes the original closing cue. The movie is encoded as Ogg Theora/Vorbis for standard Godot playback. No voices or external recordings were added.

## v0.6.0 presentation, story and sound

The six-chapter Save Star Saga, optional challenges, badge names and ending captions are original writing. The actual ending movie was regenerated from the updated procedural storyboard and the existing original closing score. There are no voices or external video clips.

New intro and climax variations expand each of the six original story battle scores. Additional impact, material, guard, reflection, warning and interface sounds are synthesized in `audio.gd`; no external recordings or samples were added. The music generator remains included. Shared Rally music is preserved.

Live fighter demonstrations, stronger poses, ink-style controls, warning overlays and scene characters are drawn by reusable GDScript components. The six existing action-card paintings and six arena paintings are retained.

### Title lettering edit: exact image-generation prompt

Input: `game/assets/intro_poster.png`. Tool: built-in image generation. Output: `game/assets/intro_poster_v060.png`, inspected in the actual title screen. The original file is retained.

> Use case: text-localization. Edit target: supplied Doodle Rumble game title poster. Make one precise branding edit only: replace the large upper-left white scratched lettering 'STICK SOULZ' with exactly 'DOODLE RUMBLE' arranged on two lines, DOODLE on top and RUMBLE below, matching the original expressive distressed hand-painted white brush letter aesthetic and roughly same area beneath the little crown. Keep the rest of the entire poster unchanged: all fighters and colors, every weapon, Dark lord, background, framing, bottom character names and descriptions, all other text, lighting, the playful hand-drawn illustrated style. Do not create UI or add text elsewhere. Final output should retain the wide landscape game-title composition. Preserve all kids' character silhouettes and hollow heads. This is a production game asset variant, not a mockup.

### Lower-right arcade-copy cleanup (v0.6.7)

Input: the existing `game/assets/intro_poster_v060.png`. Tool: built-in image generation. Output: the same production asset path, inspected in the native title render and directly from the exported PCK. The edit removes only the small lower-right “STICKS FIGHT FOREVER / INSERT COIN” block and reconstructs the surrounding purple-blue rubble and haze; no title, fighter, weapon, lighting or other poster lettering is intentionally changed.

> Use case: precise-object-edit. Asset type: game title-screen background poster. Edit target: Image 1, the existing Doodle Rumble intro poster. Remove only the small bottom-right arcade-style text block that reads “STICKS FIGHT FOREVER” and “INSERT COIN”, including the tiny arrow/chevron. Reconstruct the affected area with the surrounding dark purple/blue rubble, glow, haze, and foreground silhouettes so it looks like the original painted poster naturally continues. Preserve every other pixel-level element: the Doodle Rumble title, Dark Lord, H4CK3R, all six fighters, colors, weapons, composition, lighting, texture, and dimensions. Do not add any new text, logos, watermarks, characters, or UI. Keep the result as a 1672x941 RGB PNG suitable for a Godot background.

## v0.6.2 boss-detail pass

Pac-Man's jaw, charge marks and pellets; H4CK3R's CRT cast labels, checksum shapes, firewall panel and local cyan glow; and Dark lord's ink mantle, crown, scythe and cast marks are original procedural GDScript drawings. No third-party sprites, sound recordings or new bitmap illustrations were added. The earlier chapter-badge artwork was procedural and its selector/display has been retired; chapter completion and optional stickers remain.
