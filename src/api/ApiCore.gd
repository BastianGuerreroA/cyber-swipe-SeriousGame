extends Node

signal session_started(session_id: int)
signal session_ended
signal redeem_completed(success: bool, response_data: Dictionary)
signal balance_loaded(balances: Array)
signal attributes_loaded(attributes: Array)
signal adjust_completed(success: bool, response_data: Dictionary)

const BASE_URL = "https://lsg.diinf.usach.cl/lsg-core-api"
const GAME_ID = 54 # ID de CyberSwipe asignado por la API

var active_session_id: int = -1

var active_mechanics: Dictionary = {
	"salvavidas": false,
	"consultoria": false,
	"analisis": false,
	"subsidio": false,
	"ciberseguro": false
}

func reset_active_mechanics() -> void:
	active_mechanics = {
		"salvavidas": false,
		"consultoria": false,
		"analisis": false,
		"subsidio": false,
		"ciberseguro": false
	}
	if LsgAuth.logged_in:
		print("LSG-Core: Ventajas de la ronda reiniciadas.")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Evitamos el cierre inmediato de la aplicación para poder reportar el fin de sesión
	get_tree().set_auto_accept_quit(false)
	
	# Escuchamos los eventos de login para iniciar sesión automáticamente
	LsgAuth.login_success.connect(_on_user_login_success)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_clean_up_and_exit()

func _clean_up_and_exit() -> void:
	print("LSG-Core: Detectado intento de cierre del juego.")
	if LsgLogger.is_active:
		print("LSG-Core: Enviando reporte de telemetria acumulado antes de salir...")
		await LsgLogger.submit_session_log()
	if active_session_id != -1:
		print("LSG-Core: Cerrando sesión activa en servidor antes de salir...")
		await end_session()
	get_tree().quit()

# Inicia la sesión global del juego cuando el usuario se loguea
func _on_user_login_success(_username: String) -> void:
	start_session()
	LsgLogger.start_session()

# Petición para INICIAR la sesión global
func start_session() -> void:
	if not LsgAuth.logged_in or LsgAuth.access_token.is_empty():
		print("LSG-Core: No se puede iniciar sesión de juego sin usuario autenticado.")
		return
		
	var url = BASE_URL + "/videogames/" + str(GAME_ID) + "/players/" + str(LsgAuth.player_id) + "/sessions"
	var headers = PackedStringArray([
		"Authorization: Bearer " + LsgAuth.access_token,
		"Content-Type: application/json"
	])
	
	var payload = {
		"plugin_version": "2.0.0",
		"session_metrics": {"platform": OS.get_name(), "device": OS.get_model_name()}
	}
	
	var http = HTTPRequest.new()
	http.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(http)
	
	var error = http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if error != OK:
		print("LSG-Core: Error al iniciar petición HTTP de sesión.")
		remove_child(http)
		http.queue_free()
		return
		
	var response = await http.request_completed
	remove_child(http)
	http.queue_free()
	
	var response_code = response[1]
	var body = response[3]
	
	if response_code == 200 or response_code == 201:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var data = json.data
			active_session_id = int(data.get("id_session", -1))
			print("LSG-Core: Sesión iniciada con éxito en backend. ID Sesión: ", active_session_id)
			session_started.emit(active_session_id)
		else:
			print("LSG-Core: Error al parsear JSON de inicio de sesión.")
	else:
		print("LSG-Core: Falló inicio de sesión de juego en API (Código ", response_code, ").")

# Petición para TERMINAR la sesión global
func end_session() -> void:
	if active_session_id == -1:
		return
		
	var url = BASE_URL + "/videogames/" + str(GAME_ID) + "/players/" + str(LsgAuth.player_id) + "/sessions/" + str(active_session_id) + "/end"
	var headers = PackedStringArray([
		"Authorization: Bearer " + LsgAuth.access_token,
		"Content-Type: application/json"
	])
	
	var http = HTTPRequest.new()
	http.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(http)
	
	var error = http.request(url, headers, HTTPClient.METHOD_PATCH, "{}")
	if error != OK:
		print("LSG-Core: Error al iniciar petición HTTP para cerrar sesión.")
		remove_child(http)
		http.queue_free()
		return
		
	var response = await http.request_completed
	remove_child(http)
	http.queue_free()
	
	var response_code = response[1]
	
	if response_code == 200:
		print("LSG-Core: Sesión finalizada exitosamente en el servidor.")
	else:
		print("LSG-Core: Falló finalización de sesión en el servidor (Código ", response_code, ").")
		
	active_session_id = -1
	session_ended.emit()

