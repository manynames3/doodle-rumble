# Doodle Rumble working direction

The user explicitly authorized upgrading Doodle Rally on 2026-09-13 after the racing review. Implement the racing improvements while preserving the working fighting game. Keep racing saves, gameplay, art and music in dedicated components; shared settings and audio must continue to work for both games.

Finish Purple and Yellow as selectable fighters alongside Orange, Red, Green and Blue. Preserve the increasing six-stage journey: Blue, Red, Green, Pac-Man, H4CK3R, then Dark lord.

Combat art direction: an animated child's sketchbook has become a playable battle. Keep the existing illustrated backgrounds. Favor substantial hollow-headed fighters, oversized weapons, uneven black ink outlines, handwritten compact HUD, dramatic readable color effects, local light spill, layered desk props, and reachable platforms. Inspect actual game renders against the supplied references; compiling alone is not completion. Preserve fixed physics damage timing and recovery protection, and support reduced motion.

Use subagents proactively for independent useful work. Optimize first-pass correctness and total efficiency. Choose models deliberately rather than inheriting Astra for routine tasks:
- Terra High: reconnaissance, asset discovery, dependency tracing, codebase mapping, low-risk mechanical changes.
- Sol High: substantive gameplay, UI, animation, VFX, rendering, debugging, integration, performance.
- Sol Extra High: difficult implementation spanning interacting systems, subtle physics/state/animation issues, high-risk debugging or refactoring.
- Astra Ultra: architecture, difficult high-level decisions, visual/art-direction judgment, ambiguous cross-system planning, final integrated review.

Keep BUILD_STATUS.md accurate. Deliver runnable project and Mac export, distinguish automated/runtime tests from physical-device tests, and use isolated preferences for automated QA. Do not disturb a user's running game instance.
