extends Control
@onready var music_menu: AudioStreamPlayer = $MusicMenu

func _ready() -> void:
	if not music_menu.finished.is_connected(_on_music_finished):
		music_menu.finished.connect(_on_music_finished)
	music_menu.play()

func _on_music_finished() -> void:
	music_menu.play()
