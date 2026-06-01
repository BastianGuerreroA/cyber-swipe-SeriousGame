extends Node

# Variables de estado global
var nombre_usuario: String = "Usuario"
var puntos_totales: int = 0
var progreso_general: int = 0
var lista_capsulas: Array = []

# ID de la cápsula que el jugador seleccionó para Estudiar o Practicar
var capsula_activa_id: int = 1

func _ready() -> void:
	cargar_datos_desde_json()

# Función para leer el archivo JSON externo
func cargar_datos_desde_json() -> void:
	var ruta_archivo = "res://capsulas.json"
	
	if not FileAccess.file_exists(ruta_archivo):
		print("ERROR: No se encontró el archivo JSON en: ", ruta_archivo)
		return
		
	var archivo = FileAccess.open(ruta_archivo, FileAccess.READ)
	var contenido_texto = archivo.get_as_text()
	archivo.close()
	
	var json = JSON.new()
	var error = json.parse(contenido_texto)
	
	if error == OK:
		var datos = json.data
		# Guardamos los datos del usuario
		nombre_usuario = datos["usuario"]["nombre"]
		puntos_totales = datos["usuario"]["puntos_totales"]
		progreso_general = datos["usuario"]["progreso_general"]
		# Guardamos las cápsulas
		lista_capsulas = datos["capsulas"]
		print("Datos cargados correctamente. Cápsulas importadas: ", lista_capsulas.size())
	else:
		print("ERROR al parsear JSON: ", json.get_error_message())

# Retorna los datos de una cápsula específica por su ID
func obtener_capsula(id: int) -> Dictionary:
	for cap in lista_capsulas:
		if cap["id"] == id:
			return cap
	return {}

# Retorna las cartas de la cápsula activa para el CardManager
func obtener_cartas_de_capsula_activa() -> Array:
	var cap = obtener_capsula(capsula_activa_id)
	if not cap.is_empty() and cap.has("cartas"):
		return cap["cartas"]
	return []
