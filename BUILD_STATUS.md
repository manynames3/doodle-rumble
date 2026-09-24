# Build status — Doodle Rumble v0.7.5

Updated 2026-09-24. Godot 4.7.2 / GDScript. This is a local build; it has not been published as a GitHub release.

## This update

- Fixed the imported-fighter save flow. **Save fighter** now writes the custom fighter and stays in the Workshop; **Save & Fight!** writes it and continues to the selected game mode.
- When an imported photo is missing body-part cutouts, save explains that joint dots mark bends while cutout dots trace the outside edge. It automatically switches to **Cutout shapes**, selects the first missing part, and names the next step. Other validation/save errors use a compact, game-styled message instead of a full-screen gray system dialog.
- The Draw palette now recolors the six starter figure parts as well as setting the color for new strokes. Existing freehand marks keep their own colors, color changes can be undone, and older starter drawings recover their saved palette color.
- Added automated coverage for the tool switch, selected body part, child-friendly explanation and dialog, plus incomplete and complete imported drawings. A complete six-part photo can be saved, reloaded, and emitted into the match flow.
- Preserved the six custom weapon kits, platform-aware specials and existing photo cleanup/white-edge behavior. Doodle Rally was not changed.

## Verification and delivery

- Godot 4.7.2 imported the project successfully.
- Full source regression: **30 suites / 2,753 checks / zero failures**. The Workshop suite passed **48 checks / zero failures**.
- The exported v0.7.5 PCK passed the Workshop import/save suite: **48 checks / zero failures**.
- Rendered the updated color palette and starter fighter in the macOS Metal viewport at 1280×720, and checked the help card/footer layout.
- `game/tools/test_package_release.py`: **6/6 passed**. `git diff --check` passed.
- Exported a fresh Universal macOS app, **v0.7.5 / build 23**. `codesign --verify --deep --strict` passed, the executable contains arm64 and x86_64 slices, and the app completed a 120-frame isolated headless boot.
- The updated app is at `builds/mac-v0.7.5/Doodle Rumble.app` in the developer workspace (about 309 MB). The app bundle is intentionally excluded from Git; no ZIP archives were created.

## Launch

To launch the local export, double-click `builds/mac-v0.7.5/Doodle Rumble.app`. The app bundle is local and is not included in this repository. From source, open [game/project.godot](game/project.godot) in Godot 4.7.2 and press F5. In fighter selection choose **My Doodles** to create or import a fighter. On the Draw page, choose **Fighter color** to recolor the starter body and set the color for new marks. For photo imports, use **Cutout shapes** to trace the outside edge of the head, body, both arms and both legs; **Move joints** only places bend points. If a save finds missing shapes, it switches to the correct tool and selects the first one for you. **Save fighter** keeps you in the Workshop; **Save & Fight!** continues to battle.

## Known limits

- The app is locally ad-hoc signed, without a Developer ID certificate or notarization. macOS may ask a recipient to allow it in **System Settings → Privacy & Security → Open Anyway**. First launch after transfer and Intel hardware execution remain unverified.
- Button callbacks and save behavior were exercised in isolated engine tests with a synthetic six-part photo. A manual family session using a real photo has not been performed.
- The custom-art native benchmark peaked at 34.51 ms in the previous 300-frame sample; its median and p95 stayed below one 60 Hz frame on the Apple M1. Highly detailed creations may still have a brief preparation hitch when entering a match.
