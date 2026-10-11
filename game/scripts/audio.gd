extends Node
## Original, small synthesized sounds. No external recordings or asset licenses.

const RATE := 22050
const VOICES := 12
const MUSIC_FADE_SECONDS := 0.75
const EFFECT_HEADROOM := 0.72
const MUSIC_PHASES := ["intro", "battle", "climax"]
const STORY_STAGE_MUSIC := ["desktop", "quarry", "journey_green", "quarry", "pac_man", "glitch", "glitch", "dark_lord"]
const FIGHTER_SPECIAL_STYLE := {
	"orange": "spin", "red": "quake", "green": "dash", "blue": "blocks",
	"purple": "signal", "yellow": "swarm", "crackle": "eclipse", "pac_man": "chomp",
	"h4ck3r": "glitch", "fuse": "quake", "dark_lord": "void",
}
const KIT_SPECIAL_STYLE := {
	"ore_pop": "ore", "fossil_fetch": "fossil", "home_run": "home_run",
	"swerve_shot": "swerve", "cluckquake": "cluck", "rainbow_ruckus": "rainbow",
}
const BOSS_PATTERN_STYLE := {
	"crackle": {
		"rocket_single": "dash", "firecracker_arc": "pellet", "firecracker_pop": "blocks",
		"firework_fan": "eclipse", "spear_thrust": "dark_slash",
	},
	"pac_man": {"pellet_fan": "pellet", "leap_chomp": "chomp"},
	"h4ck3r": {
		"cursor_strike": "dash", "packet_blast": "packet_blast", "cursor_stamp": "cursor_stamp",
		"ink_geyser": "ink_geyser", "eraser_drop": "eraser", "checksum_volley": "glitch",
		"firewall_scan": "firewall",
	},
	"fuse": {
		"missile_single": "dash", "missile_salvo": "eclipse",
		"missile_high_low": "dark_quake", "launcher_bash": "quake",
	},
	"dark_lord": {
		"reaper": "dark_slash", "quake": "dark_quake", "void_orb": "void", "rift": "dark_rift",
		"eclipse_volley": "eclipse", "eclipse_wave": "eclipse", "void_pillar": "dark_rift", "camera": "camera_flash",
	},
}
const MUSIC_PATHS := {
	"desktop": "res://assets/music/desktop.wav",
	"quarry": "res://assets/music/quarry.wav",
	"journey_green": "res://assets/music/journey_green.wav",
	"glitch": "res://assets/music/glitch.wav",
	"pac_man": "res://assets/music/pac_man.wav",
	"dark_lord": "res://assets/music/dark_lord.wav",
}
var _sounds: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _music_other: AudioStreamPlayer
var _music_cache: Dictionary = {}
var _music_context := "title"
var _music_phase := "battle"
var _music_fading := false
var _music_fade := 0.0
var _next_voice: int = 0
var _last_mix := Vector3(-1, -1, -1)
var _last_paused: bool = false
var _random := RandomNumberGenerator.new()
var _silent_mode: bool = false
var _shutting_down: bool = false
var _impact_cache: Dictionary = {}
var _warning_last_msec := -10000
var _music_duck := 1.0
var _music_duck_hold := 0.0
var external_music_active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_silent_mode = DisplayServer.get_name() == "headless" or "--silent-qa" in OS.get_cmdline_user_args()
	_random.seed = 71023
	_sounds["ui"] = _tone(0.075, 780.0, 1080.0, 0.28)
	_sounds["jump"] = _tone(0.16, 280.0, 700.0, 0.35)
	_sounds["swing"] = _tone(0.12, 260.0, 125.0, 0.38, 0.38)
	_sounds["hit"] = _tone(0.18, 150.0, 55.0, 0.62, 0.27)
	_sounds["special"] = _tone(0.35, 180.0, 870.0, 0.42, 0.12)
	_sounds["pitchfork"] = _tone(0.23, 390.0, 980.0, 0.36, 0.08)
	_sounds["hammer"] = _tone(0.28, 108.0, 39.0, 0.64, 0.25)
	_sounds["sword"] = _tone(0.16, 970.0, 350.0, 0.35, 0.29)
	_sounds["pickaxe"] = _melody([784.0, 1174.66, 587.33], 0.065)
	_sounds["bow"] = _tone(0.13, 950.0, 330.0, 0.32, 0.10)
	_sounds["staff"] = _tone(0.12, 520.0, 270.0, 0.30, 0.06)
	_sounds["custom_pick"] = _melody([659.25,987.77,1318.51],0.044)
	_sounds["custom_bone"] = _tone(0.20,340.0,135.0,0.42,0.19)
	_sounds["custom_bat"] = _tone(0.22,185.0,72.0,0.52,0.30)
	_sounds["custom_ball"] = _melody([440.0,659.25,523.25],0.050)
	_sounds["custom_chicken"] = _tone(0.18,1050.0,360.0,0.40,0.24)
	_sounds["custom_crayon"] = _melody([587.33,698.46,880.0],0.055)
	_sounds["ore_pop"] = _melody([392.0,523.25,783.99],0.084)
	_sounds["fossil_fetch"] = _melody([330.0,440.0,330.0],0.10)
	_sounds["home_run"] = _tone(0.33,220.0,72.0,0.59,0.37)
	_sounds["swerve_shot"] = _melody([523.25,783.99,587.33],0.09)
	_sounds["cluckquake"] = _melody([1046.5,392.0,880.0,330.0],0.060)
	_sounds["rainbow_ruckus"] = _melody([523.25,659.25,783.99,1046.5,880.0],0.065)
	_sounds["signal"] = _melody([659.25, 987.77, 1318.51], 0.075)
	_sounds["swarm"] = _melody([523.25, 659.25, 783.99], 0.08)
	_sounds["chomp"] = _melody([330.0, 185.0, 440.0, 165.0], 0.045)
	_sounds["pac_bite"] = _signature_stream("bite")
	_sounds["cursor_tap"] = _signature_stream("cursor_tap")
	_sounds["dark_blade_swing"] = _signature_stream("dark_blade")
	_sounds["boss"] = _tone(0.45, 87.0, 174.0, 0.42, 0.13)
	_sounds["warning"] = _melody([659.25, 0.0, 659.25], 0.12)
	_sounds["win"] = _melody([523.25, 659.25, 783.99, 1046.5], 0.17)
	_sounds["round"] = _melody([392.0, 523.25, 783.99], 0.11)
	# UI and round cues keep the toy-and-paper character of the title theme.
	_sounds["menu_move"] = _melody([659.25, 783.99], 0.045)
	_sounds["menu_select"] = _melody([523.25, 783.99, 1046.5], 0.065)
	_sounds["menu_back"] = _melody([587.33, 392.0], 0.065)
	_sounds["round_start"] = _melody([392.0, 523.25, 659.25, 783.99], 0.09)
	_sounds["round_end"] = _melody([783.99, 587.33, 523.25], 0.095)
	_sounds["match_win"] = _melody([523.25, 659.25, 783.99, 1046.5, 1318.51], 0.115)
	_sounds["ui"] = _sounds["menu_select"]
	_sounds["win"] = _sounds["match_win"]
	_sounds["guard_shield"] = _guard_stream("shield")
	_sounds["guard_parry"] = _guard_stream("parry")
	_sounds["guard_reflect"] = _guard_stream("reflect")
	_sounds["warning_hazard"] = _warning_stream("hazard")
	_sounds["warning_boss"] = _warning_stream("boss")
	_sounds["warning_projectile"] = _warning_stream("projectile")
	# Story pages use small paper, pencil, computer and character Foley cues
	# instead of making every advance feel like a generic menu beep.
	_sounds["story_open"] = _story_foley("open")
	_sounds["story_page"] = _story_foley("page")
	_sounds["story_pencil"] = _story_foley("pencil")
	_sounds["story_bonk"] = _story_foley("bonk")
	_sounds["story_magic"] = _story_foley("magic")
	_sounds["story_glitch"] = _story_foley("glitch")
	_sounds["story_chomp"] = _story_foley("chomp")
	_sounds["story_swish"] = _story_foley("swish")
	_sounds["story_spark"] = _story_foley("spark")
	_sounds["story_next"] = _story_foley("next")
	_sounds["story_skip"] = _story_foley("skip")
	_sounds["story_hover"] = _story_foley("hover")
	_sounds["story_close"] = _story_foley("close")
	for fighter_id in FIGHTER_SPECIAL_STYLE:
		var fighter_style: String = FIGHTER_SPECIAL_STYLE[fighter_id]
		_sounds["signature_" + fighter_style] = _signature_stream(fighter_style)
	for extra_style in ["ore", "fossil", "home_run", "swerve", "cluck", "rainbow", "pellet", "cursor_stamp", "ink_geyser", "eraser", "firewall", "dark_slash", "dark_rift", "eclipse", "dark_blade", "cursor_tap", "bite", "dark_quake", "camera_flash", "packet_blast"]:
		_sounds["signature_" + extra_style] = _signature_stream(extra_style)
	for index in range(VOICES):
		var player := AudioStreamPlayer.new()
		player.name = "Effect%d" % index
		add_child(player)
		_players.append(player)
	_music = AudioStreamPlayer.new()
	_music.name = "MusicA"
	_music.stream = _music_loop()
	_music_cache["title"] = _music.stream
	_music_cache["racing"] = _music.stream
	_music_cache["story"] = _story_music_loop()
	add_child(_music)
	_music_other = AudioStreamPlayer.new()
	_music_other.name = "MusicB"
	add_child(_music_other)
	apply_settings()
	if not _silent_mode:
		_music.play()


