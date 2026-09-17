extends RefCounted
## One outgoing-damage rule for the two final story bosses. Scale a payload
## only when it is created; reflected projectiles keep their existing penalty.
const MULTIPLIER := 1.25
const EMPOWERED_IDS := ["h4ck3r", "dark_lord"]

static func damage(source_id: String, base_damage: int) -> int:
	if source_id in EMPOWERED_IDS:
		return ceili(float(base_damage) * MULTIPLIER)
	return base_damage
