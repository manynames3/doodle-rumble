extends RefCounted
## Short, replayable scenes. Nothing here controls combat or its difficulty.
const CHAPTERS := [
	{
		"title":"THE GREAT UNSAVED DISASTER", "short":"The missing star", "color":"ffad38",
		"setup":"The kids went for a snack. Their drawings went for an adventure.\nThen somebody stole the Save Star. Uh-oh.",
		"before":[["blue","I built a security wall. Very secure. Forgot the door."],["hero","Did you see a glowing star?"],["blue","Went that way. First: a wall-strength test! Liability forms are imaginary."]],
		"after":[["blue","Excellent test. The wall has become several doors."],["hero","Come help us save the drawing!"],["blue","Yes! I'll bring my emergency blocks. They're just regular blocks, but nervous."]],
		"clue":"A trail of golden pixels leads into the quarry.", "challenge":"Land an aerial attack", "goal":"air", "tip":"Jump, then attack. Your air move is different from your ground swing."
	},
	{
		"title":"PERMIT TO BONK", "short":"Permit to bonk", "color":"ff5967",
		"setup":"Red has mistaken the golden trail for a building plan.\nThe quarry now has six bridges and absolutely no safety inspector.",
		"before":[["red","STOP! Hard-hat zone. Please put a hard hat on your hard hat."],["hero","We're following a stolen star."],["red","You'll need a bridge. I build bridges by hitting the problem really hard."]],
		"after":[["red","Bridge complete! Slightly flatter than the sketch."],["hero","That's a path."],["red","A bridge with excellent ground support. You're welcome."]],
		"clue":"The trail slips between the pages of a paper forest.", "challenge":"Dodge through one attack", "goal":"counter", "tip":"Watch Red lift the hammer. Dodge through the swing, then counter."
	},
	{
		"title":"PLEASE DO NOT TRIM THE DRAGONS", "short":"Paperwork jungle", "color":"9aff73",
		"setup":"Green is pruning the Paper Canopy. The trees are fine.\nThe paper dragons have filed a strongly folded complaint.",
		"before":[["green","Quiet! I'm teaching this tree to be a helicopter."],["hero","Have you seen the Save Star?"],["green","A hungry yellow circle took it. Catch me and I'll show you the shortcut!"]],
		"after":[["green","Good footwork. Terrible gardening. I like it."],["hero","Is that tree actually flying?"],["green","Eventually. For now it's a ceiling fan with ambitions."]],
		"clue":"Arcade Afterglow is open. The snack machine is suspiciously quiet.", "challenge":"Land two special attacks", "goal":"specials", "tip":"Green recovers after a dash. Let the slash pass, then take your turn."
	},
	{
		"title":"THE ALL-YOU-CAN-BYTE BUFFET", "short":"Snack attack", "color":"ffdc53",
		"setup":"Pac-Man ate the gate tokens, the high-score sign,\nand a very convincing picture of a sandwich.",
		"before":[["pac_man","Welcome to my restaurant. The menu is: everything."],["hero","Did you eat our Save Star?"],["pac_man","Too spicy. I gave it to H4CK3R. Dessert first, directions later!"]],
		"after":[["pac_man","Okay! Okay! The token gate is yours."],["hero","And the sign?"],["pac_man","It said HIGH SCORE. I thought it was a serving suggestion."]],
		"clue":"H4CK3R has the star. Follow the signal to Neon Switchyard.", "challenge":"Win a round with half your health", "goal":"healthy", "tip":"Jump the charge. A closed mouth means Pac-Man is catching his breath."
	},
	{
		"title":"PLEASE ACCEPT THESE COOKIES", "short":"Cookie trouble", "color":"6ceaff",
		"setup":"H4CK3R runs the network. His password is extremely secret.\nIt is written on seven sticky notes and one camera bug.",
		"before":[["h4ck3r","Access denied! First, accept all cookies."],["hero","Chocolate chip?"],["h4ck3r","Browser cookies. Dark lord took the good ones AND your star. Initiating dramatic firewall!"]],
		"after":[["h4ck3r","Firewall disabled. It was mostly a screensaver."],["hero","Will you open the core?"],["h4ck3r","Yes. If anyone asks, you guessed my password. It was NOT password123. There was a four."]],
		"clue":"One final page. One very dramatic doodle. Bring the colors home.", "challenge":"Land an aerial attack and a special", "goal":"mix", "tip":"Move away from the cursor stamp. Attack while H4CK3R reboots."
	},
	{
		"title":"HIS ROYAL DARKNESS NEEDS A NAP", "short":"Lights, please!", "color":"d397ff",
		"setup":"Dark lord has installed Permanent Dramatic Lighting.\nHe says the Save Star is his crown jewel. The crown disagrees.",
		"before":[["dark_lord","ALL COLORS SHALL BOW BEFORE ME!"],["hero","Even beige?"],["dark_lord","ESPECIALLY BEIGE. Wait. No laughing during my final-boss speech!"]],
		"after":[["dark_lord","I only wanted a turn being the main character."],["hero","You can join us. But the star belongs to everybody."],["dark_lord","Fine. I shall become... Assistant Manager of Purple. With a cape."]],
		"clue":"The Save Star returns to the desk. Every doodle gets a place on the page.", "challenge":"Win using a perfect dodge", "goal":"counter", "tip":"Watch the warning, avoid the big strike, and use the recovery window."
	}
]
const HERO_REPLIES := {"orange":"Orange", "red":"Red", "green":"Green", "blue":"Blue", "purple":"Purple", "yellow":"Yellow"}
static func chapter(index: int) -> Dictionary:
	return CHAPTERS[clampi(index,0,5)].duplicate(true)
static func goal_met(index: int, stats: Dictionary) -> bool:
	match CHAPTERS[clampi(index,0,5)].goal:
		"air": return stats.get("air",false)
		"counter": return stats.get("counter",false)
		"specials": return int(stats.get("special_hits",0)) >= 2
		"healthy": return stats.get("healthy",false)
		"mix": return stats.get("air",false) and int(stats.get("special_hits",0)) > 0
	return false
