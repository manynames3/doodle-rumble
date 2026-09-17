# v0.6.0 release verification

Date: 2026-09-14. Host: Apple M1 macOS. Engine: standard Godot 4.7.2, GDScript, OpenGL Compatibility. Tests and native captures use isolated QA preferences and do not interrupt the user's running game.

## Source tests

1,708 checks across 20 suites passed. The final menu, story and ending suites were rerun after the focus, reduced-motion and result-screen fixes. The source runner rejects script errors and warnings as failures.

| Suite | Checks |
| --- | ---: |
| Arena variety | 64 |
| Boot and audio | 18 |
| Boss strength | 28 |
| Boss update | 74 |
| Combat depth | 343 |
| Controls depth | 41 |
| Core combat | 112 |
| Ending transitions and focus | 45 |
| Game loop | 133 |
| Menus | 140 |
| Music | 82 |
| New fighters | 162 |
| Pac-Man | 29 |
| Pac-Man pressure | 26 |
| Premium audio | 135 |
| Premium story | 64 |
| Racing integration | 48 |
| Rally library | 21 |
| Rally simulation | 72 |
| Story worlds | 71 |

The game-loop bot completed all six story matches with optional hazards on and three local two-player matches: 18 rounds, no retries. The bot uses normal movement, attacks, specials, health and scoring. Story comic transitions, completion rewards and score branches additionally use explicit result fixtures. Racing integration completed six two-lap races. These tests establish working paths, not human difficulty or fun.

The premium combat tests cover Purple's facing-sensitive shield, guard timing, reflection ownership and one-reflection limits, AI response windows, damage timing, recovery protection and existing counters/aerial attacks. New story tests cover six chapter scenes, continuation, badge/challenge logic, save backup recovery, once-only completion and damage attribution without hazard credit. A separate two-process seed/read test passed three checks using the same named QA profile, verifying saved progress and fighter/hazard choices survive a fresh launch.

## Exported resources and native app

The v0.6.0 Universal app exported successfully with the matching macOS template. The executable contains arm64 and x86_64. Strict deep local signature verification passed. A separate native executable launched headlessly with isolated preferences and exited cleanly after 120 frames.

Seven suites were run with the actual exported PCK as the main pack: core (112), menus (140), premium story (64), ending (45), premium audio (135), game loop (133) and racing (48). **677 checks passed**, including another 18 live combat rounds and six complete races. These runs resolve scripts/assets/autoloads from the packaged resources, rather than the editor's source directory. After the movie encode was corrected, the app was rebuilt, the ending suite passed again against source and exported resources (45 checks each), and the complete movie played from the final exported PCK with 32 playback/routing checks. The rebuilt app also passed signature verification and a fresh native startup smoke check.

This does not establish Intel execution or successful first launch after downloading on a second Mac. The app is ad-hoc signed and not Apple-notarized; the host has no Developer ID signing identity.

## Render and media review

Native Godot renders were inspected at 1280×720 using a hidden root window and rendered SubViewport. Coverage includes the updated title, six-card selection/live preview, story journal, all six chapter introductions and punchlines, settings, practice, pause and victory results. Separate fighter captures cover idle, anticipation, active attacks, recovery, victory and defeat, plus live spin/guard/reflect effects. Hazard captures cover layered warnings and active canopy effects.

Fixes from review included excessive plated limb weight, dialogue/actor overlap, stale countdown text under results, reduced-motion preview blinking, and keyboard focus escaping behind the ending. No parser, draw-triangulation or runtime errors remained in final captures. Reduced motion keeps the preview pose and its supplementary effects steady.

The closing movie was regenerated as 30 seconds of 1280×720 Ogg Theora video at 24 fps with the original Vorbis score. Encoded frames were inspected at six story beats. An initial higher-bitrate encode showed incorrect late frames in native Godot playback despite decoding correctly with FFmpeg. The final 6 MB q5/GOP48 encode fixed this. Exact-path native playback passed 32 checks: captures at six points showed the proper scenes, including the Save Star return at 22.27 seconds and closing card at 27.49 seconds; playback completed and released music ownership. FFmpeg independently decoded all 720 frames without error. Native and decoded frames are in the delivery evidence directory.

Audio tests checked original arrangement identities, stream routing, phase changes, menu/weapon/guard/warning cues, shared Rally ownership, pause/mute behavior and PCM headroom. No claim is made that these checks replace a listening pass.

## Reproduce

```sh
python3 game/tools/run_tests.py --godot /absolute/path/to/Godot --logs test-logs
godot --headless --path game --script res://tools/check_story_restart.gd -- --isolated-qa --silent-qa --qa-profile=resume-check --phase=seed
godot --headless --path game --script res://tools/check_story_restart.gd -- --isolated-qa --silent-qa --qa-profile=resume-check --phase=read
```

Never direct QA at a player's preferences. Test logs and current screenshots are supplied under `docs/test-results/v060/`; historical documents are retained separately.

## Still requires physical or human verification

Physical controllers, keyboard rollover, Intel hardware, first transferred launch, extended play sessions, performance on lower-end Macs, speaker/headphone listening, family readability, boss fairness and repeat-play interest. Automated matches are not a consumer study or a measured quality rating.
