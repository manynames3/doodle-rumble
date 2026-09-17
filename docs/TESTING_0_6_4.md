# Doodle Rumble v0.6.4 verification

Tested on Apple M1, macOS, standard Godot 4.7.2. Automated runs used isolated preferences and silent audio; native captures used a hidden rendering viewport without taking focus from a player's game.

## Round-result change

The result now shows the two real match actors, at their normal rig scales, against the unchanged arena camera. There are no enlarged substitute portraits. The result ribbon fades in without scaling. The winner's rig performs a short hop and ongoing wave/show-off; the loser folds onto the floor with four orbiting stars. A separate result-defeated state handles timeout losses with health remaining. A tied round sets neither victory nor defeat. Next round and rematch clear these flags. Reduced motion freezes the poses and star positions.

The integration test asserts unchanged camera zoom and fighter rig scale, visible match actors, knockout and timeout defeat, tie behavior, and next-round/rematch reset. Existing physics, damage, AI, story, local battle, music and racing suites are rerun for regression coverage.

Native 1280×720 captures in `test-results/v064/` include `round_playing.png`, `round_result_orange_wins.png`, `round_result_orange_wins_later.png`, `round_result_dark_lord_loses.png`, `round_result_dark_lord_wins.png` and `round_result_reduced_motion.png`. They were visually inspected for the actual stage composition, fixed scale, readable silhouettes, floor contact, star placement and oversized Dark lord fit.

## Automated suites and export

The 22 source suites passed 1,890 checks. The exported Mac PCK was exercised with the same 22 suites and 1,890 checks. The gameplay integration suite includes the full six-stage journey and three local matches across 18 rounds with no retries. Source and packaged suite summaries are in `test-results/v064/source-logs/results.json` and `test-results/v064/packaged-logs/results.json`.

The Universal Mac app is locally ad-hoc signed; strict deep signature verification passed. The exported application was launched headlessly for 120 frames. Archive integrity and a clean extracted-copy launch are recorded in the delivery receipt and release checks.

## Limits

The app is not notarized. Physical gamepad input, Intel Mac execution, keyboard rollover, transferred first launch and family playtesting have not been performed. The screenshots verify native rendering on this M1 machine, not display behavior on every Mac.
