extends Node2D
#warning-ignore-all:return_value_discarded

var _sources: Array = []

func _ready():
	for src in get_children():
		_sources.append(src.name)
	
	AudioMgr.connect('play_requested', self, 'play_sound')
	AudioMgr.connect('stop_requested', self, 'stop_sound')
	AudioMgr.connect('pause_requested', self, 'pause_sound')
	AudioMgr.emit_signal('play_requested', 'MX', 'Music')
	
func _get_audio(source, sound) -> Node:
	return get_node(''+source+'/'+sound)

func play_sound(source: String, sound: String) -> void:
	var audio: Node = _get_audio(source, sound)
	if source == 'VX':
		randomize()
		var pintch_value = rand_range(0.8, 1.2)
		audio.pitch_scale = pintch_value
	audio.play()
	

func stop_sound(source: String, sound: String) -> void:
	_get_audio(source, sound).stop()


func pause_sound(source: String, sound: String) -> void:
	var audio: Node = _get_audio(source, sound)
	
	if not audio.get('stream_paused'):
		audio.stream_paused = true

func _on_finished(source, sound):
	AudioMgr.emit_signal('stream_finished', source, sound)
