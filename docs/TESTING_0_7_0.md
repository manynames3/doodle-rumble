# Verification — Doodle Workshop v0.7.0

## Source and persistence

Godot 4.7.2 ran **30 source suites / 2,621 checks / zero failures**. The complete original suite ran, then the affected custom suites were rerun after review fixes. Raw logs and receipts are retained locally under `docs/test-results/v070/` and are not bundled in the public repository. QA used separate `DoodleRumbleQA` profiles; it did not open or overwrite the family's settings, story or artwork.

The new checks cover six-slot creation/edit/copy/delete, corrupt-file backup recovery, failed-save rollback, original photo ownership, long-stroke preservation, invalid/missing-photo handling, and approved kit data. Two separate Godot processes restored a saved custom fighter and chapter via the same isolated profile (`restart-write.log`, `restart-read.log`).

`test_workshop` performs **33 checks** including actual source PNG/JPEG/HEIC loading, a synthetic JPEG with EXIF orientation 6, untouched source and matte hashes, editable keep/erase/cutout data on reopening, and rejection of incomplete imported rigs. The native picker is configured through Godot; these file tests call the import path directly and are not a human picker interaction test. Artificial fixtures do not establish automatic success on every photographed drawing.

## Combat and game flow

- **226 custom-combat checks:** basic/aerial/special damage, timing at 30/60/120 simulation increments, cooldowns, single-hit-per-cast protection, return/cleanup, reflection ownership and ball bounces. Twelve seeded two-custom-AI scenarios cover all kits at three difficulties; health is replenished there to sustain pressure testing.
- **Nine live-match checks:** three complete best-of-three matches use actual mapped player inputs and physics, without forced damage/health/scoring. They cover custom/custom local, custom/original local and original/custom computer play; each is followed by a rematch cleanup check.
- **48 integration checks:** My Doodles → editor → real Practice → same initiating player slot/mode → stage selection; independent state when both players select one drawing; window-close draft protection; all six story chapters, deleted-hero recovery, portraits and personalized ending. Story chapter result outcomes are scripted in this suite, so it is a progression test rather than a complete human-played custom campaign.
- Original six-fighter, difficulty, bosses, hazards, controls, menus, audio, endings and racing suites remain green.

## Native visuals and performance

The public [six-pose contact sheet](screenshots/workshop/six-poses.png) shows a drawn fighter and an authored synthetic paper-photo fixture in idle, walk, jump, attack, victory and defeat poses. [My Doodles](screenshots/workshop/my-doodles.png) and [the local match](screenshots/workshop/custom-fighters-in-match.png) are actual game-scene captures. Raw native render logs and the beige rendering benchmark remain in the local QA folder.

Native QA passed **34 checks**, plus **eight focused art checks**. Inspection covered original colors, transparency, white perimeter, limb joins, hand/weapon alignment, distinct feet, preview fit and results. Screenshots are evidence of specific sampled poses, not exhaustive proof of all possible drawings.

On Apple M1/macOS with GL Compatibility, two rigs (51 drawn strokes and one six-part photo rig) ran for 300 frames in a hidden native SubViewport. Frame wall time including rendering/vsync: **mean 11.42 ms, median 11.58 ms, p95 13.76 ms, max 35.31 ms**. Two-rig pose CPU: **median 0.085 ms, p95 0.102 ms**. The twelve contact-sheet rigs were freed before timing. This isolates artwork cost; it is not a whole-match FPS guarantee. Exact output is retained locally in `docs/test-results/v070/custom_fighters_native_qa.txt`.

## Mac build and packaging

The installed export-template directory lacks `4.7.2.stable/macos.zip`. A fresh Godot game pack was exported successfully with `--export-pack`. The previous local app's Universal runtime reports `4.7.2.stable.official.ed1daf0bf`, matching the editor; a separate new bundle contains that runtime, the new pack, version 0.7.0 / build 19, and a fresh ad-hoc signature. The previous app was preserved. `codesign --verify --deep --strict` passes and `file` confirms arm64/x86_64 slices.

The exported PCK passed **30 suites / 2,621 checks / zero failures**; packaged logs are retained locally under `docs/test-results/v070/packaged/`. The rebuilt app completed a 120-frame headless boot with an isolated profile and no runtime errors. Package policy tests passed **6/6**. Archive structure, required original source packs, exclusions and signatures are checked by `package_release.py`; final SHA-256 receipts accompany the two ZIPs.

## Not tested

Family usability, a full human-played custom campaign, physical controllers, keyboard rollover, trackpad drawing comfort, representative difficult real family photos, audio through real speakers, long sessions, Intel execution and transferred launch on another Mac. Photo rigging remains an assisted workflow. The app is not Developer ID signed or Apple-notarized.
