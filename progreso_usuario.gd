class_name ProgresoUsuario
extends Resource

@export var nombre_usuario: String = "Usuario"
@export var puntos_totales: int = 0
@export var progreso_general: int = 0
@export var puntajes_maximos: Dictionary = {} # Guarda { capsula_id (int) : record (int) }
