extends Button

@export var escena_capsulas: PackedScene
@onready var hover_audio: AudioStreamPlayer = $"../HoverAudio"


func _ready() -> void:
	pressed.connect(_comenzar, 4)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _comenzar():
	get_tree().change_scene_to_packed(escena_capsulas)


func _on_mouse_entered() -> void:
	hover_audio.play()
