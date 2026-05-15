extends Button

@export var escena_principal: PackedScene
@onready var hover_audio: AudioStreamPlayer = $"../HoverAudio"


func _ready() -> void:
	pressed.connect(_jugar, 4)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _jugar():
	get_tree().change_scene_to_packed(escena_principal)


func _on_mouse_entered() -> void:
	hover_audio.play()
