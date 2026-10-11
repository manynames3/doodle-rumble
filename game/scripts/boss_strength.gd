extends RefCounted
## Final-stage bosses have individual damage tiers. Scale once at release;
## reflected projectiles keep their existing penalty.
const MULTIPLIERS := {"crackle":1.20,"h4ck3r":1.25,"fuse":2.0625,"dark_lord":1.95}

static func damage(source_id: String, base_damage: int) -> int:
	return ceili(float(base_damage) * float(MULTIPLIERS.get(source_id,1.0)))
