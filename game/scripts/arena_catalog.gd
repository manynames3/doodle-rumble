extends RefCounted
const ORDER := ["desktop","quarry","glitch","canopy","arcade","network"]
const NAMES := {"desktop":"Desktop Dojo","quarry":"Block Quarry","glitch":"Glitch Core","canopy":"Paper Canopy","arcade":"Arcade Afterglow","network":"Neon Switchyard"}
const SHORT_NAMES := {"desktop":"Desktop","quarry":"Quarry","glitch":"Glitch Core","canopy":"Paper Canopy","arcade":"Afterglow","network":"Switchyard"}
const STORY := {
 "desktop":"A drawing window flickers. The first doodle takes a step.",
 "quarry":"The drawings build a path through a world of blocks.",
 "canopy":"Green guards the last page still growing with color.",
 "arcade":"Pac-Man has swallowed the tokens that power the gate.",
 "network":"H4CK3R controls the signal into Dark lord's core.",
 "glitch":"Every stolen color leads here. Bring the light back."
}
static func hazard_cycle(kind: String) -> Array:
	match kind:
		"canopy": return ["paper_swarm","ink_geyser","eraser_drop"]
		"arcade": return ["pixel_pinball","cursor_stamp","pixel_pinball"]
		"network": return ["circuit_zip","cursor_stamp","camera"]
		"glitch": return ["circuit_zip","camera","ink_geyser","eraser_drop"]
		_: return ["eraser_drop","ink_geyser","cursor_stamp"]
