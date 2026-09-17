# v0.6.1 verification

Tested 2026-09-14 on Apple M1 / macOS using standard Godot 4.7.2 and the Compatibility renderer. QA used separate per-process preferences, never the player's saved game or running instance.

## Source

**1838 checks across 22 suites passed.** Existing round-timer assertions and menu navigation tests were updated for the requested 60-second/two-page behavior, then the affected suites were rerun. The runner rejects script errors and warnings.

| Suite | Checks |
| --- | ---: |
| arena variety | 64 |
| boot audio | 18 |
| boss strength | 28 |
| boss update | 74 |
| combat depth | 343 |
| controls depth | 41 |
| core | 112 |
| difficulty | 76 |
| difficulty live | 28 |
| ending | 45 |
| game | 133 |
| menus | 164 |
| music | 82 |
| new fighters | 164 |
| pacman | 29 |
| pacman pressure | 26 |
| premium audio | 135 |
| premium story | 64 |
| racing | 48 |
| rally library | 21 |
| rally sim | 72 |
| story worlds | 71 |

The game-loop input bot completed all six story matches and three local matches in 18 rounds, with no retries. Racing integration completed six two-lap races. Story/score branch tests also use explicit fixtures; those are distinct from live input-driven matches.

The menus test covers difficulty selection at story/quick-match start, saved-story difficulty restoration, large stage selection, Back preserving fighters/arena, separate local controls, settings focus containment and Escape after Pause is remapped. Profile tests cover old saves defaulting to Easy, invalid values, saved difficulty and backup behavior.

## Difficulty evidence

Easy preserves previous profile timing except the requested H4CK3R buff. H4CK3R approach increased from 0.91 to 0.99, recovery from 0.62s to 0.50s, opening rest from 1.0s to 0.85s, and hazard execution from 2.25s to 2.0s. Higher-level AI rests use 0.86/0.72 multipliers; decision intervals use 0.90/0.80. Optional hazard spacing uses 0.82/0.68 with a 4-second safety floor. Attack warning durations are unchanged and there is at most one live hazard zone.

In a 45-second controller simulation with passive mock targets, attack decisions increased from Easy to Medium to Hard: ordinary AI **22/24/28**, H4CK3R **18/20/22**, Dark lord **23/24/25**. These are controller decisions, not guaranteed landed hits.

Separate full-scene tests used real fighters. First physical attacks occurred at **3.50/2.93/2.80s** for Blue, **2.68/2.52/2.35s** for H4CK3R, and **1.78/1.68/1.58s** for Dark lord. First optional hazards occurred at **8.00/6.56/5.44s**. These demonstrate applied pacing changes; subjective boss fairness still needs family playtesting.

## Native visual inspection

All six special previews were rendered through complete 4.4-second cycles in normal and reduced-motion modes: **3,180 frames**. A separate unclipped probe confirmed no bright painted content (alpha at least 100/255) crosses the reserved artwork bounds. Soft glow is contained by the art-area clip. Actual full selection pages and widest poses were inspected, including the header and SPECIAL PREVIEW footer. This avoids treating an idle pose or a clipped render alone as proof of fit.

Native captures of Quick Match stages, 2P stages, both difficulty states, the story fighter page, the populated badge journal and the empty journal were inspected. The separate stage cards are 390×210 logical pixels; their illustrated regions are 380×157, compared with the old 148×59 thumbnails. Full names and the selected state are readable. The final exported PCK was used for another complete set of these screen captures.

## Mac export

The Universal app exported successfully. Its executable contains arm64 and x86_64; strict deep local signature verification passed. The app launched headlessly with isolated preferences and exited cleanly after 120 frames.

**834 checks passed against the exported PCK**, across core, menus, new fighters, difficulty, live difficulty, premium story, full game loop, ending and racing. That includes another 18 live combat rounds and six complete races. Native packaged-resource captures completed without rendering/script errors. Source and Mac ZIP integrity and packaged-source hashes are checked by the delivery script.

The app is locally ad-hoc signed, not Apple-notarized. Intel execution, physical controllers, keyboard rollover, a transferred first launch, long sessions and family balance/fun remain unverified. Existing ending and audio assets are preserved; this update does not claim a new listening study.

## Reproduce

```sh
python3 game/tools/run_tests.py --godot /absolute/path/to/Godot --logs test-logs
godot --path game res://tests/capture_showcase_fit.tscn -- --isolated-qa --silent-qa
godot --path game --script res://tools/capture_selection_update.gd -- --isolated-qa --silent-qa --capture-dir=/absolute/path/to/output
```

Logs, result summaries and final screenshots are included in `docs/test-results/v061/`. Prior release reports describe earlier versions.
