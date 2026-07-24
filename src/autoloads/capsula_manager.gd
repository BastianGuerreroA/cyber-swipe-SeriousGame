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

# Variable global para registrar la métrica que causó la derrota en la última ronda
var metrica_fallida: String = ""

# Diccionario centralizado de consejos pedagógicos por derrota
const CONSEJOS_DERROTA = {
	"presupuesto": "El presupuesto se agotó. Recuerda que la ciberseguridad no es solo un gasto, sino una inversión necesaria para mitigar incidentes costosos.",
	"confidencialidad": "Fallo de Confidencialidad. Protege tus accesos utilizando contraseñas seguras, gestores y activando doble factor (MFA).",
	"integridad": "Fallo de Integridad. La información crítica se alteró o borró. Mantén respaldos constantes para garantizar que tus datos sean confiables.",
	"disponibilidad": "Fallo de Disponibilidad. Los sistemas quedaron inoperativos (ej. Ransomware). Implementa respaldos offline (fuera de red) y climatiza tus racks."
}

# Diccionario centralizado de consejos/resumen pedagógico por victoria
const CONSEJOS_VICTORIA = {
	1: "¡Excelente! Has aprendido a proteger tus dispositivos físicos con PIN y contraseñas robustas.",
	2: "¡Genial! Sabes cómo identificar correos de phishing y evitar la descarga de archivos fraudulentos.",
	3: "¡Muy bien! Tienes clara la regla de respaldos 3-2-1 para protegerte contra ataques de ransomware.",
	4: "¡Perfecto! Has comprendido la importancia de segmentar tus redes Wi-Fi y usar conexiones VPN seguras.",
	5: "¡Fantástico! Sabes reconocer trampas de ingeniería social física como el Baiting o el Vishing."
}

# Definimos la ruta del recurso del jugador en la carpeta de usuario del dispositivo
const RUTA_GUARDADO_TRES = "user://progreso_usuario.tres"
const RUTA_CARPETA_CAPSULAS = "user://capsules/"

# Rutas base para iconos dinámicos
const RUTA_ICONOS_CAPSULAS = "res://assets/IconosCapsulas/capsula_"
const RUTA_ICONO_DEFECTO = "res://assets/IconosPixelArt/MedallaPixelArt.png"

# Obtiene dinámicamente el ícono de cualquier cápsula (funciona en editor y APK exportada)
func obtener_icono_capsula(id: int) -> Texture2D:
	var ruta_icono = RUTA_ICONOS_CAPSULAS + str(id) + ".png"
	if ResourceLoader.exists(ruta_icono):
		return load(ruta_icono) as Texture2D
		
	if ResourceLoader.exists(RUTA_ICONO_DEFECTO):
		return load(RUTA_ICONO_DEFECTO) as Texture2D
		
	return null

func _ready() -> void:
	# 1. Asegurar la existencia de user://capsules/ y copiar semillas si está vacía
	ContentManager.preparar_directorio_local()
	
	# 2. Cargar el contenido local de las cápsulas (.lsg)
	cargar_contenido_capsulas()
	
	# 3. Cargar el progreso del jugador (Resource nativo de Godot)
	cargar_progreso_jugador()
	
	# 4. Escuchar actualización de GitHub para recargar cápsulas automáticamente
	if not ContentManager.content_sync_completed.is_connected(_on_content_sync_completed):
		ContentManager.content_sync_completed.connect(_on_content_sync_completed)
		
	# 5. Iniciar sincronización remota desde GitHub en segundo plano
	ContentManager.sincronizar_con_github()

func _on_content_sync_completed(_success: bool) -> void:
	print("CapsulaManager: Sincronización finalizada. Recargando cápsulas...")
	cargar_contenido_capsulas()


# Lee los datos de las cartas y textos desde archivos JSON independientes
func cargar_contenido_capsulas() -> void:

	lista_capsulas.clear()

	var dir := DirAccess.open(RUTA_CARPETA_CAPSULAS)

	if dir == null:
		push_error("No existe la carpeta de cápsulas: " + RUTA_CARPETA_CAPSULAS)
		return

	dir.list_dir_begin()

	var file := dir.get_next()

	while file != "":
		if !dir.current_is_dir():
			if file.ends_with(".lsg"):
				# ignoramos el índice
				if file == "index.lsg":
					file = dir.get_next()
					continue

				var path := RUTA_CARPETA_CAPSULAS + file

				var capsule := CryptoManager.load_capsule(path)

				if !capsule.is_empty():
					lista_capsulas.append(capsule)
				else:
					push_warning("No se pudo cargar " + file)

		file = dir.get_next()

	dir.list_dir_end()

	lista_capsulas.sort_custom(
		func(a,b):
			return a.get("id", 0) < b.get("id", 0)
	)

	print("Capsulas cargadas: ", lista_capsulas.size())

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


func existen_capsulas() -> bool:

	var dir := DirAccess.open(RUTA_CARPETA_CAPSULAS)

	if dir == null:
		return false

	dir.list_dir_begin()

	var file := dir.get_next()

	while file != "":
		if file.ends_with(".lsg"):
			if file != "index.lsg":
				dir.list_dir_end()
				return true

		file = dir.get_next()
	dir.list_dir_end()
	return false


func obtener_total_capsulas()->int:
	return lista_capsulas.size()
