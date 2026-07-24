extends Node

# Variables de estado del Logger
var session_start_time: String = ""
var events: Array = []
var total_points_earned: int = 0
var total_points_spent: int = 0
var redemptions_count: int = 0
var is_active: bool = false

# Mapeo dinámico y estático de id_point_dimension a dimension_code
var dimension_code_map: Dictionary = {
	1: "SOCIAL_BASE",
	2: "FISICO_BASE",
	3: "AFECTIVO_BASE",
	4: "MENTAL_BASE",
	6: "CONDICION_FISICA",
	11: "REG_EMOCIONAL"
}

# Inicializar y configurar el modo del proceso
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

# Iniciar la sesión de telemetría local
func start_session() -> void:
	session_start_time = Time.get_datetime_string_from_system()
	events.clear()
	total_points_earned = 0
	total_points_spent = 0
	redemptions_count = 0
	is_active = true
	
	log_event("session_start", {})
	print("LSG-Logger: Sesion de telemetria iniciada localmente a las ", session_start_time)

# Resolver el código de la dimensión
func get_dimension_code(dimension_id: int) -> String:
	if dimension_code_map.has(dimension_id):
		return dimension_code_map[dimension_id]
	return "DIMENSION_" + str(dimension_id)

# Registrar un evento genérico en el timeline
func log_event(type: String, data: Dictionary) -> void:
	if not is_active:
		return
		
	var event = {
		"type": type,
		"timestamp": Time.get_datetime_string_from_system(),
		"data": data
	}
	events.append(event)
	print("LSG-Logger: Evento registrado -> ", type)

# Helper para registrar compras (tienda o reanimación)
func log_redemption(mechanic_name: String, cost: int, dimension_id: int) -> void:
	if not is_active:
		return
		
	total_points_spent += cost
	redemptions_count += 1
	
	var dim_code = get_dimension_code(dimension_id)
	
	log_event("mechanic_redeemed", {
		"mechanic": mechanic_name,
		"cost": cost,
		"dimension_id": dimension_id,
		"dimension_code": dim_code
	})

# Helper para registrar la ganancia de puntos
func log_points_earned(amount: int, reason: String, dimension_id: int, dimension_code: String = "") -> void:
	if not is_active:
		return
		
	total_points_earned += amount
	
	var dim_code = dimension_code
	if dim_code.is_empty():
		dim_code = get_dimension_code(dimension_id)
		
	log_event("points_earned", {
		"amount": amount,
		"reason": reason,
		"dimension_id": dimension_id,
		"dimension_code": dim_code
	})

# Helper para registrar el fin de una partida (victoria o derrota)
func log_game_result(capsule_id: int, result: String, score: int) -> void:
	if not is_active:
		return
		
	log_event("game_completed", {
		"capsule_id": capsule_id,
		"result": result,
		"score_on_round": score
	})

# Compilar y enviar el reporte de telemetría completo al servidor de LSG
func submit_session_log() -> void:
	if not is_active:
		print("LSG-Logger: No hay sesion de telemetria activa para enviar.")
		return
		
	if not LsgAuth.logged_in or LsgAuth.access_token.is_empty():
		print("LSG-Logger: Imposible enviar telemetria sin usuario autenticado.")
		is_active = false
		return
		
	is_active = false # Desactivamos para evitar envíos duplicados
	
	var session_end_time = Time.get_datetime_string_from_system()
	log_event("session_end", {})
	
	# Calcular la duración aproximada en segundos
	var start_unix = Time.get_unix_time_from_datetime_string(session_start_time)
	var end_unix = Time.get_unix_time_from_datetime_string(session_end_time)
	var play_time_seconds = int(max(0, end_unix - start_unix))
	
	# Estructura final del payload para el servidor
	var payload = {
		"player_id": LsgAuth.player_id,
		"videogame_id": LsgCore.GAME_ID,
		"session_start": session_start_time,
		"session_end": session_end_time,
		"mod_version": "2.0.0",
		"experiment_tag": "LSG_C1_T1_CV",
		"total_points_earned": total_points_earned,
		"total_points_spent": total_points_spent,
		"redemptions_count": redemptions_count,
		"raw_log": {
			"events": events,
			"summary": {
				"total_play_time_seconds": play_time_seconds,
				"total_points_earned": total_points_earned,
				"total_points_spent": total_points_spent,
				"redemptions_count": redemptions_count
			}
		}
	}
	
	var url = LsgCore.BASE_URL + "/game-logs/sessions"
	var headers = PackedStringArray([
		"Authorization: Bearer " + LsgAuth.access_token,
		"Content-Type: application/json"
	])
	
	print("LSG-Logger: Enviando reporte de telemetria al servidor...")
	
	var http = HTTPRequest.new()
	http.process_mode = Node.PROCESS_MODE_ALWAYS
	http.use_threads = true
	if url.begins_with("https://"):
		http.set_tls_options(TLSOptions.client_unsafe())
	add_child(http)
	
	var error = http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if error != OK:
		print("LSG-Logger: Error al iniciar peticion HTTP de telemetria.")
		remove_child(http)
		http.queue_free()
		return
		
	var response = await http.request_completed
	remove_child(http)
	http.queue_free()
	
	var response_code = response[1]
	var body = response[3]
	
	if response_code == 200 or response_code == 201:
		print("LSG-Logger: Reporte de telemetria enviado con exito al servidor.")
	else:
		var json = JSON.new()
		var err_msg = ""
		if json.parse(body.get_string_from_utf8()) == OK:
			err_msg = str(json.data)
		else:
			err_msg = body.get_string_from_utf8()
		print("LSG-Logger: Fallo al enviar telemetria (Codigo ", response_code, "): ", err_msg)
