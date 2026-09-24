# Verification — smoother custom fighters v0.7.2

## What was fixed

The v0.7.1 custom renderer submitted two polylines and four circles for every saved pencil stroke on every animation frame. A detailed drawing could send thousands of canvas commands per fighter, while the match also animated two tiny HUD copies. The same source also contained a five-argument `draw_polygon()` call that Godot 4.7.2 cannot parse. The renderer now rasterizes original strokes and photo cutouts into up to ten cached, articulated part textures when a fighter loads. Each frame moves those pieces and draws the few photo-joint bridges. Fine decorative strokes omit invisible rounded end-cap draws during the one-time bake; broad silhouette strokes keep them. HUD portraits hold their initial pose. The combined optional paper-edge shader still follows the animated fighter.

## Native match performance

Measured on this Apple M1 with Godot 4.7.2 GL Compatibility, a 1280×720 native hidden viewport containing the actual main match scene, two active fighters and the HUD. Vsync was off; each case used 20 warmup frames and 300 timed frames. The synthetic drawings had 51, 306 and 906 strokes each. These are local measurements, not a frame-rate guarantee for another Mac or every real drawing.

| Pair | Median frame | 95th percentile | Median draw calls |
| --- | ---: | ---: | ---: |
| Orange + Blue | 7.78 ms | 10.92 ms | 679 |
| Two 51-stroke drawings | 10.35 ms | 13.16 ms | 873 |
| Two 306-stroke drawings | 10.46 ms | 12.95 ms | 873 |
| Two 906-stroke drawings | 10.53 ms | 13.03 ms | 873 |

For comparison, the broken v0.7.1 renderer, with its polygon call corrected only for profiling, measured **363.29 ms median / 392.13 ms p95 / 13,095 draw calls** for two 306-stroke fighters in the same scenario. The v0.7.2 detailed case is **10.46 ms median / 12.95 ms p95 / 873 draw calls**. Physics simulation remained around 0.3 ms in the custom cases; the bottleneck was rendering. The 906-stroke run had an isolated 56.99 ms maximum during initial preparation; its last 200 frames measured 10.54 ms median / 13.01 ms p95. Raw output is retained locally under `docs/test-results/v072/`; the reproducible script is [profile_custom_match.gd](../game/tests/profile_custom_match.gd).

## Visual and regression checks

The source runner passed **30 suites / 2,621 checks / zero failures**, including live custom matches, all four weapon kits, saving and recovery, menus, original fighters, story, audio, and the unchanged racing game. The receipt and raw logs are retained locally under `docs/test-results/v072/source/`. The focused native art test passed nine checks, including original photo colors, moving joints, combined white perimeter, and the White edge switch turning the extra border off. The native contact/match capture passed **34 checks / zero failures**. I inspected the public [six poses](screenshots/workshop/six-poses.png), [My Doodles selection](screenshots/workshop/my-doodles.png), and [a real local match](screenshots/workshop/custom-fighters-in-match.png). The photos are synthetic authored fixtures; no family drawing or private save was changed.

The app uses a freshly exported Godot pack with the matching 4.7.2 Universal runtime, copied from the prior local build because the standard export template is unavailable on this machine. The bundle is ad-hoc signed and passed `codesign --verify --deep --strict`; `file` reports both arm64 and x86_64 slices. The **final exported pack** passed the same **30 suites / 2,621 checks / zero failures**; the packaged receipt and logs are retained locally under `docs/test-results/v072/packaged/`. The rebuilt app executable completed a 120-frame headless boot under an isolated QA profile with no runtime errors. Package policy tests passed 6/6, the packager validated both ZIP archives and their signatures/contents, and SHA-256 receipts were generated. Extraction and first launch on a separate Mac remain untested.

## Remaining verification

This does not replace testing the user's own most intricate drawings during sustained play. Physical controller use, family usability, Intel runtime, and a transferred first launch on another Mac remain untested. The app is not Developer ID signed or notarized.