func play(cue: String) -> void:
	if _shutting_down or _silent_mode or not _sounds.has(cue) or Settings.master_volume <= 0.0 or Settings.sfx_volume <= 0.0:
		return
	_play_stream(_sounds[cue], cue)


func play_impact(weapon: String, strength: float, material: String = "paper") -> void:
	## strength is on a roughly 0..1 scale (damage / 20 is a useful call site).
	## Distinct cached composites avoid stacking many voices on each collision.
	if _shutting_down or _silent_mode or Settings.master_volume <= 0.0 or Settings.sfx_volume <= 0.0:
		return
	var weight := "heavy" if strength >= 0.8 else "light"
	var surface := material if material in ["paper", "metal", "magic"] else "paper"
	var key := "%s/%s/%s" % [weapon, weight, surface]
	if not _impact_cache.has(key):
		_impact_cache[key] = _impact_stream(weapon, weight == "heavy", surface)
	_play_stream(_impact_cache[key], "impact", clampf(0.94 + strength * 0.06, 0.92, 1.07))
	_duck_music(0.80 if weight == "heavy" else 0.91, 0.08 if weight == "heavy" else 0.035)


func play_fighter_special(fighter_id: String, special_id: String = "") -> void:
	## Each signature cast gets a short, identifiable launch cue. Custom kits
	## resolve only through their approved special id, never player-provided stats.
	var style: String = str(FIGHTER_SPECIAL_STYLE.get(fighter_id, KIT_SPECIAL_STYLE.get(special_id, "")))
	var cue := "signature_" + style if not style.is_empty() else special_id
	if not _sounds.has(cue):
		cue = "special"
	play(cue)
	_duck_music(0.88, 0.13)


