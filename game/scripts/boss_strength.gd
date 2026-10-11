extends RefCounted
## Final-stage bosses have individual damage tiers. Scale once at release;
## reflected projectiles keep their existing penalty.
const MULTIPLIERS := {"crackle":1.20,"h4ck3r":1.25,"fuse":2.0625,"dark_lord":1.95}
const Difficulty = preload("res://scripts/difficulty.gd")
const EASY_DARK_LORD_DAMAGE_FACTOR := 0.70

static func damage(source_id: String, base_damage: int, difficulty: int = Difficulty.MEDIUM) -> int:
	var amount := ceili(float(base_damage) * float(MULTIPLIERS.get(source_id,1.0)))
	if source_id == "dark_lord" and Difficulty.normalized_level(difficulty) == Difficulty.EASY and amount > 0:
		amount = maxi(1, roundi(float(amount) * EASY_DARK_LORD_DAMAGE_FACTOR))
	return amount
