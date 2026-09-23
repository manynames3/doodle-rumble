# Pac-Man one-eye runtime poses

These are project-authored transparent pose derivatives generated from the supplied Pac-Man art for the runtime. The corrected art shows one visible eye in every gameplay pose. The three source atlases are retained in `source_atlases/`; the supplied production PNGs in `source_art/Pac_Man_Transparent_Asset_Pack/` remain unchanged. `import_character_packs.py` reads these per-pose overrides when rebuilding runtime textures.

The atlas art does not provide unique frames for every game state, so a few adjacent states intentionally reuse the closest generated pose while their existing game effects and fixed-timing attacks remain intact.
