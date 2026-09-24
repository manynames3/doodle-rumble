# v0.7.1 update checks

Godot 4.7.2 editor project scan and a 120-frame headless application startup completed without script errors. The new Universal app bundle passed strict deep signature verification and completed a 120-frame headless launch with an isolated QA profile. The Mac ZIP is `Doodle_Rumble_Mac_v0.7.1.zip` (SHA-256 `abe895888415eb86d9408222393f5b3179622f87731073df5eb6e64427053626`). This is a maintenance patch for the paper-edge option and custom-fighter rendering path.

No automated regression suite or native frame-time benchmark was run after the v0.7.1 changes. The 30-suite / 2,621-check report and 300-frame art benchmark in [TESTING_0_7_0.md](TESTING_0_7_0.md) describe the earlier source revision and are not evidence for this patch. Please check the White edge switch with an imported fighter and compare a high-detail custom fighter in a real match on the target Mac.

The Mac app was built from a fresh exported game pack using the verified Godot 4.7.2 Universal runtime from the prior local app because the matching macOS export template is absent on this machine. The bundle is ad-hoc signed, not notarized.
