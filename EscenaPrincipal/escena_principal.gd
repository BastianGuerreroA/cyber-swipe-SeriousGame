extends Node2D
@export var MusicaFondo: AudioStreamPlayer2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	MusicaFondo.play()
