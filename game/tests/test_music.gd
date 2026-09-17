extends SceneTree
## Run in headless mode after --import. Settings changes stay in memory.

const FADE := 0.75
var settings: Node
var sound: Node
var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error("FAIL: " + description)


func run() -> void:
	await process_frame
	settings = root.get_node("Settings")
	sound = root.get_node("Sound")
	var original_volumes := [settings.master_volume, settings.music_volume, settings.sfx_volume]
	settings.master_volume = 1.0
	settings.music_volume = 1.0
	settings.sfx_volume = 1.0
	sound.apply_settings()
	var original_title: AudioStreamWAV = sound.get("_music").stream
	var keys := ["desktop", "quarry", "journey_green", "glitch", "pac_man", "dark_lord"]
	var fingerprints: Dictionary = {}
	for key in keys:
		sound.set_music_context(key)
		check(sound.get("_music_context") == key, "%s context accepted" % key)
		check(sound.get("_music_fading"), "%s starts a transition" % key)
		var incoming: AudioStreamPlayer = sound.get("_music_other")
		var stream := incoming.stream as AudioStreamWAV
		check(stream != null, "%s is a WAV stream" % key)
		if stream != null:
			check(stream.mix_rate == 22050 and stream.format == AudioStreamWAV.FORMAT_16_BITS and not stream.stereo, "%s is 16-bit mono at expected rate" % key)
			check(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and stream.loop_begin == 0 and stream.loop_end == stream.data.size() / 2, "%s covers a complete PCM loop" % key)
			check(stream.get_length() > 10.0 and stream.get_length() < 20.0, "%s has a complete arrangement" % key)
			var signature := hash(stream.data)
			check(not fingerprints.has(signature), "%s has a distinct arrangement" % key)
			fingerprints[signature] = key
			var peak := 0
			var activity := 0
			for index in range(0, stream.data.size() - 1, 200):
				var value := stream.data[index] | (stream.data[index + 1] << 8)
				if value > 32767:
					value -= 65536
				peak = maxi(peak, absi(value))
				if absi(value) > 600:
					activity += 1
			check(peak > 3500 and peak < 30000 and activity > 100, "%s is audible without clipping" % key)
		sound._process(FADE * 0.5)
		check(sound.get("_music_fade") > 0.45 and sound.get("_music_fade") < 0.55, "%s fades halfway" % key)
		check(sound.get("_music").stream != null and sound.get("_music_other").stream != null, "%s overlaps outgoing and incoming streams" % key)
		sound._process(FADE * 0.5)
		check(not sound.get("_music_fading") and sound.get("_music_other").stream == null, "%s transition releases old stream" % key)
		check(sound.get("_music").stream == stream, "%s becomes active" % key)

	sound.set_music_context("title")
	sound._process(FADE)
	check(sound.get("_music").stream == original_title, "title keeps original melody")
	sound.set_music_context("story")
	check(sound.get("_music_context") == "story" and sound.get("_music_other").stream != null, "story context selects the paper-desk bed")
	var story_stream: AudioStreamWAV = sound.get("_music_other").stream
	check(story_stream != null and story_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and story_stream.get_length() > 10.0, "story bed is a long loop")
	sound._process(FADE)
	check(sound.get("_music").stream == story_stream, "story bed crossfade completes")
	sound.set_music_context("racing")
	check(sound.get("_music_context") == "racing" and sound.get("_music_fading"), "story-to-racing starts a clean return")
	sound._process(FADE)
	check(sound.get("_music").stream == original_title, "racing keeps original melody")
	check(not sound.get("_music_fading"), "story-to-racing return completes")
	sound.set_music_context("desktop")
	sound._process(FADE)
	settings.master_volume = 0.5
	settings.music_volume = 0.4
	sound.apply_settings()
	check(absf(sound.get("_music").volume_db - linear_to_db(0.2)) < 0.01, "music obeys master and music volume")
	settings.music_volume = 0.0
	sound.apply_settings()
	check(sound.get("_music").volume_db <= -79.0, "zero music volume mutes stream")
	settings.music_volume = 1.0
	for cue in ["story_open", "story_page", "story_pencil", "story_bonk", "story_magic", "story_glitch", "story_chomp", "story_swish", "story_spark", "story_next", "story_skip", "story_hover", "story_close"]:
		var story_cue: AudioStreamWAV = sound.get("_sounds")[cue]
		check(story_cue != null and story_cue.get_length() > 0.04 and story_cue.get_length() < 0.7, "%s is a short story Foley cue" % cue)
	sound.apply_settings()
	check(absf(sound.get("_music").volume_db - linear_to_db(0.5)) < 0.01, "restored music volume restores level")
	paused = true
	sound.apply_settings()
	check(absf(sound.get("_music").volume_db - linear_to_db(0.5 * 0.45)) < 0.01, "game pause softens music")
	paused = false
	sound.apply_settings()
	sound.set_music_context("quarry")
	sound._process(FADE * 0.65)
	sound.set_music_context("pac_man")
	check(sound.get("_music_context") == "pac_man" and sound.get("_music_other").stream != null, "interrupted fade has new target")
	sound._process(FADE)
	check(sound.get("_music").stream == sound._get_music_stream("pac_man") and sound.get("_music_other").stream == null, "interrupted fade finishes cleanly")
	sound.shutdown()
	check(sound.get("_music").stream == null and sound.get("_music_other").stream == null, "shutdown releases both players")
	settings.master_volume = original_volumes[0]
	settings.music_volume = original_volumes[1]
	settings.sfx_volume = original_volumes[2]
	print("MUSIC_TEST_RESULT checks=%d failures=%d" % [checks, failures.size()])
	call_deferred("quit", 0 if failures.is_empty() else 1)
