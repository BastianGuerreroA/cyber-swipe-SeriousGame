extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():

	var cap = CryptoManager.load_capsule(
		"res://resources/data/capsules/capsule_001.lsg"
	)

	print(cap)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
