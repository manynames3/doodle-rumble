extends RefCounted

## Authoritative walkable tops. Art and collision both read these rectangles.
const PLATFORMS = [
	Rect2(140,480,220,22),
	Rect2(500,440,280,22),
	Rect2(900,370,220,22),
]
const STORY_PLATFORMS = {
	"canopy":[Rect2(134,482,240,24),Rect2(472,369,218,24),Rect2(807,469,280,24)],
	"arcade":[Rect2(120,501,200,24),Rect2(445,447,390,24),Rect2(935,501,220,24)],
	"network":[Rect2(142,495,240,24),Rect2(460,365,190,24),Rect2(690,489,200,24),Rect2(995,375,188,24)]
}
const FLOOR = Rect2(20,600,1240,120)
const QUARRY_PLATFORMS = [
	Rect2(108,505,236,22),
	Rect2(450,465,310,22), # Loose bridge, index 1.
	Rect2(908,500,242,22),
	Rect2(552,326,194,22),
]
const GLITCH_PLATFORMS = [
	Rect2(176,510,204,22),
	Rect2(458,365,196,22),
	Rect2(575,492,224,22),
	Rect2(938,372,178,22),
]
const BOSS_PLATFORMS = [
	Rect2(145,463,205,22),
	Rect2(480,321,236,22),
	Rect2(932,452,208,22),
]
const DESKTOP_PAD = Rect2(588,574,104,26)
const QUARRY_BRIDGE_INDEX = 1
const GLITCH_PADS = [Rect2(156,568,100,32),Rect2(1024,568,100,32)]
const GLITCH_EXITS = [Vector2(1080,599),Vector2(200,599)]

static func get_platforms(kind: String, boss_large: bool = false) -> Array[Rect2]:
	var source: Array = BOSS_PLATFORMS if boss_large else QUARRY_PLATFORMS if kind == "quarry" else GLITCH_PLATFORMS if kind == "glitch" else STORY_PLATFORMS.get(kind,PLATFORMS)
	var result: Array[Rect2] = []
	for rect in source:
		result.append(rect)
	return result
