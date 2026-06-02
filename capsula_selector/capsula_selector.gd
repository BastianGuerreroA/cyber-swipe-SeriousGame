extends Control

@onready var label_usuario = $MarginContainer/ScrollContainer/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HContainer_Usuario/Usuario
@onready var label_puntos = $MarginContainer/ScrollContainer/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HContainer_Usuario/HBoxContainer/Puntos
@onready var label_progreso = $MarginContainer/ScrollContainer/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Hcontainer_Progreso/HBoxContainer/Label
@onready var label_total_capsulas = $MarginContainer/ScrollContainer/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Hcontainer_Progreso/HBoxContainer/TotalCapsulas
@onready var contenedor_capsulas = $MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer_capsulas

# Precargamos la escena del item de la cápsula para instanciarla
const CAPSULA_ITEM_ESCENA = preload("res://Capsula_Item/capsula_item.tscn")

func _ready() -> void:
	# 1. Cargar datos del perfil de usuario
	label_usuario.text = CapsulaManager.nombre_usuario
	label_puntos.text = str(CapsulaManager.puntos_totales)
	
	# Las completadas serán el nivel máximo desbloqueado menos 1
	var completadas = clampi(CapsulaManager.progreso_general - 1, 0, CapsulaManager.lista_capsulas.size())
	label_progreso.text = str(completadas)
	label_total_capsulas.text = "/" + str(CapsulaManager.lista_capsulas.size())
	
	# Limpiar placeholders
	for child in contenedor_capsulas.get_children():
		child.queue_free()
		
	# 2. Rellenar la lista evaluando el estado de cada cápsula
	for datos_capsula in CapsulaManager.lista_capsulas:
		var id_cap = datos_capsula["id"]
		
		# Si su ID es menor al progreso_general, ya fue ganada (Completada)
		if id_cap < CapsulaManager.progreso_general:
			datos_capsula["estado"] = "Completada"
		# Si su ID es igual al progreso_general, es la que le toca jugar (Disponible)
		elif id_cap == CapsulaManager.progreso_general:
			datos_capsula["estado"] = "Disponible"
		# Si es mayor, aún no llega ahí (Bloqueada)
		else:
			datos_capsula["estado"] = "Bloqueado"
			
		var instancia = CAPSULA_ITEM_ESCENA.instantiate()
		contenedor_capsulas.add_child(instancia)
		instancia.configurar(datos_capsula)
