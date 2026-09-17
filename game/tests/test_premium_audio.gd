extends SceneTree
## Offline signal and routing checks. Headless/silent QA does not audition audio.

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures.append(description)
		push_error("FAIL: " + description)


func signal_stats(stream: AudioStreamWAV) -> Vector2:
	var peak := 0.0
	var energy := 0.0
	var count := stream.data.size() / 2
	var step := maxi(1, count / 8000)
	var sampled := 0
	for index in range(0, count, step):
		var value: int = stream.data[index * 2] | (stream.data[index * 2 + 1] << 8)
		if value > 32767:
			value -= 65536
		var normalized := float(value) / 32768.0
		peak = maxf(peak, absf(normalized))
		energy += normalized * normalized
		sampled += 1
	return Vector2(peak, sqrt(energy / maxf(1.0, sampled)))


func run() -> void:
	await process_frame
	var sound: Node = root.get_node("Sound")
	var settings: Node = root.get_node("Settings")
	var old_volumes := [settings.master_volume, settings.music_volume, settings.sfx_volume]
	settings.master_volume = 1.0
	settings.music_volume = 1.0
	settings.sfx_volume = 1.0
	sound.apply_settings()
	var contexts := ["desktop", "quarry", "journey_green", "pac_man", "glitch", "dark_lord"]
	for context in contexts:
		var streams := {}
		var levels := {}
		for phase in ["intro", "battle", "climax"]:
			var stream: AudioStreamWAV = sound._get_music_stream(context, phase)
			check(stream != null, "%s %s arrangement loads" % [context, phase])
			if stream == null:
				continue
			check(stream.format == AudioStreamWAV.FORMAT_16_BITS and stream.mix_rate == 22050 and not stream.stereo, "%s %s is 16-bit mono 22.05 kHz" % [context, phase])
			check(stream.loop_end == stream.data.size() / 2, "%s %s loops all frames" % [context, phase])
			var stats := signal_stats(stream)
			check(stats.x < 0.75 and stats.y > 0.05, "%s %s has headroom and musical activity" % [context, phase])
			streams[phase] = stream
			levels[phase] = stats.y
		if streams.size() == 3:
			check(streams["intro"].data.size() == streams["battle"].data.size() and streams["battle"].data.size() == streams["climax"].data.size(), "%s phase versions stay sample-aligned" % context)
			check(levels["intro"] < levels["battle"] and levels["battle"] < levels["climax"], "%s grows from intro to climax" % context)
		sound.set_music_context(context)
		sound.set_music_phase("intro")
		check(sound.get("_music_phase") == "intro" and sound.get("_music_other").stream == streams["intro"], "%s selects intro during context fade" % context)
		sound._process(0.75)
		sound.set_music_phase("climax")
		check(sound.get("_music_fading") and sound.get("_music_other").stream == streams["climax"], "%s crossfades to climax" % context)
		sound._process(0.75)
		check(sound.get("_music").stream == streams["climax"] and sound.get("_music_other").stream == null, "%s completes climax fade" % context)

	for weapon in ["pitchfork", "hammer", "sword", "pickaxe", "bow", "staff", "chomp", "dark_blade", "cursor_wand"]:
		var light: AudioStreamWAV = sound._impact_stream(weapon, false, "paper")
		var heavy: AudioStreamWAV = sound._impact_stream(weapon, true, "paper")
		var paper_stats := signal_stats(light)
		var heavy_stats := signal_stats(heavy)
		check(light.data != heavy.data and heavy.get_length() > light.get_length(), "%s light and heavy impacts differ" % weapon)
		check(paper_stats.x < 0.8 and heavy_stats.x < 0.8 and paper_stats.y > 0.015, "%s impact is audible with peak headroom" % weapon)
	var hammer_paper: AudioStreamWAV = sound._impact_stream("hammer", true, "paper")
	var hammer_metal: AudioStreamWAV = sound._impact_stream("hammer", true, "metal")
	var hammer_magic: AudioStreamWAV = sound._impact_stream("hammer", true, "magic")
	check(hammer_paper.data != hammer_metal.data and hammer_paper.data != hammer_magic.data and hammer_metal.data != hammer_magic.data, "paper, metal, and magic accents differ")
	for cue in ["guard_shield", "guard_parry", "guard_reflect", "warning_hazard", "warning_boss", "warning_projectile", "menu_move", "menu_select", "menu_back", "round_start", "round_end", "match_win"]:
		var stream: AudioStreamWAV = sound.get("_sounds")[cue]
		var stats := signal_stats(stream)
		check(stats.x < 0.8 and stats.y > 0.01, "%s has bounded audible signal" % cue)
	check(sound.get("_sounds")["warning_hazard"].data != sound.get("_sounds")["warning_boss"].data, "hazard and boss warning motifs differ")
	sound.set_music_context("title")
	sound._process(0.75)
	check(sound.get("_music_phase") == "battle", "title resets the stage phase")
	settings.master_volume = old_volumes[0]
	settings.music_volume = old_volumes[1]
	settings.sfx_volume = old_volumes[2]
	sound.apply_settings()
	sound.shutdown()
	await create_timer(0.15).timeout
	print("PREMIUM_AUDIO_TEST_RESULT checks=%d failures=%d" % [checks, failures.size()])
	call_deferred("quit", 0 if failures.is_empty() else 1)
