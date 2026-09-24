# Verification — Doodle Rumble v0.7.5

## Imported fighter save-flow fix

The **Save fighter** button previously called the same action as **Save & Fight!**, so it immediately exited the Workshop instead of just saving. Both actions now persist the fighter, but only **Save & Fight!** emits the continue-to-match signal. When an imported photo is missing any of its six animated cutouts, either save action explains the difference between joint dots (bend points) and cutout dots (the outside edge of a body part), switches to **Cutout shapes**, and selects the first missing part. Other validation and storage errors use a compact, game-styled message.

## Automated verification

- Godot 4.7.2 source import completed successfully.
- Full source regression: **30 suites / 2,753 checks / zero failures**. Per-suite raw logs are retained in the local ignored `docs/test-results/v075/source-regression/` folder and are not part of the public source push.
- Focused Workshop flow: **48 checks / zero failures**, covering the selected starter color, recoloring all base parts, preserving custom marks, undo/redo, older-draft migration, automatic cutout-tool selection, imported saves, and both save buttons.
- The same focused Workshop suite passed against the exported PCK: **48 checks / zero failures**.
- Rendered and inspected the help card in the macOS Metal viewport at 1280×720; the message stays readable and the shorter status line no longer wraps into the footer.
- Rendered and inspected the Draw page with a recolored starter figure and matching selected palette swatch.
- Release archive policy tests passed **6/6** without creating ZIP files. `git diff --check` passed.

## Mac app

- Exported with the matching Godot 4.7.2 macOS template to `builds/mac-v0.7.5/Doodle Rumble.app` in the developer workspace. The generated bundle is not part of the public source push.
- Universal arm64/x86_64, bundle version 0.7.5, build 23, about 309 MB. `codesign --verify --deep --strict` passed.
- The exported executable completed a **120-frame isolated headless boot**. A manual family session with a real imported photo remains to be done.
- This local app is ad-hoc signed, not Developer ID signed or notarized; Gatekeeper behavior after transfer remains unverified.
