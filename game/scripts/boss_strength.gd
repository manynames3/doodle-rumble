extends RefCounted
## Final-stage bosses have individual damage tiers. Scale once at release;
## reflected projectiles keep their existing penalty.
const MULTIPLIERS := {"h4ck3r":1.25,"dark_lord":1.50}

static func damage(source_id: String, base_damage: int) -> int:
	return ceili(float(base_damage) * float(MULTIPLIERS.get(source_id,1.0)))
