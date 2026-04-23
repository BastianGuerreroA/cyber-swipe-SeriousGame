extends Control

@onready var panel = $PanelLogin
@onready var boton_lsg = $BotonLSG

func _ready():
	panel.visible = false

# Abrir panel
func _on_boton_lsg_pressed():
	panel.visible = true
	boton_lsg.visible = false
	
	panel.scale = Vector2(0.8, 0.8)
	panel.modulate.a = 0
	
	var tween = create_tween()
	tween.tween_property(panel, "scale", Vector2(1,1), 0.2)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)

# Cerrar panel
func _on_boton_cerrar_pressed():
	panel.visible = false
	boton_lsg.visible = true
