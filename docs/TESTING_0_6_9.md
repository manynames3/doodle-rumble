# Validation archive — Doodle Rumble v0.6.9

Updated 2026-09-22. Tested with standard Godot 4.7.2 on Apple M1/macOS 26.6.2. QA uses isolated preferences and silent audio, so it does not alter a player's saves or disturb a running game.

## Gameplay and asset regression

The full source run and the final exported-PCK run each passed **24 suites / 2,251 checks / 0 failures**. Machine-readable results and per-suite logs are in `docs/test-results/v069/source/` and `docs/test-results/v069/packaged/` in the complete project ZIP. They cover movement, attack timing, hit protection, character packs, boss phases, hazards, AI, difficulty, story progression, menus, local 2P, audio routing, the ending and the racing regression. The live-match suite played 18 combat rounds with zero retries; the racing suite completed six two-lap races. No parser error or runtime warning appeared in these runs.

The art suite now checks 326 cases: nine role-correct packs, fallbacks, pose and effect resources, actual attack-release timing, packed-weapon layering and result animation. A separate geometry suite confirms **all nine characters** settle inside both screen edges and meet the floor at either result spawn (18/18 checks). A native edge-result capture additionally verified that Red and Dark lord fall inward while their stars remain visible, that the winner hops again during `round_over`, and that the running scene advances the celebration. Five focused combat/art suites passed 977 checks after that correction.

## Native visual and movie review

Godot rendered 1280×720 selection previews for all six fighters in normal and reduced-motion settings. We checked fit and silhouette, including Red's raised hammer, and inspected the exported-PCK selection captures. No cutout extended beyond its large preview after the final scale pass. Native source captures show Orange's spin, Purple's guard, H4CK3R's system-scan release, Dark lord's void release and both left/right edge results. The public [screenshot gallery](screenshots/README.md) shows curated menu, combat, boss and result frames; selected release evidence is under `docs/test-results/v069/visuals/` in the project ZIP.

The ending was re-rendered after the result-art fix as a 30.00-second, 720-frame Ogg Theora/Vorbis movie. FFmpeg decoded the whole file, and Godot played and captured four positions (3, 11.5, 21.5 and 27.5 seconds). The opening confrontation and return to the desk were visually reviewed. The existing score was retained. These are playback/image checks, not a speaker listening test.

## Mac build and package checks

The final v0.6.9 app was exported with Godot's matching templates. Its Mach-O executable contains both **arm64 and x86_64**; the bundle reports version **0.6.9**, build **16**. Strict `codesign --verify --deep --strict` passed, and the app executable launched and exited cleanly with an isolated QA profile. The exported PCK loaded all six fighter previews and passed the full regression suite. The five archive-policy unit tests passed.

Both release ZIPs passed full archive integrity checks. The 627 MB project ZIP contains the runnable Godot project and all nine original production packs; it excludes the private family drawings, supplied planning originals, caches, credentials and build output. The 207 MB Mac ZIP has no `__MACOSX` or AppleDouble entries. Its app was extracted with `ditto`, passed strict signature verification again, and launched/exited cleanly from the extracted location. SHA-256 receipts are adjacent to the archives in `DELIVERY_v0.6.9.json` and `SHA256SUMS_v0.6.9.txt`.

**Distribution limit:** this machine has no Apple Developer ID identity. The build is ad-hoc signed and **not notarized**; `spctl` rejects it as a public download. It is a locally tested release candidate, not a frictionless Mac installer. Physical controller behavior, Intel execution, transferred first launch, keyboard rollover, audio on other hardware, long sessions and family playtesting remain unverified on those devices.
