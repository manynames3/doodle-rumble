# Local Mac build v0.7.8 — verification

Prepared on an Apple M1 Mac with Godot 4.7.2 and the Compatibility renderer. This is a local playable build of the current source; it is not a published GitHub release.

- Full source regression: **30 suites / 2,867 checks / zero failures**. QA used isolated preferences and did not use the family's saved fighters or progression.
- The exported app's embedded PCK passed the focused music suite (**114 checks**) and premium-audio suite (**188 checks**).
- The exported app completed a **120-frame headless startup smoke test**. `codesign --verify --deep --strict` passed, and `file` confirmed both arm64 and x86_64 executable slices.
- The app is ad-hoc signed and not notarized. First launch on this or another Mac may require **System Settings → Privacy & Security → Open Anyway**.
- Audio checks verify resource loading, cue routing, signal levels, phase crossfades and headroom. Music and effects were not auditioned on speakers or headphones; external audio hardware, GUI launch, and another Mac remain untested.
- Doodle Rally's gameplay and assets were not changed.

The local playable app is `builds/mac-v0.7.8/Doodle Rumble.app`. An app-only ZIP was created in the workspace outputs folder, outside this repository; no v0.7.8 GitHub release has been published.
