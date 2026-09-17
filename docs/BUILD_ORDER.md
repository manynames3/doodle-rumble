# Build order

> Archived milestone plan from the supplied package. See ../BUILD_STATUS.md for completed work and current next steps.

Use a small, complete playable slice before expanding the roster. These are development milestones, not completed work.

## 1. Prove that fighting feels fun

Build one side-view arena with a floor, safe side walls, and one low platform. Add two placeholder stick figures, movement, jump, one sword attack, health, a win state, and rematch. Use a stationary practice target before adding a computer opponent. Include the desktop window frame from the start.

Done when someone unfamiliar with the game can move, jump, hit, win, and restart without verbal instruction. Test a target of 30 seconds to the first successful hit.

## 2. Make the drawings move

Trace one approved child-drawn fighter and its weapon. Animate idle, run, jump/fall, attack, hit reaction, and victory. Attach weapon art at a hand pivot. Put the hitbox on a separate node so visual size does not accidentally determine game balance. Verify the kids recognize their own character immediately.

## 3. Complete the first four fighters

Add Orange with pitchfork, Red with hammer, Green with sword, and Blue with pickaxe. Give everyone the same movement and button layout. Add one special per fighter, with a visible cooldown. Starting loadouts are provisional. Use shared fighter logic and separate data rather than copying a complete script per character.

## 4. Make a complete family game

Add character selection, gentle and standard computer difficulty, training, local two-player mode, controller assignment, pause, sound controls, reduced motion, and rematch. Keep all four starting characters available. Pause on loss of focus or controller disconnect. Add a short optional control practice with no failure state.

## 5. Test and export for Mac

Export with matching Godot export templates. Test on the actual family Mac, including a full match, sleep/wake, full-screen toggle, sound, and the intended controllers. Check both Apple Silicon and Intel only if both are distribution targets. Follow the official signing and notarization instructions when preparing a downloadable release.

## Initial rules

- Each fighter has 100 health. A round ends at zero health or 90 seconds. At time-out, higher remaining health wins; equal health is a draw and the round is replayed.
- Best of three rounds. The result screen shows Rematch first, then Change character.
- No damage from the first arena’s boundaries. Landings remain forgiving.
- Basic attacks have a short windup, active hit window, and recovery. Hit each opponent at most once per swing.
- Special attacks share a starting cooldown of 6 seconds. Display their readiness with both an icon and text.
- Brief hit stun and knockback should prevent a single repeated attack from trapping an opponent indefinitely.
- Gentle AI approaches in bursts, pauses before attacking, and gives the child room to react. It does not read future inputs.
- Use an optional hold-to-repeat basic attack. Jump and special activate once per press.

## Later additions

Add Purple and Yellow, then Sign guy and H4ck3r, then a Dark lord boss with camera bugs. Add Pac-man as a guest concept. An animator mode could let an adult use a cursor to create obstacles while a child controls a fighter; it is a separate mode and comes after the basic game.

Add a block quarry and glitch lab once the desktop arena is stable. Breakable blocks, weapon pickups, four-player play, online play, and a level editor belong in later releases.

## Playtest questions

- Can each child start a match and land a hit within 30 seconds?
- Can they identify their fighter, weapon, health, and ready special without help?
- Is the hammer’s slow windup obvious? Can they jump over arrows?
- Can either player escape repeated hits?
- Does a rematch start within two deliberate selections?
- Can two players reliably hold their required keys simultaneously on this keyboard?
- Do movement, attack timing, and match rules remain correct at different frame rates?
- Can a new fighter use the shared controller without changing existing fighters?

Budget the first four-character build as several focused development stages. Art complexity, the children’s changes, controller testing, and Mac release packaging will determine the calendar; this plan does not promise a fixed completion date.
