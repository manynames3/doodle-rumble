# Build and distribute Doodle Rumble

The current public release is [v0.7.14 / build 32](https://github.com/manynames3/doodle-rumble/releases/tag/v0.7.14). Its playable Universal Mac ZIP and source revision are verified in [TESTING_0_7_14.md](TESTING_0_7_14.md). `MAC_SETUP.md` is the archived starter plan.

## Run from source

Use the standard Godot 4.7.2 editor, open `game/project.godot`, wait for asset import, then press F5. The game runs offline and needs no runtime packages or plug-ins. Clone this GitHub repository for the complete current source.

## Test and export on macOS

Install matching Godot 4.7.2 export templates. From the repository root, replace `/path/to/Godot` with your executable:

```sh
/path/to/Godot --headless --editor --path game --import --quit
/path/to/Godot --headless --fixed-fps 60 --path game --script res://tests/test_menus.gd -- --isolated-qa
mkdir -p builds/mac-v0.7.14
/path/to/Godot --headless --path game --export-release macOS
codesign --verify --deep --strict 'builds/mac-v0.7.14/Doodle Rumble.app'
```

The preset creates a Universal Apple Silicon/Intel app in `builds/mac-v0.7.14/`. The release pass runs the full source regression and tests the exact exported pack, as recorded in the verification report. `python3 game/tools/run_tests.py --godot /path/to/Godot` runs the broader source regression with isolated preferences.

A distributable app-only archive can be staged with license notices:

```sh
release_stage='builds/mac-v0.7.14/delivery/Doodle_Rumble_Mac_v0.7.14'
mkdir -p "$release_stage"
ditto 'builds/mac-v0.7.14/Doodle Rumble.app' "$release_stage/Doodle Rumble.app"
ditto docs/licenses "$release_stage/Licenses"
ditto -c -k --norsrc --keepParent "$release_stage" 'builds/mac-v0.7.14/Doodle_Rumble_Mac_v0.7.14.zip'
```

The published archive also includes launch instructions and testing notes. Verify ZIP integrity, the extracted app's signature/startup, and SHA-256 before upload; check GitHub's asset digest against the local archive before publication. `python3 game/tools/test_package_release.py` checks archive policy without packaging a release. Preserve private references, credentials and family preferences outside distribution.

## Signing and verification limits

This Mac has no Apple Developer ID certificate. The app is ad-hoc signed and not Apple-notarized; macOS may require **System Settings → Privacy & Security → Open Anyway** after download. The current pass verifies both executable slices, native Apple M4 rendering, exact-pack menus/live fight, startup and archive integrity. Intel execution, physical controllers and transfer to another Mac were not tested here. See [BUILD_STATUS.md](../BUILD_STATUS.md) for current evidence and earlier releases.
