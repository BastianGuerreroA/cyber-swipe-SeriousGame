extends Control

@onready var label_usuario = $MarginContainer/ScrollContainer/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HContainer_Usuario/Usuario
@onready var label_puntos = $MarginContainer/ScrollContainer/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HContainer_Usuario/HBoxContainer/Puntos
@onready var label_progreso = $MarginContainer/ScrollContainer/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Hcontainer_Progreso/HBoxContainer/Label
@onready var label_total_capsulas = $MarginContainer/ScrollContainer/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Hcontainer_Progreso/HBoxContainer/TotalCapsulas
@onready var contenedor_capsulas = $MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer_capsulas

# Precargamos la escena del item de la cápsula para instanciarla
const CAPSULA_ITEM_ESCENA = preload("res://Capsula_Item/capsula_item.tscn")

func _ready() -> void:
	# 1. Cargar datos del perfil de usuario desde el Singleton
	label_usuario.text = CapsulaManager.nombre_usuario
	label_puntos.text = str(CapsulaManager.puntos_totales)
	label_progreso.text = str(CapsulaManager.progreso_general)
	label_total_capsulas.text = "/" + str(CapsulaManager.lista_capsulas.size())
	
	# 2. Limpiar todos los nodos de ejemplo (los placeholders CapsulaItem1, CapsulaItem2 que tienes en el .tscn)
	for child in contenedor_capsulas.get_children():
		child.queue_free()
		
	# 3. Generar la lista dinámicamente a partir del JSON cargado en el Singleton
	for datos_capsula in CapsulaManager.lista_capsulas:
		var instancia = CAPSULA_ITEM_ESCENA.instantiate()
		contenedor_capsulas.add_child(instancia)
		instancia.configurar(datos_capsula)
