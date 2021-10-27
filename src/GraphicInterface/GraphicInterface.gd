extends CanvasLayer
#warning-ignore-all:return_value_discarded

onready var _character_info: WindowDialog = find_node('CharacterInfo')
onready var _margin_container: Container =\
_character_info.find_node('MarginContainer')
onready var _character_container: PanelContainer =\
_character_info.find_node('CharacterContainer')
onready var _character_artist: Label =\
_character_info.find_node('CharacterArtist')
onready var _character_description: Label =\
_character_info.find_node('Description')
onready var _default_popup_size := _character_info.rect_min_size
onready var _default_character_container_size := _character_container.rect_size.x

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	E.connect('character_clicked', self, '_show_character_info')
	_character_info.connect('popup_hide', E, 'emit_signal', ['character_popup_closed'])


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _show_character_info(character: KinematicBody2D) -> void:
	if _character_container.get_child_count() > 0:
		_character_container.get_child(0).queue_free()
	
	# ---- Devolver las cosas a sus tamaños por defecto ------------------------
	_character_container.rect_size.x = _default_character_container_size
	_character_container.rect_min_size.x = _default_character_container_size
	_margin_container.rect_size = _default_popup_size
	_margin_container.rect_min_size = _default_popup_size
	yield(get_tree(), 'idle_frame')
	# ------------------------ Devolver las cosas a sus tamaños por defecto ----
	
	randomize()
	var sound = randi()% 7+ 1
	AudioMgr.emit_signal('play_requested', 'VX', 'Voice%s' % sound)
	
	_character_description.hide()
	_character_artist.hide()
	
	yield(get_tree().create_timer(0.5), 'timeout')
	
#	_character_info.window_title = character.character_name
	
	if character.character_description:
		_character_artist.text = character.character_artist
		_character_description.text = character.character_description
		_character_artist.show()
		_character_description.show()
	
	var animated_sprite: AnimatedSprite =\
	character.get_node('PopupAnimatedSprite').duplicate()
	var texture: Texture = animated_sprite.frames.get_frame('default', 0)
	
	animated_sprite.play('default')
	animated_sprite.show()
	
	_character_container.add_child(animated_sprite)
	_character_container.rect_size.x =\
	texture.get_width() * animated_sprite.scale.x
	_character_container.rect_min_size.x =\
	texture.get_width() * animated_sprite.scale.x
	
	
	yield(get_tree(), 'idle_frame')
	_character_info.popup_centered(_default_popup_size)
	_character_info.rect_size = _margin_container.rect_size + (Vector2.ONE * 20.0)
	animated_sprite.position = _character_container.rect_size / 2
