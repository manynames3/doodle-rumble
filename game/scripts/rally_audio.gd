extends Node
## Dedicated original Rally music. Shared Sound owns routing back to the fighting game.
const RATE := 22050
var _loops: Dictionary = {}
var _sounds: Dictionary = {}
var _music: AudioStreamPlayer
var _previous: AudioStreamPlayer
var _voices: Array[AudioStreamPlayer] = []
var _theme := ""
var _silent := false
var _fade := 1.0
var _voice := 0
var _last_events: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_silent = DisplayServer.get_name()=="headless" or "--silent-qa" in OS.get_cmdline_user_args()
	_music=AudioStreamPlayer.new()
	_previous=AudioStreamPlayer.new()
	add_child(_music)
	add_child(_previous)
	for i in range(6):
		var player := AudioStreamPlayer.new()
		add_child(player)
		_voices.append(player)
	for theme in ["desk","castle","sky"]:
		var stream: AudioStreamWAV = load("res://assets/rally/music/%s.wav"%theme)
		stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
		stream.loop_end=stream.data.size()/4
		_loops[theme]=stream
	for cue in ["star","turbo","ramp","hop","splash","gate_hit","gate_clear","wind","drift_boost","finish","challenge_complete"]:
		var tones: Array = {"star":[880,1320],"turbo":[160,880],"ramp":[360,1100],"hop":[260,590],"splash":[240,90],"gate_hit":[180,80],"gate_clear":[520,784],"wind":[460,600],"drift_boost":[660,1100],"finish":[523,1046],"challenge_complete":[660,1320]}[cue]
		_sounds[cue]=_chirp(tones[0],tones[1],0.34 if cue=="finish" else 0.13)

func play_theme(theme: String) -> void:
	var chosen := theme if _loops.has(theme) else "desk"
	if chosen==_theme: return
	_theme=chosen
	_previous.stop()
	var swap := _music
	_music=_previous
	_previous=swap
	_music.stream=_loops[chosen]
	_fade=0.0
	if not _silent: _music.play()
	_apply_mix()

func event(kind: String, style: int = 0) -> void:
	if not _sounds.has(kind) or _silent or Settings.master_volume<=0 or Settings.sfx_volume<=0: return
	var now := Time.get_ticks_msec()
	if now-int(_last_events.get(kind,-1000))<55: return
	_last_events[kind]=now
	var player := _voices[_voice]
	_voice=(_voice+1)%_voices.size()
	player.stream=_sounds[kind]
	player.pitch_scale=1.0+style*0.065
	player.volume_db=linear_to_db(maxf(.0001,Settings.master_volume*Settings.sfx_volume*.6))
	player.play()

func _process(delta: float) -> void:
	_fade=minf(1.0,_fade+delta/.65)
	if _fade>=1 and _previous.playing: _previous.stop()
	_apply_mix()

func _apply_mix() -> void:
	var gain := Settings.master_volume*Settings.music_volume*.65
	_music.volume_db=linear_to_db(maxf(.0001,gain*_fade))
	_previous.volume_db=linear_to_db(maxf(.0001,gain*(1.0-_fade)))
	_music.stream_paused=gain<=0
	_previous.stream_paused=gain<=0
	for player in _voices:
		player.volume_db=linear_to_db(maxf(.0001,Settings.master_volume*Settings.sfx_volume*.6))
		player.stream_paused=Settings.master_volume<=0 or Settings.sfx_volume<=0

func stop() -> void:
	for player in [_music,_previous]+_voices:
		if is_instance_valid(player):
			player.stop()
			player.stream = null

func _exit_tree() -> void:
	stop()

func _chirp(start: float, finish: float, duration: float) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	var frames := int(RATE*duration)
	bytes.resize(frames*2)
	for i in range(frames):
		var t := float(i)/RATE
		var progress := t/duration
		var phase := TAU*(start*t+(finish-start)*t*t/(2*duration))
		var v := sin(phase)*minf(1,t/.007)*pow(1-progress,1.6)*.36
		var sample := int(v*32760)
		bytes[i*2]=sample&255
		bytes[i*2+1]=(sample>>8)&255
	var wave := AudioStreamWAV.new()
	wave.format=AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate=RATE
	wave.data=bytes
	return wave
