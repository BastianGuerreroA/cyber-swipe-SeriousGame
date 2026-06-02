extends Node

# Variables de estado global
var nombre_usuario: String = "Usuario"
var puntos_totales: int = 0
var progreso_general: int = 1
var lista_capsulas: Array = []
# ID de la cápsula que el jugador seleccionó para Estudiar o Practicar
var capsula_activa_id: int = 1
var puntaje_ronda_actual: int = 0
var puntajes_maximos: Dictionary = {} # Guarda { id_capsula: record_puntaje }

# Definimos la ruta del recurso del jugador en la carpeta de usuario del dispositivo
const RUTA_GUARDADO_TRES = "user://progreso_usuario.tres"
const RUTA_CONTENIDO_JSON = "res://capsulas.json"

func _ready() -> void:
	# 1. Cargar el contenido estático de las cápsulas (JSON generado por LLM o Desarrollador)
	cargar_contenido_capsulas()
	
	# 2. Cargar el progreso del jugador (Resource nativo de Godot)
	cargar_progreso_jugador()


# Lee los datos de las cartas y textos (JSON)
func cargar_contenido_capsulas() -> void:
	if not FileAccess.file_exists(RUTA_CONTENIDO_JSON):
		print("ERROR: No se encontró capsulas.json")
		return
	var archivo = FileAccess.open(RUTA_CONTENIDO_JSON, FileAccess.READ)
	var json = JSON.new()
	if json.parse(archivo.get_as_text()) == OK:
		lista_capsulas = json.data["capsulas"]
	archivo.close()


# Carga los récords y datos del usuario (Resource)
func cargar_progreso_jugador() -> void:
	if ResourceLoader.exists(RUTA_GUARDADO_TRES):
		var progreso = ResourceLoader.load(RUTA_GUARDADO_TRES) as ProgresoUsuario
		if progreso:
			nombre_usuario = progreso.nombre_usuario
			puntos_totales = progreso.puntos_totales
			progreso_general = progreso.progreso_general
			puntajes_maximos = progreso.puntajes_maximos
			if progreso_general < 1:
				progreso_general = 1
			print("Progreso del usuario cargado desde Resource (.tres)")


# Guarda los récords y datos del usuario (Resource)
func guardar_progreso() -> void:
	var progreso = ProgresoUsuario.new()
	progreso.nombre_usuario = nombre_usuario
	progreso.puntos_totales = puntos_totales
	progreso.progreso_general = progreso_general
	progreso.puntajes_maximos = puntajes_maximos # o tu variable de diccionario
	
	# Aseguramos guardar los datos de puntajes_maximos locales en el recurso
	progreso.puntajes_maximos = puntajes_maximos
	
	var error = ResourceSaver.save(progreso, RUTA_GUARDADO_TRES)
	if error == OK:
		print("Progreso guardado exitosamente en formato Resource (.tres)")
	else:
		print("Error al guardar el Resource (.tres): ", error)

# Retorna una cápsula específica por su ID desde la lista cargada
func obtener_capsula(id: int) -> Dictionary:
	for cap in lista_capsulas:
		if cap["id"] == id:
			return cap
	return {}
	
# Retorna las cartas correspondientes a la cápsula que se está jugando
func obtener_cartas_de_capsula_activa() -> Array:
	var cap = obtener_capsula(capsula_activa_id)
	if not cap.is_empty() and cap.has("cartas"):
		return cap["cartas"]
	return []
	
# Retorna el puntaje récord guardado para una cápsula
func obtener_record_capsula(id: int) -> int:
	if puntajes_maximos.has(id):
		return puntajes_maximos[id]
	return 0
	

func registrar_fin_de_juego(victoria: bool) -> void:
	var record_actual = obtener_record_capsula(capsula_activa_id)
	
	# 1. Registrar el récord si se superó
	if puntaje_ronda_actual > record_actual:
		puntajes_maximos[capsula_activa_id] = puntaje_ronda_actual
		
		# Recalcular puntos totales
		var suma = 0
		for record in puntajes_maximos.values():
			suma += record
		puntos_totales = suma
	
	# 2. Desbloquear la siguiente cápsula si el jugador GANÓ la cápsula de su nivel máximo actual
	if victoria and capsula_activa_id == progreso_general:
		# Incrementamos en 1 el nivel desbloqueado (máximo número total de cápsulas)
		progreso_general = clampi(progreso_general + 1, 1, lista_capsulas.size())
	
	# 3. Guardar cambios en el recurso .tres
	guardar_progreso()


	
