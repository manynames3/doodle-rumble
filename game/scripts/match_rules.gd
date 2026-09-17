extends RefCounted
## No rendering dependencies: scoring and time are deterministic and testable.
const ROUND_SECONDS := 60.0
var scores = [0, 0]
var remaining = ROUND_SECONDS
var round_number = 1
var finished = false
var last_winner = -1
var resolved = false

func reset() -> void:
	scores = [0, 0]
	remaining = ROUND_SECONDS
	round_number = 1
	finished = false
	last_winner = -1
	resolved = false

func next_round() -> void:
	remaining = ROUND_SECONDS
	round_number += 1
	last_winner = -1
	resolved = false

func tick(delta: float, hp1: int, hp2: int) -> bool:
	if finished or resolved:
		return false
	remaining = maxf(0, remaining-delta)
	if hp1 > 0 and hp2 > 0 and remaining > 0:
		return false
	last_winner = -1 if hp1 == hp2 else (0 if hp1 > hp2 else 1)
	resolved = true
	if last_winner >= 0:
		scores[last_winner] += 1
	finished = scores[0] >= 2 or scores[1] >= 2
	return true
