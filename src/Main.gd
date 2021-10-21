extends Node2D


func _ready() -> void:
	Console.add_command('zoom_out', self).register()
	Console.add_command('zoom_in', self).register()


func zoom_out() -> void:
	$Camera2D.zoom += Vector2.ONE * 0.5


func zoom_in() -> void:
	$Camera2D.zoom -= Vector2.ONE * 0.5
