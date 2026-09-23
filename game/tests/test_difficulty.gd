extends SceneTree
## Difficulty pace, story compatibility, and hazard fairness without touching a live profile.
const Difficulty = preload("res://scripts/difficulty.gd")
const AI = preload("res://scripts/ai_controller.gd")
const PacAI = preload("res://scripts/pacman_controller.gd")
const HackerAI = preload("res://scripts/hacker_controller.gd")
const BossAI = preload("res://scripts/boss_controller.gd")
const Rules = preload("res://scripts/match_rules.gd")
const Profile = preload("res://scripts/story_progress.gd")
const Hazards = preload("res://scripts/hazards.gd")
const DT := 1.0 / 60.0
var checks := 0
var failures := 0

class FakeRig extends RefCounted:
	func set_opponent_tell(_message: String, _progress: float = 0.0) -> void:
		pass

class FakeFighter extends RefCounted:
	var position := Vector2(500, 599)
	var weapon := {"reach": 190.0}
	var health := 100
	var max_health := 100
	var hurt_time := 0.0
	var attack_time := -1.0
	var cooldown := 0.0
	var guard_remaining := 0.0
	var boss_guard := false
	var boss_cast := ""
	var boss_charge := 0.0
	var facing := 1
	var rig := FakeRig.new()
	var attack_serial := 0
	var attack_spec := {"windup": 0.25, "active": 0.1}
	var definition := {"id": "blue"}
	func is_on_floor() -> bool:
		return true

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + label)

