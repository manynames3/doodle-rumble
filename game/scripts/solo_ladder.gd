extends RefCounted
## The 1P journey is ordered independently from the six selectable fighters.
const STAGES := [
	{"opponent":"blue", "arena":"desktop", "difficulty":"Very easy", "ai_level":0, "challenge_rank":1},
	{"opponent":"red", "arena":"quarry", "difficulty":"Easy", "ai_level":1, "challenge_rank":2},
	{"opponent":"green", "arena":"canopy", "difficulty":"Medium", "ai_level":2, "challenge_rank":3},
	{"opponent":"crackle", "arena":"quarry", "difficulty":"Hard", "ai_level":3, "challenge_rank":4},
	{"opponent":"pac_man", "arena":"arcade", "difficulty":"Hard", "ai_level":3, "challenge_rank":5},
	{"opponent":"h4ck3r", "arena":"network", "difficulty":"Very hard", "ai_level":4, "challenge_rank":6},
	{"opponent":"fuse", "arena":"network", "difficulty":"Boss", "ai_level":5, "challenge_rank":7},
	{"opponent":"dark_lord", "arena":"glitch", "difficulty":"Final boss", "ai_level":5, "challenge_rank":8}
]

static func stage(index: int) -> Dictionary:
	return STAGES[clampi(index,0,STAGES.size()-1)]
