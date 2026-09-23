# Build status — Doodle Rumble v0.6.10

Updated 2026-09-23. Standard Godot 4.7.2 / GDScript. The local Universal Mac app has been exported and tested. It is ad-hoc signed, not notarized.

## Completed

- Pac-Man now has one large visible eye in every mapped pose, including idle, run, bite and heavy attacks. The 13 derived runtime pose overrides are separate from the untouched supplied pack; the art importer selects them on rebuild and the character-art regression checks the mapping.
- Dark lord is tuned above H4CK3R in the same 40-second fixed-step attack-pressure probe (593 damage vs. 357); Pac-Man measures 146. His incoming damage scaling is 1.5×, compared with H4CK3R's 1.25×.
- Dark lord has an eight-move cycle: reaper sweep, ground quake, void orbs, rift, five-shard eclipse volley, jumpable eclipse wave, sidestep-only void pillar and camera bugs. Each heavy move gets a readable warning, then a distinct purple/black attack image, debris or hazard shape. The boss pursues more actively and chases players who camp above him.
- All six playable fighters, the six-stage rising story, bosses, arenas, settings and local modes remain wired. No racing gameplay was changed in this update.
- The Mac build is Universal for Apple Silicon and Intel, reports version 0.6.10 / build 17, and passes strict local signature verification.

## Verification

- Source project: **24 suites / 2,275 checks / 0 failures**.
- Exported Mac PCK: **24 suites / 2,275 checks / 0 failures**. The test runner now accepts `--main-pack` to run against the exported pack.
- The journey test completed 18 simulated combat rounds with no retries. Focused boss-pressure results were Pac-Man 146, H4CK3R 357 and Dark lord 593 over the same 40-second fixed-step probe.
- Native captures were reviewed for Pac-Man idle/run/bite/heavy and Dark lord's eclipse-volley, eclipse-wave and void-pillar tell/release. The exported app booted for 120 headless frames; universal architectures and strict codesign verification passed.
- The six package-policy tests pass. Detailed evidence is in [TESTING_0_6_10.md](docs/TESTING_0_6_10.md) and [docs/test-results/v0610](docs/test-results/v0610/).

## Known limits and next steps

- The stronger final boss has automated attack-pressure coverage, not a substitute for family playtesting. Tune again from real child-player sessions if it feels unfair or still too easy.
- This Mac has no Apple Developer ID signing identity. A downloaded app may trigger **System Settings → Privacy & Security → Open Anyway**. Notarization needs a Developer ID certificate and Apple Developer account.
- Physical controller behavior, Intel execution, transferred first launch, keyboard rollover, speaker listening tests, long sessions and family playtesting remain unverified on those devices.
- The supplied Pac-Man source PNGs stay unchanged. The one-eye corrections are separate authored runtime overrides; future replacement Pac-Man poses should preserve the single-eye silhouette.
