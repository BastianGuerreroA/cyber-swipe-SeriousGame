extends Control

@export var presupuesto: Array[Texture2D] = []
@export var integridad: Array[Texture2D] = []
@export var disponibilidad: Array[Texture2D] = []
@export var confidencialidad: Array[Texture2D] = []

# Guardamos referencias directas a los TextureRect
@onready var icon_presupuesto = $HBoxContainer/VBoxContainer_p/Presupuesto
@onready var icon_integridad = $HBoxContainer/VBoxContainer_I/Intregridad
@onready var icon_disponibilidad = $HBoxContainer/VBoxContainer_D/Disponibilidad
@onready var icon_confidencialidad = $HBoxContainer/VBoxContainer_C/Confidencialidad

#Referencias de cada circulo
@onready var circulo_presupuesto = $HBoxContainer/VBoxContainer_p/Circulo_Preupuesto
@onready var circulo_integridad = $HBoxContainer/VBoxContainer_I/Circulo_Integridad
@onready var circulo_disponibilidad = $HBoxContainer/VBoxContainer_D/Circulo_Disponibilidad
@onready var circulo_confidencialidad = $HBoxContainer/VBoxContainer_C/Circulo_Confidencialidad


# Función matemática que transforma de 0-100 a un índice 0-4
func obtener_indice(valor: int) -> int:
	if valor <= 20: return 0
	elif valor <= 40: return 1
	elif valor <= 60: return 2
	elif valor <= 80: return 3
	else: return 4

func _on_card_manager_metricas_actualizadas(p: Variant, c: Variant, i: Variant, d: Variant) -> void:
	# Verificamos que llenaste los arreglos en el inspector para evitar crasheos
	if presupuesto.size() > 0: icon_presupuesto.texture = presupuesto[obtener_indice(p)]
	if confidencialidad.size() > 0: icon_confidencialidad.texture = confidencialidad[obtener_indice(c)]
	if integridad.size() > 0: icon_integridad.texture = integridad[obtener_indice(i)]
	if disponibilidad.size() > 0: icon_disponibilidad.texture = disponibilidad[obtener_indice(d)]


# Recibe el efecto de la decisión. Si es null, apaga todo.
func mostrar_indicadores(efecto) -> void:
	if efecto == null:
		circulo_presupuesto.visible = false
		circulo_integridad.visible = false
		circulo_disponibilidad.visible = false
		circulo_confidencialidad.visible = false
	else:
		# Se hacen visibles SOLO si el efecto matemático no es 0
		circulo_presupuesto.visible = (efecto["presupuesto"] != 0)
		circulo_integridad.visible = (efecto["integridad"] != 0)
		circulo_disponibilidad.visible = (efecto["disponibilidad"] != 0)
		circulo_confidencialidad.visible = (efecto["confidencialidad"] != 0)