func run() -> void:
	await process_frame
	check("--isolated-qa" in OS.get_cmdline_user_args(), "QA uses isolated preferences")
	check(Difficulty.NAMES == ["Easy", "Medium", "Hard"], "three ordered difficulty levels")
	check(Difficulty.normalized_level(-4) == 0 and Difficulty.normalized_level(8) == 2, "difficulty input is bounded")
	_test_round_time()
	_test_pressure_model()
	_test_stage_profiles()
	_test_controllers()
	_test_hazards()
	_test_story_saves()
	await process_frame
	root.get_node("Sound").shutdown()
	print("DIFFICULTY_TEST_RESULT checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

func _test_round_time() -> void:
	var rules = Rules.new()
	check(rules.remaining == 60.0 and Rules.ROUND_SECONDS == 60.0, "every match starts at 60 seconds")
	rules.tick(1.0, 100, 100)
	check(is_equal_approx(rules.remaining, 59.0), "round clock ticks in seconds")
	rules.next_round()
	check(rules.remaining == 60.0, "next round receives a fresh minute")
	rules.reset()
	check(rules.remaining == 60.0 and rules.round_number == 1, "match reset restores a full first round")

func _test_pressure_model() -> void:
	# Reference the shipped v0.6.1 readiness/cadence factors directly. A rate is
	# inverse to its delay; the same full attack and hazard warnings still apply.
	for level in [Difficulty.MEDIUM, Difficulty.HARD]:
		var gain: float = Difficulty.PRESSURE_GAINS[level]
		var attack_rate_ratio: float = float(Difficulty.V061_REST_FACTORS[level]) / Difficulty.rest_factor(level)
		var hazard_rate_ratio: float = (8.0 * float(Difficulty.V061_HAZARD_FACTORS[level])) / Difficulty.hazard_interval(8.0, level)
		check(is_equal_approx(attack_rate_ratio, gain), "difficulty %d raises attack readiness by its promised v0.6.1 gain" % level)
		check(is_equal_approx(hazard_rate_ratio, gain * (1.30 if level == Difficulty.HARD else 1.0)), "difficulty %d includes the latest optional hazard cadence gain" % level)
	check(Difficulty.PRESSURE_GAINS == [1.0, 1.20, 1.50], "Medium and Hard target 20 and 50 percent more decision pressure than v0.6.1")
	print("PRESSURE_COMPARISON v061_readiness_medium=+20% hard=+50% v062_hard_hazards=+30%")

func _test_stage_profiles() -> void:
	for difficulty in range(3):
		var previous_rest := INF
		for stage in range(3):
			var ai = AI.new()
			ai.configure(stage)
			ai.configure_difficulty(difficulty)
			ai.reset()
			check(float(ai.profile.rest_max) < previous_rest, "chapter %d gains attack pace at difficulty %d" % [stage, difficulty])
			previous_rest = float(ai.profile.rest_max)
			check(ai.profile.tell == AI.PROFILES[stage].tell, "chapter warning remains full at difficulty %d" % difficulty)
			check(is_equal_approx(ai.rest_time, float(ai.profile.rest_max)), "reset uses selected pace")
			if difficulty == 0:
				check(ai.profile == AI.PROFILES[stage], "Easy keeps existing chapter %d tuning" % stage)
	var ai = AI.new()
	ai.configure(2)
	ai.configure_difficulty(2)
	var hard_rest: float = ai.profile.rest_max
	ai.configure_difficulty(0)
	check(ai.profile == AI.PROFILES[2] and hard_rest < float(ai.profile.rest_max), "switching back to Easy restores untouched baseline")
	check(AI.PROFILES[2].rest_max == 1.4, "shared chapter constants were not mutated")
	var post_reset_ai = AI.new()
	post_reset_ai.configure(2)
	post_reset_ai.reset()
	post_reset_ai.configure_difficulty(2)
	check(is_equal_approx(post_reset_ai.rest_time, float(post_reset_ai.profile.rest_max)), "chapter AI configuration works after reset")

func _count_commands(controller, seconds: float) -> int:
	var fighter = FakeFighter.new()
	var opponent = FakeFighter.new()
	opponent.position.x = 620
	var count := [0]
	if controller.has_signal("pattern_released"):
		controller.pattern_released.connect(func(_kind: String): count[0] += 1)
	for frame in range(int(seconds / DT)):
		var command: Dictionary = controller.read_input(DT, fighter, opponent)
		if command.get("attack", false) or command.get("special", false): count[0] += 1
	return count[0]

func _test_controllers() -> void:
	var normal_counts := []
	for level in range(3):
		var ordinary = AI.new()
		ordinary.configure(1)
		ordinary.configure_difficulty(level)
		ordinary.reset()
		ordinary.rng.seed = 42
		normal_counts.append(_count_commands(ordinary, 45.0))
	check(normal_counts[0] < normal_counts[1] and normal_counts[1] < normal_counts[2], "ordinary AI naturally attacks more often at each difficulty")
	var hard_vs_v0610: float = float(normal_counts[2]) / 36.0
	check(hard_vs_v0610 >= 1.30 and hard_vs_v0610 <= 1.50, "Hard regular AI delivers 30-50 percent more attack decisions than the v0.6.10 baseline")
	_test_hard_hit_reengagement()
	var easy_hacker = HackerAI.new()
	easy_hacker.configure_difficulty(0)
	easy_hacker.reset()
	check(easy_hacker.recovery_duration < 0.62 and easy_hacker.execution_duration < 2.25 and easy_hacker.approach_speed > 0.91, "H4CK3R gains modest real pressure on Easy")
	check(easy_hacker.tell_duration == 0.78, "H4CK3R keeps its entire warning")
	var hard_hacker = HackerAI.new()
	hard_hacker.configure_difficulty(2)
	hard_hacker.reset()
	check(hard_hacker.recovery_duration < easy_hacker.recovery_duration and hard_hacker.execution_duration < easy_hacker.execution_duration, "Hard H4CK3R recovers faster")
	var hacker_after_reset = HackerAI.new()
	hacker_after_reset.reset()
	hacker_after_reset.configure_difficulty(2)
	check(is_equal_approx(hacker_after_reset.time_left, hard_hacker.time_left), "H4CK3R choice can be applied after reset")
	var hacker_easy_count: int = _count_commands(easy_hacker, 45.0)
	var medium_hacker = HackerAI.new()
	medium_hacker.configure_difficulty(1)
	medium_hacker.reset()
	var hacker_medium_count: int = _count_commands(medium_hacker, 45.0)
	var hacker_hard_count: int = _count_commands(hard_hacker, 45.0)
	check(hacker_easy_count < hacker_medium_count and hacker_medium_count < hacker_hard_count, "H4CK3R naturally attacks more often at each difficulty")
	var pac_easy = PacAI.new()
	pac_easy.configure_difficulty(0)
	pac_easy.reset()
	var pac_hard = PacAI.new()
	pac_hard.configure_difficulty(2)
	pac_hard.reset()
	var pac_after_reset = PacAI.new()
	pac_after_reset.reset()
	pac_after_reset.configure_difficulty(2)
	check(is_equal_approx(pac_after_reset.time_left, pac_hard.time_left), "Pac-Man choice can be applied after reset")
	check(pac_easy.approach_speed == PacAI.APPROACH_SPEED and pac_hard.approach_speed > pac_easy.approach_speed, "Pac-Man pursues more assertively above Easy")
	check(PacAI.TELL_SECONDS == {"bite":0.35, "dash":0.70, "pellet_fan":0.68, "leap_chomp":0.58}, "Pac-Man warnings remain unchanged")
	check(_count_commands(pac_hard, 45.0) > _count_commands(pac_easy, 45.0), "Hard Pac-Man attacks more often in 45 seconds")
	var boss_easy = BossAI.new()
	boss_easy.configure_difficulty(0)
	boss_easy.reset()
	var boss_hard = BossAI.new()
	boss_hard.configure_difficulty(2)
	boss_hard.reset()
	var boss_after_reset = BossAI.new()
	boss_after_reset.reset()
	boss_after_reset.configure_difficulty(2)
	check(is_equal_approx(boss_after_reset.time_left, boss_hard.time_left), "Dark lord choice can be applied after reset")
	check(boss_hard.recovery_duration < boss_easy.recovery_duration and boss_hard.tell_duration == boss_easy.tell_duration, "Dark lord attacks sooner with full tells")
	var boss_medium = BossAI.new()
	boss_medium.configure_difficulty(1)
	boss_medium.reset()
	var boss_counts := [_count_commands(boss_easy, 45.0), _count_commands(boss_medium, 45.0), _count_commands(boss_hard, 45.0)]
	check(boss_counts[0] < boss_counts[1] and boss_counts[1] < boss_counts[2], "Dark lord naturally attacks more often at each difficulty")
	print("DIFFICULTY_PRESSURE ordinary=%s hard_vs_v0610=%.2f hacker=%s dark_lord=%s" % [str(normal_counts), hard_vs_v0610, str([hacker_easy_count, hacker_medium_count, hacker_hard_count]), str(boss_counts)])

func _test_hard_hit_reengagement() -> void:
	var fighter = FakeFighter.new()
	var opponent = FakeFighter.new()
	opponent.position.x = 600
	var gentle = AI.new()
	gentle.configure(1)
	gentle.configure_difficulty(Difficulty.EASY)
	gentle.reset()
	gentle.rest_time = 1.2
	fighter.hurt_time = DT
	gentle.read_input(DT,fighter,opponent)
	check(gentle.rest_time > 1.0,"Easy retains its existing post-hit recovery pacing")
	var hard = AI.new()
	hard.configure(1)
	hard.configure_difficulty(Difficulty.HARD)
	hard.reset()
	hard.rng.seed = 8142
	hard.rest_time = 2.0
	hard.think_time = 0.2
	hard.tell_time = 0.3
	hard.waiting_for_attack = true
	fighter.hurt_time = 0.18
	while fighter.hurt_time > 0.0:
		hard.read_input(DT,fighter,opponent)
		fighter.hurt_time = maxf(0.0,fighter.hurt_time-DT)
	check(hard.rest_time <= 0.06 and hard.think_time == 0.0 and hard.tell_time == 0.0,"Hard clears stale wait and counts its short recovery while hit-stun plays")
	var resumed_tell := -1.0
	for frame in range(30):
		hard.read_input(DT,fighter,opponent)
		if hard.tell_time > 0.0:
			resumed_tell = float(frame)*DT
			break
	check(resumed_tell >= 0.0 and resumed_tell <= 0.30,"Hard regular AI visibly re-engages within 0.30 seconds after hit-stun")
	check(float(hard.profile.tell) >= 0.42,"Hard regular attack still has a readable warning")
	print("HARD_AI_REENGAGEMENT tell_after_hit_seconds=%.3f" % resumed_tell)

func _test_hazards() -> void:
	var stage_intervals := [12.0, 10.0, 9.0, 8.0, 10.0, 11.0]
	for interval in stage_intervals:
		var previous_hard_interval: float = maxf(3.6, interval * 0.68 / 1.50)
		check(is_equal_approx(previous_hard_interval / Difficulty.hazard_interval(interval, 2), 1.30), "Hard schedules 30 percent more hazards than v0.6.2 at every stage")
		check(Difficulty.hazard_interval(interval, 0) == interval, "Easy keeps the stage's original hazard cadence")
		check(Difficulty.hazard_interval(interval, 2) < Difficulty.hazard_interval(interval, 1) and Difficulty.hazard_interval(interval, 1) < interval, "higher difficulty increases optional hazard frequency")
	check(Difficulty.opening_hazard_delay(0) == 8.0 and Difficulty.opening_hazard_delay(2) < 8.0, "opening hazard respects chosen pace")
	var longest_warning := 0.0
	for kind in Hazards.TYPES:
		var spec: Dictionary = Hazards.TYPES[kind]
		longest_warning = maxf(longest_warning, float(spec.tell) + float(spec.active) + 0.28)
	check(Difficulty.hazard_interval(8.0, 2) > longest_warning + 0.45, "Hard arena cadence retains full warnings and a gap between zones")
	var hazards = Hazards.new()
	root.add_child(hazards)
	hazards.mark_target(500, 0, "camera")
	hazards.mark_target(500, 0, "eraser_drop")
	check(hazards.marks.size() == 1 and hazards.pending.is_empty(), "optional arena event does not stack on an occupied zone")
	hazards.mark_target(500, 0, "dark_rift", "dark_lord")
	check(hazards.marks.size() == 1 and hazards.pending.size() == 1, "boss signature waits behind active warning")
	hazards.tick(3.0, [])
	check(hazards.marks.size() == 1 and hazards.marks[0].age == 0.0 and hazards.marks[0].kind == "dark_rift", "queued signature starts a fresh complete warning")
	hazards.queue_free()

func _test_story_saves() -> void:
	var legacy_path := "user://difficulty_legacy.cfg"
	var save_path := "user://difficulty_profile.cfg"
	var legacy := ConfigFile.new()
	legacy.set_value("meta", "version", 1)
	legacy.set_value("run", "stage", 4)
	legacy.set_value("run", "fighter", "orange")
	legacy.set_value("run", "active", true)
	legacy.set_value("run", "hazards", true)
	check(legacy.save(legacy_path) == OK, "legacy fixture writes in isolated profile")
	var profile = Profile.new()
	profile.difficulty_level = 2
	profile.load_profile(legacy_path)
	check(profile.stage == 4 and profile.difficulty_level == 0, "old story save migrates to Easy")
	profile.difficulty_level = 2
	check(profile.save_profile(save_path), "Hard story choice saves")
	var loaded = Profile.new()
	loaded.load_profile(save_path)
	check(loaded.stage == 4 and loaded.difficulty_level == 2, "story choice survives reload")
	loaded.checkpoint(5, "orange", true)
	check(loaded.stage == 5 and loaded.difficulty_level == 2, "existing checkpoint calls retain chosen difficulty")
	loaded.begin_run("orange", true, 1)
	check(loaded.stage == 0 and loaded.difficulty_level == 1, "new journey can select Medium")
	profile.free()
	loaded.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(legacy_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + ".bak"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Profile.SAVE_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Profile.SAVE_PATH + ".bak"))
