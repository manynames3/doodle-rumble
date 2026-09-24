extends RefCounted
## Authoritative combat data for workshop doodles. Art never changes these ranges.

const KITS := {
	"pixel_pick": {"name":"Pixel Pick", "weapon":"custom_pick", "special":"ore_pop", "special_name":"Ore Pop", "description":"Chip forward, drop from above, then pop three ink ore seams."},
	"bone": {"name":"Big Bone", "weapon":"custom_bone", "special":"fossil_fetch", "special_name":"Fossil Fetch", "description":"Sweep wide, rise with a bone, then throw it out and back."},
	"bat": {"name":"Slugger Bat", "weapon":"custom_bat", "special":"home_run", "special_name":"Home Run", "description":"Swing to the side or in the air; time a heavy launcher to return a shot."},
	"ball": {"name":"Bouncy Ball", "weapon":"custom_ball", "special":"swerve_shot", "special_name":"Swerve Shot", "description":"Kick up close or volley in the air, then bank a curved ball off the stage."},
	"rubber_chicken": {"name":"Rubber Chicken", "weapon":"custom_chicken", "special":"cluckquake", "special_name":"Cluckquake", "description":"Squeak-slap or bonk from above. Unleash a huge chicken-powered squeak around you."},
	"giant_crayon": {"name":"Jumbo Crayon", "weapon":"custom_crayon", "special":"rainbow_ruckus", "special_name":"Rainbow Ruckus", "description":"Whack with jumbo wax, then scribble a bright, jumpable rainbow across the floor."},
}

static func ids() -> Array[String]:
	var result: Array[String] = []
	for id in KITS.keys(): result.append(str(id))
	return result

static func info(kit: String) -> Dictionary:
	return KITS.get(kit, KITS.pixel_pick).duplicate(true)

static func ground(kit: String) -> Dictionary:
	match kit:
		"bone": return {"name":"Big Bone", "damage":15, "reach":128.0, "windup":0.16, "active":0.14, "recovery":0.36, "knockback":365.0, "hitbox_top":115.0, "hitbox_height":107.0}
		"bat": return {"name":"Slugger Bat", "damage":16, "reach":121.0, "windup":0.16, "active":0.14, "recovery":0.36, "knockback":385.0, "hitbox_top":113.0, "hitbox_height":106.0}
		"ball": return {"name":"Bouncy Ball", "damage":12, "reach":91.0, "windup":0.16, "active":0.14, "recovery":0.36, "knockback":300.0, "hitbox_top":108.0, "hitbox_height":100.0}
		"rubber_chicken": return {"name":"Rubber Chicken", "damage":15, "reach":124.0, "windup":0.16, "active":0.14, "recovery":0.36, "knockback":355.0, "hitbox_top":113.0, "hitbox_height":105.0}
		"giant_crayon": return {"name":"Jumbo Crayon", "damage":14, "reach":112.0, "windup":0.16, "active":0.14, "recovery":0.36, "knockback":345.0, "hitbox_top":110.0, "hitbox_height":105.0}
		_: return {"name":"Pixel Pick", "damage":14, "reach":116.0, "windup":0.16, "active":0.14, "recovery":0.36, "knockback":350.0, "hitbox_top":113.0, "hitbox_height":114.0}

static func air(kit: String) -> Dictionary:
	match kit:
		"bone": return {"air_kind":"bone_rise", "damage":15, "reach":108.0, "windup":0.16, "active":0.14, "recovery":0.36, "knockback":390.0, "launch_y":-350.0, "hitbox_top":164.0, "hitbox_height":135.0}
		"bat": return {"air_kind":"bat_sweep", "damage":16, "reach":126.0, "windup":0.16, "active":0.14, "recovery":0.36, "knockback":385.0, "hitbox_top":135.0, "hitbox_height":120.0}
		"ball": return {"air_kind":"ball_volley", "damage":12, "reach":102.0, "windup":0.16, "active":0.14, "recovery":0.36, "knockback":315.0, "hitbox_top":111.0, "hitbox_height":133.0}
		"rubber_chicken": return {"air_kind":"chicken_peck", "damage":15, "reach":119.0, "windup":0.16, "active":0.14, "recovery":0.36, "knockback":375.0, "hitbox_top":151.0, "hitbox_height":132.0}
		"giant_crayon": return {"air_kind":"crayon_swoop", "damage":14, "reach":126.0, "windup":0.16, "active":0.14, "recovery":0.36, "knockback":375.0, "hitbox_top":145.0, "hitbox_height":127.0}
		_: return {"air_kind":"pick_drop", "damage":14, "reach":103.0, "windup":0.16, "active":0.14, "recovery":0.36, "knockback":365.0, "launch_y":160.0, "hitbox_top":64.0, "hitbox_height":110.0}

static func special(kit: String) -> Dictionary:
	match kit:
		"bone": return {"damage":22, "windup":0.34, "active":0.14, "recovery":0.55, "reach":128.0, "knockback":420.0}
		"bat": return {"damage":24, "windup":0.42, "active":0.12, "recovery":0.55, "reach":136.0, "knockback":590.0, "launch_y":-520.0, "hitbox_top":125.0, "hitbox_height":120.0}
		"ball": return {"damage":22, "windup":0.34, "active":0.14, "recovery":0.55, "reach":100.0, "knockback":380.0}
		"rubber_chicken": return {"damage":22, "windup":0.40, "active":0.14, "recovery":0.55, "reach":185.0, "knockback":485.0}
		"giant_crayon": return {"damage":22, "windup":0.38, "active":0.14, "recovery":0.55, "reach":350.0, "knockback":425.0}
		_: return {"damage":22, "windup":0.34, "active":0.14, "recovery":0.55, "reach":116.0, "knockback":400.0}
