extends Node2D
@export var MusicaFondo: AudioStreamPlayer2D

func _ready() -> void:
	MusicaFondo.play()

func _on_boton_pausa_pressed() -> void:
	# 1. Ocultamos el botón de pausa para que desaparezca
	$CanvasLayer/MarginContainer/BotonPausa.visible = false
	
	# 2. Hacemos visible el menú de pausa
	$CanvasLayer/MarginContainer/PauseMenu.visible = true
	
	# 3. Congelamos el juego
	get_tree().paused = true
