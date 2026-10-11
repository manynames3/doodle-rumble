# Original transparent production packs

`Fuse_Production_Assets/` is a separate generated expansion pack: 13 authored poses, six effects, a missile, source atlases, exact prompts and extraction geometry. `game/tools/import_fuse_art.py` rebuilds its runtime textures and authored pivots; the main importer below also invokes it. `Fuse_Concept_Renderings/` preserves the preceding concepts. These generated assets do not replace any owner-supplied pack.

`Crackle_Production_Assets/` is the diamond-helmet/fireworks expansion based on the user's pencil motif: 13 authored poses, six effects, three projectile sprites, seven unchanged generated atlases, exact prompts and extraction geometry. `game/tools/import_crackle_art.py` rebuilds the runtime pack. The original family photo stays outside the repository.

These nine folders preserve the individual PNGs, README files, and manifests from the owner-supplied `*_Transparent_Asset_Pack.zip` archives. The PNG bytes are unchanged. They are placed outside `game/` so Godot imports only the smaller runtime copies under `game/assets/character_art/`.

To rebuild the runtime images, install Pillow for the build-time Python interpreter and run:

```sh
python3 game/tools/import_character_packs.py
```

The importer validates each pack against its manifest, trims transparent safety padding from runtime copies, scales the copies, and writes per-pose pivot metadata. See [`../docs/CHARACTER_PACK_MAPPING.md`](../docs/CHARACTER_PACK_MAPPING.md) for the exact game-state mapping and assets retained only as source.
