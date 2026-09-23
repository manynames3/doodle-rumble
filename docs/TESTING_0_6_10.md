# Validation archive — Doodle Rumble v0.6.10

Updated 2026-09-23. The project and app were tested on this Apple Silicon Mac with standard Godot 4.7.2. Automated gameplay tests used isolated QA preferences; they do not use or overwrite normal player saves.

## Gameplay and art regression

The complete source run passed **24 suites / 2,275 checks / 0 failures**. The same suite was run against the Mac app's exported PCK and passed **24 suites / 2,275 checks / 0 failures**. Each run's JSON summary and logs are under `docs/test-results/v0610/source/` and `docs/test-results/v0610/packaged/`.

The suites cover combat timing and damage, fighter-art mappings, boss attacks and recovery windows, hazard warnings, AI, stage progression, menus, local multiplayer, audio, ending playback and existing racing regression tests. The story integration test simulated 18 rounds across all six chapters with zero retries. No racing feature or content was changed in this release.

Boss pressure was compared with identical fixed-step conditions over 40 seconds: Pac-Man dealt 146, H4CK3R 357 and Dark lord 593 simulated damage. Dark lord's eight patterns and boss multiplier are also covered by focused tests. This models attack pressure and telegraph logic; it does not measure fun or perceived fairness.

## Visual review

Godot rendered native 1280×720 captures from the running scene. I reviewed Pac-Man in idle, run, bite and heavy attack: each uses one visible eye. Dark lord's eclipse volley, eclipse wave and void pillar were captured at both warning and release. Their purple warning marks remain distinct from the larger purple release effects. The capture files are under `docs/test-results/v0610/visuals/`.

The original supplied Pac-Man bite-impact PNG was compared byte-for-byte with the copy under `source_art/` and is unchanged. The new one-eye runtime override PNGs are separate from that original art.

## Mac app

The 0.6.10 / build 17 Mac app exported successfully with Godot 4.7.2's matching templates. `file` reports both **arm64** and **x86_64** in the executable, `codesign --verify --deep --strict` passed, and the app booted its main scene for 120 headless frames with no error output. The exported PCK also passed the complete regression run above.

This machine does not have an Apple Developer ID certificate. The app is ad-hoc signed and **not notarized**, so Gatekeeper may require **System Settings → Privacy & Security → Open Anyway** after download. Finder launch on a separate Mac, Intel execution, physical controllers, sound through external hardware, keyboard rollover and family playtesting remain unverified.

## Archive checks

The package-policy test suite passed **6 tests**. Both release ZIPs passed full CRC/integrity scans and archive-content policy checks. Their exact byte sizes and SHA-256 digests are in `DELIVERY_v0.6.10.json` and `SHA256SUMS_v0.6.10.txt` beside the archives.
