# Build and distribute Doodle Rumble

This is the current build procedure for the Godot 4.7.2 project. `MAC_SETUP.md` is the archived starter plan.

## Run from source

Install the standard Godot 4.7.2 editor and import `game/project.godot`. Press F5 to start. The game runs offline and needs no Python packages or plug-ins. On the title screen, choose Story Mode, Quick Match, 2P Battle or Doodle Rally.

## Test and export on macOS

Install the matching **4.7.2** Godot export templates. From this repository's root, replace `/path/to/Godot` with the executable in your Godot app:

```sh
/path/to/Godot --headless --editor --path game --import --quit
python3 game/tools/run_tests.py --godot /path/to/Godot --logs docs/test-results/local-source
mkdir -p builds/mac-v0.6.9
/path/to/Godot --headless --path game --export-release macOS
codesign --verify --deep --strict "builds/mac-v0.6.9/Doodle Rumble.app"
python3 game/tools/package_release.py --version 0.6.9
```

The export preset makes a Universal Apple Silicon/Intel `.app` in `builds/mac-v0.6.9/`. The package command produces separate **Mac app** and **complete Godot project** ZIPs plus SHA-256 receipts beside this repository. The project ZIP retains all nine original production character packs under `source_art/`; it excludes the family's private original drawings, supplied planning document, caches, credentials and local build output. Run `python3 game/tools/test_package_release.py` to check the archive policy without making a release.

Run the exported app and verify title, fighter selection, at least one full match, pause/rematch, and story progression. Also test the archive after extracting it on a separate machine before calling a build externally ready. Automated evidence and remaining device checks are recorded in `TESTING_0_6_9.md` and `BUILD_STATUS.md`.

## Current Mac signing limit

This machine has no Apple Developer ID signing identity. The export is **ad-hoc signed, not Developer ID signed or notarized**. It works as a local build, but macOS Gatekeeper can block a downloaded copy until a recipient allows it in **System Settings → Privacy & Security → Open Anyway**. A smooth public download needs an Apple Developer Program account, a Developer ID Application certificate, Xcode command-line tools, notarization and testing of the transferred archive. See [Godot's macOS export guide](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_macos.html) and [Apple's notarization guide](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).
