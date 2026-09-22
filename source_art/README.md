# Original transparent production packs

These nine folders preserve the individual PNGs, README files, and manifests from the owner-supplied `*_Transparent_Asset_Pack.zip` archives. The PNG bytes are unchanged. They are placed outside `game/` so Godot imports only the smaller runtime copies under `game/assets/character_art/`.

To rebuild the runtime images, install Pillow for the build-time Python interpreter and run:

```sh
python3 game/tools/import_character_packs.py
```

The importer validates each pack against its manifest, trims transparent safety padding from runtime copies, scales the copies, and writes per-pose pivot metadata. See [`../docs/CHARACTER_PACK_MAPPING.md`](../docs/CHARACTER_PACK_MAPPING.md) for the exact game-state mapping and assets retained only as source.