func play_boss_pattern(fighter_id: String, pattern: String) -> void:
	## Released patterns add a second, pattern-specific cue after the readable tell.
	var styles: Dictionary = BOSS_PATTERN_STYLE.get(fighter_id, {})
	var style: String = str(styles.get(pattern, ""))
	if style.is_empty():
		play_warning("boss")
		return
	play("signature_" + style)
	_duck_music(0.88, 0.16)


func set_story_stage(stage_index: int) -> void:
	## Comic scenes borrow the next arena's lighter arrangement, then fights
	## crossfade into the same stage's battle/climax mix.
	if _shutting_down:
		return
	var context: String = STORY_STAGE_MUSIC[clampi(stage_index, 0, STORY_STAGE_MUSIC.size() - 1)]
	var stream := _get_music_stream(context, "intro")
	if stream == null:
		return
	_music_phase = "intro"
	_queue_music(context, stream, false)


func play_guard(kind: String = "shield") -> void:
	play("guard_" + (kind if kind in ["shield", "parry", "reflect"] else "shield"))


func play_warning(kind: String = "hazard") -> void:
	## Limit repeated overlapping telegraphs while retaining their identities.
	if _shutting_down or _silent_mode or Settings.master_volume <= 0.0 or Settings.sfx_volume <= 0.0:
		return
	var now := Time.get_ticks_msec()
	if now - _warning_last_msec < 350:
		return
	_warning_last_msec = now
	play("warning_" + (kind if kind in ["hazard", "boss", "projectile"] else "hazard"))
	_duck_music(0.90, 0.09)


func _duck_music(gain: float, hold: float) -> void:
	_music_duck = minf(_music_duck, clampf(gain, 0.70, 1.0))
	_music_duck_hold = maxf(_music_duck_hold, hold)
	apply_settings()


func _play_stream(stream: AudioStreamWAV, cue: String, pitch: float = 1.0) -> void:
	var player: AudioStreamPlayer = _players[_next_voice]
	for candidate in _players:
		if not candidate.playing:
			player = candidate
			break
	_next_voice = (_next_voice + 1) % VOICES
	player.stream = stream
	player.pitch_scale = pitch * (_random.randf_range(0.96, 1.04) if cue in ["swing", "hit", "impact"] else 1.0)
	if cue.begins_with("signature_") or cue in ["pac_bite", "cursor_tap", "dark_blade_swing"]:
		player.pitch_scale *= _random.randf_range(0.985, 1.015)
	player.volume_db = _gain_db(Settings.master_volume * Settings.sfx_volume * EFFECT_HEADROOM)
	player.play()


func set_music_context(context: String) -> void:
	## Title and racing retain the original music; journey_green gives stage 3
	## its own cue even though it revisits the Desktop Dojo arena.
	if _shutting_down or context == _music_context:
		return
	if context not in ["title", "racing", "story"] and not MUSIC_PATHS.has(context):
		push_warning("Unknown music context: %s" % context)
		return
	var stream := _get_music_stream(context)
	if stream == null:
		return
	_music_phase = "battle"
	_queue_music(context, stream, false)


func set_music_phase(phase: String) -> void:
	## Stage arrangements share tempo and length, so a phase change resumes
	## from the same bar position while the two streams crossfade.
	if _shutting_down or phase not in MUSIC_PHASES or _music_context in ["title", "racing"]:
		return
	if phase == _music_phase:
		return
	var stream := _get_music_stream(_music_context, phase)
	if stream == null:
		return
	_music_phase = phase
	_queue_music(_music_context, stream, true)


func _queue_music(context: String, stream: AudioStreamWAV, keep_position: bool) -> void:
	if (_music_fading and _music_other.stream == stream) or (not _music_fading and _music.stream == stream):
		_music_context = context
		return
	var playback_position := _music.get_playback_position() if keep_position else 0.0
	if _music_fading and keep_position and _music_other.playing:
		playback_position = _music_other.get_playback_position()
	if _music_fading:
		# A quick menu or rematch can interrupt a fade. Keep whichever source
		# is louder, then fade from there instead of stacking a third player.
		if _music_fade >= 0.5:
			_music.stop()
			_music.stream = null
			var previous := _music
			_music = _music_other
			_music_other = previous
		_music_other.stop()
		_music_other.stream = null
	_music_other.stream = stream
	_music_fade = 0.0
	_music_fading = true
	_music_context = context
	_music_other.stream_paused = external_music_active or Settings.master_volume <= 0.0 or Settings.music_volume <= 0.0
	if not _silent_mode:
		_music_other.play(fmod(playback_position, maxf(0.01, stream.get_length())))
	apply_settings()