# Consultar balance de puntos multidimensional
func get_points_balance() -> void:
	if not LsgAuth.logged_in:
		return
		
	var url = BASE_URL + "/players/" + str(LsgAuth.player_id) + "/points/balance"
	var headers = PackedStringArray(["Authorization: Bearer " + LsgAuth.access_token])
	
	var http = HTTPRequest.new()
	http.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(http)
	
	var error = http.request(url, headers, HTTPClient.METHOD_GET, "")
	if error != OK:
		remove_child(http)
		http.queue_free()
		return
		
	var response = await http.request_completed
	remove_child(http)
	http.queue_free()
	
	var response_code = response[1]
	var body = response[3]
	
	if response_code == 200:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var balances = json.data as Array
			# Poblar dinámicamente el mapeo de códigos de dimensión en el logger
			for item in balances:
				if item is Dictionary:
					var dim_id = int(item.get("id_point_dimension", -1))
					var dim_code = item.get("dimension_code", "")
					if dim_id != -1 and not dim_code.is_empty():
						LsgLogger.dimension_code_map[dim_id] = dim_code
			balance_loaded.emit(balances)
		else:
			print("LSG-Core: Error parseando balances.")
	else:
		print("LSG-Core: Error al cargar balances (Código ", response_code, ").")

# Realizar canje de puntos por mecánicas modificables
func redeem_mechanic(mechanic_id: int, dimension_id: int, amount: int) -> void:
	if not LsgAuth.logged_in:
		redeem_completed.emit(false, {"error": "Usuario no autenticado"})
		return
		
	var url = BASE_URL + "/videogames/" + str(GAME_ID) + "/players/" + str(LsgAuth.player_id) + "/redeem"
	var headers = PackedStringArray([
		"Authorization: Bearer " + LsgAuth.access_token,
		"Content-Type: application/json"
	])
	
	var payload = {
		"modifiable_mechanic_videogame_id": mechanic_id,
		"point_dimension_id": dimension_id,
		"amount": amount,
		"metadata": {"session_id": active_session_id}
	}
	
	var http = HTTPRequest.new()
	http.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(http)
	
	var error = http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if error != OK:
		redeem_completed.emit(false, {"error": "Error de red al iniciar canje"})
		remove_child(http)
		http.queue_free()
		return
		
	var response = await http.request_completed
	remove_child(http)
	http.queue_free()
	
	var response_code = response[1]
	var body = response[3]
	
	var json = JSON.new()
	var response_data = {}
	if json.parse(body.get_string_from_utf8()) == OK:
		response_data = json.data
		
	if response_code == 200 or response_code == 201:
		print("LSG-Core: Canje exitoso.")
		redeem_completed.emit(true, response_data)
	else:
		print("LSG-Core: Error de canje en el servidor (Codigo ", response_code, "): ", response_data)
		redeem_completed.emit(false, response_data)

# Consultar puntos y atributos multidimensionales del jugador
func get_attributes_points() -> void:
	if not LsgAuth.logged_in:
		return
		
	var url = BASE_URL + "/players/" + str(LsgAuth.player_id) + "/attributes/points"
	var headers = PackedStringArray(["Authorization: Bearer " + LsgAuth.access_token])
	
	var http = HTTPRequest.new()
	http.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(http)
	
	var error = http.request(url, headers, HTTPClient.METHOD_GET, "")
	if error != OK:
		remove_child(http)
		http.queue_free()
		return
		
	var response = await http.request_completed
	remove_child(http)
	http.queue_free()
	
	var response_code = response[1]
	var body = response[3]
	
	if response_code == 200:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var attributes = json.data as Array
			attributes_loaded.emit(attributes)
		else:
			print("LSG-Core: Error parseando atributos/puntos.")
	else:
		print("LSG-Core: Error al cargar atributos/puntos (Código ", response_code, ").")

# Cargar puntos mediante API
func adjust_points(attribute_id: int, direction: String, amount: int, reason: String) -> void:
	if not LsgAuth.logged_in:
		adjust_completed.emit(false, {"error": "Usuario no autenticado"})
		return
		
	var url = BASE_URL + "/players/" + str(LsgAuth.player_id) + "/points/adjust"
	var headers = PackedStringArray([
		"Authorization: Bearer " + LsgAuth.access_token,
		"Content-Type: application/json"
	])
	
	var payload = {
		"attribute_id": attribute_id,
		"direction": direction,
		"amount": amount,
		"reason": reason,
		"videogame_id": GAME_ID
	}
	
	var http = HTTPRequest.new()
	http.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(http)
	
	var error = http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if error != OK:
		adjust_completed.emit(false, {"error": "Error de red al iniciar ajuste de puntos"})
		remove_child(http)
		http.queue_free()
		return
		
	var response = await http.request_completed
	remove_child(http)
	http.queue_free()
	
	var response_code = response[1]
	var body = response[3]
	
	var json = JSON.new()
	var response_data = {}
	if json.parse(body.get_string_from_utf8()) == OK:
		response_data = json.data
		
	if response_code == 200 or response_code == 201:
		print("LSG-Core: Ajuste de puntos exitoso.")
		var dim_id = int(response_data.get("id_point_dimension", 0))
		var dim_code = response_data.get("dimension_code", "")
		LsgLogger.log_points_earned(amount, reason, dim_id, dim_code)
		adjust_completed.emit(true, response_data)
	else:
		print("LSG-Core: Error de ajuste de puntos en el servidor (Codigo ", response_code, "): ", response_data)
		adjust_completed.emit(false, response_data)
