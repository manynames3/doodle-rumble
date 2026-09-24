# Build and distribute Doodle Rumble

The current local build is v0.7.6. `MAC_SETUP.md` is the archived starter plan.

## Run from source

Install the standard Godot 4.7.2 editor, open `game/project.godot`, wait for asset import, then press F5. The game runs offline and needs no runtime packages or plug-ins.

## Test and export on macOS

Install the matching **Godot 4.7.2 export templates**. From the repository root, replace `/path/to/Godot` with the executable in your Godot app:

```sh
/path/to/Godot --headless --editor --path game --import --quit
python3 game/tools/run_tests.py --godot /path/to/Godot --logs docs/test-results/local-source
mkdir -p builds/mac-v0.7.6
/path/to/Godot --headless --path game --export-release macOS
codesign --verify --deep --strict "builds/mac-v0.7.6/Doodle Rumble.app"
python3 game/tools/package_release.py --version 0.7.6
```

The export preset creates a Universal Apple Silicon/Intel app in `builds/mac-v0.7.6/`. `package_release.py` creates two separate archives beside the project: the **Mac app** and the **complete Godot project**. The project archive retains the nine original character packs and derived Pac-Man eye-correction source art; it excludes private family drawings, planning files, caches, credentials and local build output. The archives have SHA-256 receipts. Run `python3 game/tools/test_package_release.py` to check the archive policy without packaging a release.

Run the app and check title, fighter selection, a full match, pause/rematch and story progression. Then extract and test the archives on another Mac before calling the build ready for external distribution. Current automated evidence and open device checks are in [TESTING_0_7_6.md](TESTING_0_7_6.md) and [BUILD_STATUS.md](../BUILD_STATUS.md).

## Signing and distribution

This Mac has no Apple Developer ID signing identity. The local app is **ad-hoc signed, not Developer ID signed or notarized**. It launches here, but macOS may block an app downloaded from elsewhere until the recipient allows it in **System Settings → Privacy & Security → Open Anyway**. A smooth public download needs a Developer ID Application certificate, notarization and testing after transferring the archive. See [Godot's macOS export guide](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_macos.html) and [Apple's notarization guide](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

## Current local build

The v0.7.6 app is exported with the matching Godot 4.7.2 macOS template. It includes the poster-focused combat HUD and fighter sizing, custom-art cache/performance pass, and three story-arena movement routes. It is Universal arm64/x86_64, bundle build 24. Earlier versioned bundles are preserved. The app remains ad-hoc signed and unnotarized; see the current verification report before distributing it.
