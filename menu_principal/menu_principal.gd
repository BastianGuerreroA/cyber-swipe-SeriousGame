extends Control
@onready var music_menu: AudioStreamPlayer = $MusicMenu


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	music_menu.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
