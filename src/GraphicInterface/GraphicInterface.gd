extends CanvasLayer
#warning-ignore-all:return_value_discarded

onready var _character_info: WindowDialog = find_node('CharacterInfo')
onready var _character_photo: TextureRect = _character_info.find_node('Photo')
onready var _character_description: Label = _character_info.find_node('Description')

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	E.connect('character_clicked', self, '_show_character_info')
	_character_info.connect('popup_hide', E, 'emit_signal', ['character_popup_closed'])


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _show_character_info(character: KinematicBody2D) -> void:
	randomize()
	var sound = randi()% 7+ 1
	AudioMgr.emit_signal('play_requested', 'VX', 'Voice%s' % sound)
	
	_character_photo.hide()
	_character_description.hide()
	
	yield(get_tree().create_timer(0.5), 'timeout')
	
	_character_info.window_title = character.character_name
	
	if character.photo:
		_character_photo.texture = character.photo
		_character_photo.show()
	
	if character.character_description:
		_character_description.text = character.character_description
		_character_description.show()
	
	_character_info.popup_centered(Vector2(800.0, 600.0))