func _get_music_stream(context: String, phase: String = "battle") -> AudioStreamWAV:
	var key := context if phase == "battle" else "%s_%s" % [context, phase]
	if _music_cache.has(key):
		return _music_cache[key]
	if context == "story":
		# Story uses one gentle, looped paper-desk bed; there are no combat
		# phase changes while a comic page is on screen.
		return _music_cache["story"]
	var path: String = MUSIC_PATHS[context] if phase == "battle" else "res://assets/music/%s_%s.wav" % [context, phase]
	var stream := load(path) as AudioStreamWAV
	if stream == null:
		push_warning("Music could not load for %s" % context)
		return null
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = stream.data.size() / 2
	_music_cache[key] = stream
	return stream


func set_external_music_active(active: bool) -> void:
	external_music_active = active
	apply_settings()


func apply_settings() -> void:
	_last_mix = Vector3(Settings.master_volume, Settings.music_volume, Settings.sfx_volume)
	_last_paused = get_tree().paused
	for player in _players:
		player.volume_db = _gain_db(Settings.master_volume * Settings.sfx_volume * EFFECT_HEADROOM)
	var gain := Settings.master_volume * Settings.music_volume * (0.45 if _last_paused else 1.0) * _music_duck
	if is_instance_valid(_music):
		_music.volume_db = _gain_db(gain * (1.0 - _music_fade if _music_fading else 1.0))
		_music.stream_paused = external_music_active or Settings.master_volume <= 0.0 or Settings.music_volume <= 0.0
	if is_instance_valid(_music_other):
		_music_other.volume_db = _gain_db(gain * _music_fade if _music_fading else 0.0)
		_music_other.stream_paused = external_music_active or Settings.master_volume <= 0.0 or Settings.music_volume <= 0.0


func _process(delta: float) -> void:
	if _shutting_down:
		return
	var duck_changed := false
	if _music_duck_hold > 0.0:
		_music_duck_hold = maxf(0.0, _music_duck_hold - delta)
	elif _music_duck < 1.0:
		_music_duck = minf(1.0, _music_duck + delta * 1.8)
		duck_changed = true
	if _music_fading:
		_music_fade = minf(1.0, _music_fade + delta / MUSIC_FADE_SECONDS)
		if _music_fade >= 1.0:
			_music.stop()
			_music.stream = null
			var previous := _music
			_music = _music_other
			_music_other = previous
			_music_fading = false
			_music_fade = 0.0
		apply_settings()
	elif duck_changed or _last_mix != Vector3(Settings.master_volume, Settings.music_volume, Settings.sfx_volume) or _last_paused != get_tree().paused:
		apply_settings()


func _exit_tree() -> void:
	shutdown()


func shutdown() -> void:
	# Release the looping WAV playback before the audio server shuts down.
	_shutting_down = true
	if is_instance_valid(_music):
		_music.stop()
		_music.stream = null
	if is_instance_valid(_music_other):
		_music_other.stop()
		_music_other.stream = null
	for player in _players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	_sounds.clear()
	_impact_cache.clear()
	_music_cache.clear()


func _gain_db(value: float) -> float:
	return -80.0 if value <= 0.0 else linear_to_db(value)


