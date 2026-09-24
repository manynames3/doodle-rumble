# Verification — Doodle Rumble v0.7.7

Prepared on an Apple M1 Mac with Godot 4.7.2 and the Compatibility renderer.

## Workshop changes

- The complete source suite passed: **30 suites, 2,794 checks, zero failures**. The Workshop suite contributed **60 checks, zero failures**, covering the separate Fighter and Pen colors, old-save compatibility, import preview gating, cleanup of warm-gray pages, visible preview refresh, ordered Keep/Erase corrections, and cutout shape validation.
- Native Workshop screenshots were captured with synthetic test art and inspected. Fighter and Pen swatches are distinct and labeled. During photo import, the complete image stays visible while cutouts are incomplete, and the screen explicitly guides the user to trace each part.
- The supplied JPEG was loaded locally through the same photo decoder, square-crop and matte cleanup used by the Workshop. It loaded at **942×1,280**; with default cleanup strength, **236,366 pixels** became nearly transparent and **19,388 yellow-marker pixels** remained clearly visible. The processed preview was visually inspected on a checkerboard. The supplied photo and derived preview were kept out of the repository and release archives.
- The photo workflow does not automatically recognize a person or split limbs. Background cleanup removes page white; the user still traces Head, Body, both Arms, and both Legs. The new guidance, validation, and preview gate prevent a small or malformed traced region from being presented as a completed fighter.

## Mac export

- Exported `builds/mac-v0.7.7/Doodle Rumble.app` from the matching Godot 4.7.2 Universal macOS template. `Info.plist` reports version **0.7.7**, build **25**; `file` confirms **arm64 and x86_64** slices.
- `codesign --verify --deep --strict` passed. The app is ad-hoc signed, not Developer ID signed or notarized.
- The exported executable booted with the embedded game pack in headless mode, ran 120 frames using an isolated QA data directory, and exited with status 0.

## Not verified

- This smoke test does not replace a double-click GUI launch or a full playthrough of the exported app.
- Intel hardware, transfer to another Mac, post-transfer Gatekeeper behavior, controller devices, external audio hardware, and notarization were not tested.
- The published release includes the universal Mac app, Godot source project, checksums, and this verification report. The app is ad-hoc signed, not notarized.
