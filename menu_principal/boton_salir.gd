extends Button
@onready var hover_audio: AudioStreamPlayer = $"../HoverAudio"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_salir)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _salir() -> void:
	get_tree().quit()


func _on_mouse_entered() -> void:
	hover_audio.play()