func _wave(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for index in range(samples.size()):
		var sample := int(clampf(samples[index], -1.0, 1.0) * 32760.0)
		bytes[index * 2] = sample & 255
		bytes[index * 2 + 1] = (sample >> 8) & 255
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = samples.size()
	return stream


func _tone(duration: float, start_hz: float, end_hz: float, gain: float, noise: float = 0.0) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var count := int(duration * RATE)
	samples.resize(count)
	var phase: float = 0.0
	for index in range(count):
		var t := float(index) / RATE
		var progress := t / duration
		var frequency := lerpf(start_hz, end_hz, progress)
		phase += TAU * frequency / RATE
		var envelope := minf(t / 0.006, 1.0) * pow(1.0 - progress, 2.0)
		var tone := sin(phase) * 0.78 + sin(phase * 2.0) * 0.12
		samples[index] = (tone * (1.0 - noise) + _random.randf_range(-1.0, 1.0) * noise) * envelope * gain
	return _wave(samples)


func _melody(notes: Array, note_duration: float) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var note_samples := int(note_duration * RATE)
	samples.resize(note_samples * notes.size())
	for note_index in range(notes.size()):
		for index in range(note_samples):
			var t := float(index) / RATE
			var envelope := minf(t / 0.006, 1.0) * pow(1.0 - t / note_duration, 1.5)
			var phase := TAU * float(notes[note_index]) * t
			samples[note_index * note_samples + index] = (sin(phase) + sin(phase * 2.0) * 0.2) * envelope * 0.30
	return _wave(samples)


func _impact_stream(weapon: String, heavy: bool, material: String) -> AudioStreamWAV:
	# Each collision is one bounded composite: body, weapon resonance, and a
	# tactile paper/metal/magic accent. It stays clear over the score.
	var profiles := {
		"pitchfork": Vector3(390, 0.48, 0.28),
		"hammer": Vector3(105, 0.20, 0.36),
		"sword": Vector3(650, 0.72, 0.24),
		"pickaxe": Vector3(510, 0.78, 0.30),
		"bow": Vector3(245, 0.42, 0.12),
		"staff": Vector3(470, 0.57, 0.10),
		"chomp": Vector3(155, 0.18, 0.19),
		"dark_blade": Vector3(260, 0.68, 0.30),
		"cursor_wand": Vector3(585, 0.75, 0.10),
		"custom_pick": Vector3(760, 0.82, 0.22),
		"custom_bone": Vector3(340, 0.36, 0.19),
		"custom_bat": Vector3(180, 0.24, 0.38),
		"custom_ball": Vector3(530, 0.54, 0.11),
		"custom_chicken": Vector3(920, 0.34, 0.24),
		"custom_crayon": Vector3(610, 0.61, 0.10),
	}
	var profile: Vector3 = profiles.get(weapon, Vector3(300, 0.4, 0.25))
	var duration := 0.245 if heavy else 0.17
	var count := int(duration * RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s/%s/%s" % [weapon, heavy, material])
	var noise_memory := 0.0
	var ring_phase := 0.0
	var body_phase := 0.0
	for index in range(count):
		var t := float(index) / RATE
		var progress := t / duration
		var attack := minf(1.0, t / 0.002)
		var body_frequency := (165.0 if heavy else 220.0) * exp(-t * 11.0) + 55.0
		body_phase += TAU * body_frequency / RATE
		ring_phase += TAU * profile.x * (1.0 - progress * (0.28 if weapon == "bow" else 0.08)) / RATE
		noise_memory = noise_memory * 0.68 + rng.randf_range(-1.0, 1.0) * 0.32
		var body := sin(body_phase) * exp(-t * (16.0 if heavy else 25.0)) * (0.35 if heavy else 0.20)
		var ring := (sin(ring_phase) + profile.y * 0.34 * sin(ring_phase * 2.21)) * exp(-t * (16.0 if heavy else 23.0)) * 0.25
		var paper := noise_memory * exp(-t * 37.0) * profile.z * 0.55
		var accent := 0.0
		if material == "metal":
			accent = sin(ring_phase * 1.63) * exp(-t * 16.0) * 0.19
		elif material == "magic":
			accent = sin(TAU * (920.0 * t + 440.0 * t * t)) * exp(-t * 15.0) * 0.16
		samples[index] = (body + ring + paper + accent) * attack * pow(1.0 - progress, 0.65)
	return _wave(samples)


func _guard_stream(kind: String) -> AudioStreamWAV:
	var duration := 0.17 if kind == "shield" else 0.22
	var count := int(duration * RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var frequency := 390.0 if kind == "shield" else 740.0 if kind == "parry" else 520.0
	for index in range(count):
		var t := float(index) / RATE
		var progress := t / duration
		var envelope := minf(1.0, t / 0.003) * pow(1.0 - progress, 1.55)
		var phase := TAU * (frequency * t + (180.0 if kind == "reflect" else -95.0) * t * t)
		var tone := sin(phase) * 0.30 + sin(phase * (2.45 if kind == "parry" else 1.51)) * 0.11
		var impact := sin(TAU * 110.0 * t) * exp(-t * 42.0) * (0.18 if kind == "shield" else 0.06)
		samples[index] = (tone + impact) * envelope
	return _wave(samples)


func _warning_stream(kind: String) -> AudioStreamWAV:
	# Friendly two-note signals identify threats without a continuous siren.
	var notes := [523.25, 659.25] if kind == "hazard" else [329.63, 493.88] if kind == "boss" else [783.99, 587.33]
	var duration := 0.34
	var count := int(duration * RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for index in range(count):
		var t := float(index) / RATE
		var note_index := 0 if t < 0.15 else 1
		var local_t := t if note_index == 0 else t - 0.15
		var note_duration := 0.15 if note_index == 0 else 0.19
		var envelope := minf(1.0, local_t / 0.008) * pow(maxf(0.0, 1.0 - local_t / note_duration), 1.4)
		var phase := TAU * float(notes[note_index]) * local_t
		samples[index] = (sin(phase) + 0.16 * sin(phase * 2.0)) * envelope * 0.22
	return _wave(samples)


func _music_loop() -> AudioStreamWAV:
	# A quiet, eight-second C-major toy-keyboard loop with a soft bass pulse.
	var beat: float = 0.5
	var notes := [523.25, 0.0, 659.25, 783.99, 659.25, 0.0, 587.33, 0.0, 440.0, 0.0, 523.25, 659.25, 587.33, 0.0, 392.0, 0.0]
	var roots := [130.81, 130.81, 110.0, 98.0]
	var count := int(notes.size() * beat * RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for index in range(count):
		var t := float(index) / RATE
		var beat_index := int(t / beat)
		var local_t := fmod(t, beat)
		var envelope := minf(local_t / 0.012, 1.0) * pow(1.0 - local_t / beat, 2.5)
		var hz := float(notes[beat_index])
		var melody := sin(TAU * hz * local_t) * 0.24 * envelope if hz > 0.0 else 0.0
		var bass_hz := float(roots[beat_index / 4])
		var bass := sin(TAU * bass_hz * local_t) * 0.13 * envelope
		samples[index] = melody + bass
	return _wave(samples, true)


func _story_foley(kind: String) -> AudioStreamWAV:
	## Short, characterful page cues. These stay below the music and never
	## block scene input; each cue is a tiny bounded mono WAV made at runtime.
	var durations := {
		"open":0.52, "page":0.32, "pencil":0.24, "bonk":0.26,
		"magic":0.46, "glitch":0.34, "chomp":0.28, "swish":0.25,
		"spark":0.30, "next":0.18, "skip":0.24, "hover":0.09, "close":0.40
	}
	var duration: float = float(durations.get(kind,0.24))
	var count := int(duration * RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("story/" + kind)
	var phase_a := 0.0
	var phase_b := 0.0
	var noise_memory := 0.0
	for index in range(count):
		var t := float(index) / RATE
		var progress := t / duration
		var attack := minf(1.0,t/0.006)
		var release := pow(maxf(0.0,1.0-progress),1.35)
		var sample := 0.0
		match kind:
			"open":
				# Page lift: a breath of filtered paper followed by a soft chime.
				noise_memory = noise_memory*0.76 + rng.randf_range(-1.0,1.0)*0.24
				phase_a += TAU*(150.0+260.0*progress)/RATE
				phase_b += TAU*(620.0-210.0*progress)/RATE
				sample = noise_memory*0.32*exp(-t*8.0) + sin(phase_a)*0.15*exp(-t*5.0) + sin(phase_b)*0.10*exp(-t*4.0)
			"page":
				noise_memory = noise_memory*0.70 + rng.randf_range(-1.0,1.0)*0.30
				phase_a += TAU*(360.0-180.0*progress)/RATE
				sample = noise_memory*0.42*exp(-t*10.0) + sin(phase_a)*0.10*release
			"pencil":
				noise_memory = noise_memory*0.50 + rng.randf_range(-1.0,1.0)*0.50
				phase_a += TAU*(760.0+180.0*sin(progress*PI))/RATE
				sample = noise_memory*0.20*exp(-t*7.0) + sin(phase_a)*0.16*release
			"bonk":
				phase_a += TAU*(190.0-95.0*progress)/RATE
				phase_b += TAU*(430.0+80.0*progress)/RATE
				sample = sin(phase_a)*0.50*exp(-t*12.0) + sin(phase_b)*0.11*release
			"magic":
				phase_a += TAU*(420.0+720.0*progress)/RATE
				phase_b += TAU*(840.0+360.0*progress)/RATE
				sample = (sin(phase_a)*0.20 + sin(phase_b)*0.12)*release
			"glitch":
				phase_a += TAU*(210.0+680.0*progress)/RATE
				var gate := 1.0 if fmod(t,0.045) < 0.022 else -0.42
				sample = (sin(phase_a)*0.25 + gate*0.11)*release
			"chomp":
				phase_a += TAU*(480.0-300.0*progress)/RATE
				phase_b += TAU*(170.0+90.0*progress)/RATE
				sample = sin(phase_a)*0.18*release + sin(phase_b)*0.30*exp(-t*14.0)
			"swish":
				phase_a += TAU*(980.0-690.0*progress)/RATE
				sample = sin(phase_a)*0.24*release
			"spark":
				phase_a += TAU*(740.0+740.0*progress)/RATE
				sample = sin(phase_a)*0.23*release
			"next":
				phase_a += TAU*(540.0+240.0*progress)/RATE
				sample = sin(phase_a)*0.24*release
			"skip":
				phase_a += TAU*(430.0-220.0*progress)/RATE
				sample = sin(phase_a)*0.22*release
			"hover":
				phase_a += TAU*780.0/RATE
				sample = sin(phase_a)*0.18*release
			"close":
				phase_a += TAU*(680.0-420.0*progress)/RATE
				sample = sin(phase_a)*0.18*release
		samples[index] = sample*attack
	return _wave(samples)


func _story_music_loop() -> AudioStreamWAV:
	## A soft twelve-second felt-piano/page-turn bed for comic scenes.
	var beat := 0.60
	var notes := [392.0,0.0,523.25,659.25,0.0,587.33,440.0,0.0,349.23,440.0,523.25,0.0,392.0,0.0,293.66,0.0,440.0,523.25,659.25,0.0]
	var roots := [98.0,110.0,82.41,87.31,98.0]
	var count := int(notes.size()*beat*RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for index in range(count):
		var t := float(index)/RATE
		var step := int(t/beat)
		var local := fmod(t,beat)
		var envelope := minf(local/0.014,1.0)*pow(maxf(0.0,1.0-local/beat),2.4)
		var hz := float(notes[step])
		var melody := (sin(TAU*hz*local)+0.18*sin(TAU*hz*2.0*local))*0.18*envelope if hz>0.0 else 0.0
		var root := float(roots[mini(roots.size()-1,step/4)])
		var bass := sin(TAU*root*local)*0.095*envelope
		var airy := sin(TAU*(root*3.01)*local)*0.018*envelope
		samples[index] = melody+bass+airy
	return _wave(samples,true)


func _signature_stream(style: String) -> AudioStreamWAV:
	## Small original, layered cues: a fast tonal gesture plus a tactile burst.
	## These are intentionally short so gameplay timing and readable warnings win.
	var durations := {
		"spin":0.72, "quake":0.78, "dash":0.48, "blocks":0.66, "signal":0.58,
		"swarm":0.70, "chomp":0.63, "glitch":0.68, "void":0.88, "ore":0.75,
		"fossil":0.70, "home_run":0.82, "swerve":0.67, "cluck":0.76, "rainbow":0.78,
		"pellet":0.62, "cursor_stamp":0.66, "ink_geyser":0.70, "eraser":0.72,
		"firewall":0.78, "dark_slash":0.68, "dark_rift":0.90, "eclipse":0.86,
		"dark_blade":0.30, "cursor_tap":0.22, "bite":0.24,
		"dark_quake":0.84, "camera_flash":0.38, "packet_blast":0.56,
	}
	var duration: float = float(durations.get(style, 0.58))
	var count := int(duration * RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("signature/" + style)
	var noise_memory := 0.0
	var phase_a := 0.0
	var phase_b := 0.0
	for index in range(count):
		var t := float(index) / RATE
		var progress := t / duration
		noise_memory = noise_memory * 0.72 + rng.randf_range(-1.0, 1.0) * 0.28
		var sample := 0.0
		var sweep := 0.0
		var grit := 0.0
		match style:
			"spin":
				sweep = _sfx_chirp(t, 0.0, 0.66, 240.0, 880.0, 0.23) + _sfx_chirp(t, 0.12, 0.53, 690.0, 180.0, 0.13)
				grit = noise_memory * exp(-t * 7.0) * 0.16
				for onset in [0.25, 0.48]:
					sample += _sfx_chirp(t, onset, 0.10, 170.0, 95.0, 0.15)
			"quake":
				sweep = _sfx_chirp(t, 0.13, 0.45, 92.0, 38.0, 0.47)
				grit = noise_memory * exp(-maxf(0.0, t - 0.13) * 15.0) * (0.30 if t >= 0.13 else 0.0)
				for onset in [0.31, 0.42, 0.55]:
					sample += _sfx_chirp(t, onset, 0.09, 620.0 - (onset * 240.0), 180.0, 0.075)
			"dash":
				sweep = _sfx_chirp(t, 0.0, 0.43, 340.0, 1480.0, 0.30)
				grit = noise_memory * exp(-t * 8.0) * 0.20
			"blocks":
				for item in [[0.04, 970.0], [0.20, 690.0], [0.37, 430.0]]:
					sample += _sfx_chirp(t, float(item[0]), 0.14, float(item[1]), float(item[1]) * 0.52, 0.20)
				grit = noise_memory * exp(-t * 13.0) * 0.16
			"signal", "firewall":
				sweep = _sfx_chirp(t, 0.0, 0.42, 520.0, 1460.0, 0.21) + _sfx_chirp(t, 0.20, 0.32, 1240.0, 720.0, 0.13)
				grit = noise_memory * exp(-t * 20.0) * (0.12 if style == "firewall" else 0.06)
			"swarm", "rainbow":
				var notes := [523.25, 659.25, 783.99, 1046.5] if style == "swarm" else [392.0, 523.25, 659.25, 783.99, 1046.5]
				var spacing := 0.105 if style == "swarm" else 0.095
				for note_index in range(notes.size()):
					sample += _sfx_chirp(t, note_index * spacing, 0.25, notes[note_index], notes[note_index] * 1.025, 0.105)
				grit = noise_memory * exp(-t * 16.0) * 0.06
			"chomp":
				for item in [[0.02, 470.0], [0.20, 290.0], [0.38, 210.0]]:
					sample += _sfx_chirp(t, float(item[0]), 0.16, float(item[1]), float(item[1]) * 0.56, 0.19)
				grit = noise_memory * exp(-t * 17.0) * 0.22
			"glitch":
				var gate := 1.0 if fmod(t, 0.055) < 0.030 else -0.48
				phase_a += TAU * (250.0 + 940.0 * progress) / RATE
				sweep = (sin(phase_a) + sin(phase_a * 2.0) * 0.28) * gate * exp(-t * 2.9) * 0.25
				grit = noise_memory * exp(-t * 15.0) * 0.12
			"void", "dark_rift", "eclipse":
				var sub_onset := 0.50 if style != "eclipse" else 0.39
				sweep = _sfx_chirp(t, 0.0, duration, 210.0, 42.0, 0.18) + _sfx_chirp(t, sub_onset, 0.32, 72.0, 34.0, 0.42)
				phase_b += TAU * (440.0 + 180.0 * sin(progress * PI)) / RATE
				sample += sin(phase_b) * exp(-t * 2.5) * 0.09
				grit = noise_memory * exp(-t * 5.0) * (0.19 if t < sub_onset else 0.10)
			"ore", "pellet":
				for item in [[0.03, 680.0], [0.22, 890.0], [0.41, 1180.0]]:
					sample += _sfx_chirp(t, float(item[0]), 0.16, float(item[1]), float(item[1]) * 0.64, 0.14)
				grit = noise_memory * exp(-t * 13.0) * 0.13
			"fossil":
				sweep = _sfx_chirp(t, 0.0, 0.32, 520.0, 1140.0, 0.18) + _sfx_chirp(t, 0.34, 0.32, 1140.0, 390.0, 0.16)
				grit = noise_memory * exp(-t * 13.0) * 0.11
			"home_run":
				sweep = _sfx_chirp(t, 0.08, 0.55, 135.0, 63.0, 0.35) + _sfx_chirp(t, 0.22, 0.46, 430.0, 1280.0, 0.16)
				grit = noise_memory * exp(-maxf(0.0, t - 0.08) * 12.0) * (0.22 if t >= 0.08 else 0.0)
			"swerve":
				sweep = _sfx_chirp(t, 0.0, 0.18, 150.0, 82.0, 0.28) + _sfx_chirp(t, 0.16, 0.45, 410.0, 1040.0, 0.14)
				for onset in [0.28, 0.48]:
					sample += _sfx_chirp(t, onset, 0.08, 360.0, 590.0, 0.10)
			"cluck":
				sweep = _sfx_chirp(t, 0.0, 0.28, 1120.0, 470.0, 0.24) + _sfx_chirp(t, 0.24, 0.36, 165.0, 72.0, 0.29)
				grit = noise_memory * exp(-t * 18.0) * 0.16
			"cursor_stamp":
				sweep = _sfx_chirp(t, 0.0, 0.25, 1200.0, 460.0, 0.14) + _sfx_chirp(t, 0.15, 0.32, 120.0, 54.0, 0.35)
				grit = noise_memory * exp(-t * 22.0) * 0.17
			"ink_geyser":
				sweep = _sfx_chirp(t, 0.0, 0.60, 170.0, 920.0, 0.18)
				grit = noise_memory * exp(-t * 4.8) * 0.17
			"eraser":
				sweep = _sfx_chirp(t, 0.0, 0.58, 820.0, 240.0, 0.18) + _sfx_chirp(t, 0.43, 0.20, 180.0, 78.0, 0.28)
				grit = noise_memory * exp(-t * 8.0) * 0.17
			"dark_slash":
				sweep = _sfx_chirp(t, 0.0, 0.48, 1280.0, 155.0, 0.23) + _sfx_chirp(t, 0.24, 0.25, 93.0, 45.0, 0.31)
				grit = noise_memory * exp(-t * 10.0) * 0.15
			"dark_blade":
				sweep = _sfx_chirp(t, 0.0, 0.25, 760.0, 210.0, 0.19) + _sfx_chirp(t, 0.035, 0.16, 1480.0, 520.0, 0.08)
				grit = noise_memory * exp(-t * 22.0) * 0.09
			"cursor_tap":
				sweep = _sfx_chirp(t, 0.0, 0.075, 1080.0, 440.0, 0.17) + _sfx_chirp(t, 0.065, 0.12, 560.0, 920.0, 0.10)
				grit = noise_memory * exp(-t * 30.0) * 0.08
			"bite":
				sweep = _sfx_chirp(t, 0.0, 0.095, 520.0, 150.0, 0.18) + _sfx_chirp(t, 0.12, 0.07, 980.0, 390.0, 0.10)
				grit = noise_memory * exp(-t * 24.0) * 0.18
			"dark_quake":
				sweep = _sfx_chirp(t, 0.12, 0.56, 74.0, 31.0, 0.44) + _sfx_chirp(t, 0.34, 0.20, 690.0, 115.0, 0.11)
				for onset in [0.30, 0.46, 0.62]:
					sample += _sfx_chirp(t, onset, 0.10, 510.0 - onset * 260.0, 82.0, 0.10)
				grit = noise_memory * exp(-maxf(0.0, t - 0.12) * 12.0) * (0.28 if t >= 0.12 else 0.0)
			"camera_flash":
				sweep = _sfx_chirp(t, 0.0, 0.095, 1620.0, 920.0, 0.22) + _sfx_chirp(t, 0.10, 0.24, 520.0, 108.0, 0.18)
				grit = noise_memory * exp(-t * 27.0) * 0.12
			"packet_blast":
				for onset in [0.015, 0.085, 0.155, 0.235]:
					sample += _sfx_chirp(t, onset, 0.09, 1180.0 - onset * 1700.0, 390.0, 0.12)
				phase_a += TAU * (180.0 + 700.0 * progress) / RATE
				sweep = sin(phase_a) * (1.0 if fmod(t, 0.036) < 0.018 else -0.55) * exp(-t * 5.0) * 0.16
				grit = noise_memory * exp(-t * 20.0) * 0.11
		samples[index] = tanh((sweep + sample + grit) * 1.1) * 0.72
	return _wave(samples)


func _sfx_chirp(t: float, onset: float, duration: float, start_hz: float, end_hz: float, gain: float) -> float:
	var local := t - onset
	if local < 0.0 or local >= duration:
		return 0.0
	var progress := local / duration
	var phase := TAU * (start_hz * local + (end_hz - start_hz) * local * local / (2.0 * duration))
	var envelope := minf(1.0, local / 0.003) * pow(1.0 - progress, 1.7)
	return (sin(phase) + 0.20 * sin(phase * 2.01) + 0.055 * sin(phase * 3.97)) * envelope * gain
