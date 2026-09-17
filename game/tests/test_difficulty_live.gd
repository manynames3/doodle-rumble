extends SceneTree
## Real match coordinator, fighter physics, passive player input, and AI decisions.
const DT := 1.0 / 60.0
const Difficulty = preload("res://scripts/difficulty.gd")
var game
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + label)

func run() -> void:
	await process_frame
	check("--isolated-qa" in OS.get_cmdline_user_args(), "real matches use isolated preferences")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.test_mode = true
	game.set_process(false)
	game.set_physics_process(false)
	game.optional_hazards = true
	var results := {}
	for stage in [0, 4, 5]:
		var times := []
		var openings := []
		for level in range(3):
			game.mode = "arcade"
			game.arcade_stage = stage
			game.selected[0] = "orange"
			game.difficulty_level = level
			game.start_match()
			game.countdown = 0.0
			game.ai.rng.seed = 42
			openings.append(game.hazard_clock)
			var first_attack := -1.0
			for frame in range(540):
				await physics_frame
				game._physics_process(DT)
				if game.second.attack_serial > 0:
					first_attack = (frame + 1) * DT
					break
			times.append(first_attack)
			check(first_attack > 0.0, "stage %d first attack occurs without scripted input at level %d" % [stage, level])
			check(game.hazards.marks.size() <= 1, "stage %d uses at most one live hazard zone" % stage)
		check(times[0] > times[1] and times[1] > times[2], "stage %d first physical attack is sooner on each difficulty" % stage)
		check(openings[0] > openings[1] and openings[1] > openings[2], "stage %d optional hazard opens sooner on each difficulty" % stage)
		check(openings[0] == Difficulty.opening_hazard_delay(0), "stage %d Easy retains eight-second initial hazard" % stage)
		results[stage] = {"attack_seconds": times, "hazard_open_seconds": openings}
	print("LIVE_DIFFICULTY_PRESSURE %s" % str(results))
	game.queue_free()
	await process_frame
	root.get_node("Sound").shutdown()
	print("DIFFICULTY_LIVE_TEST_RESULT checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
