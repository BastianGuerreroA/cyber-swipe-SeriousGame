extends Node

# Señales globales para notificar cambios de estado
signal login_success(name: String)
signal login_failed(error_msg: String)
signal logging_out
signal logged_out

# Variables de estado de sesión
var access_token: String = ""
var logged_in: bool = false
var player_id: int = -1
var player_name: String = ""
var player_email: String = ""
var player_roles: Array = []

const BASE_URL = "https://lsg.diinf.usach.cl/lsg-auth"

# Función para realizar login
func login(email: String, password: String) -> void:
	var url = BASE_URL + "/login"
	var headers = PackedStringArray(["Content-Type: application/x-www-form-urlencoded"])
	
	# Construimos los datos del formulario urlencoded
	var request_data = "username=" + email.uri_encode() + "&password=" + password.uri_encode()
	
	# Instanciamos el nodo HTTP de forma dinámica
	var http = HTTPRequest.new()
	add_child(http)
	
	var error = http.request(url, headers, HTTPClient.METHOD_POST, request_data)
	if error != OK:
		login_failed.emit("Error al iniciar la petición de red.")
		remove_child(http)
		http.queue_free()
		return
		
	var response = await http.request_completed
	remove_child(http)
	http.queue_free()
	
	var result = response[0]
	var response_code = response[1]
	var body = response[3]
	
	if result != HTTPRequest.RESULT_SUCCESS:
		login_failed.emit("Error de conexión al servidor.")
		return
		
	if response_code == 200:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var data = json.data
			if data.has("access_token"):
				access_token = data["access_token"]
				logged_in = true
				print("LSG-Auth: Token recibido correctamente.")
				# Ahora consultamos quiénes somos para obtener el perfil del jugador
				await fetch_whoami()
			else:
				login_failed.emit("Respuesta del servidor inválida (sin token).")
		else:
			login_failed.emit("Error al decodificar la respuesta JSON del servidor.")
	elif response_code == 401:
		login_failed.emit("Correo o contraseña incorrectos.")
	elif response_code == 422:
		login_failed.emit("Formato de petición inválido (422).")
	else:
		login_failed.emit("Error del servidor (Código " + str(response_code) + ").")

# Obtener información del perfil del jugador
func fetch_whoami() -> void:
	if not logged_in or access_token.is_empty():
		login_failed.emit("No hay sesión activa.")
		return
		
	var url = BASE_URL + "/whoami"
	var headers = PackedStringArray(["Authorization: Bearer " + access_token])
	
	var http = HTTPRequest.new()
	add_child(http)
	
	var error = http.request(url, headers, HTTPClient.METHOD_GET, "")
	if error != OK:
		login_failed.emit("Error al consultar el perfil.")
		remove_child(http)
		http.queue_free()
		return
		
	var response = await http.request_completed
	remove_child(http)
	http.queue_free()
	
	var result = response[0]
	var response_code = response[1]
	var body = response[3]
	
	if result != HTTPRequest.RESULT_SUCCESS:
		login_failed.emit("Error de conexión al consultar el perfil.")
		return
		
	if response_code == 200:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var data = json.data
			player_id = int(data.get("id_players", -1))
			player_name = data.get("name", "Usuario LSG")
			player_email = data.get("email", "")
			player_roles = data.get("roles", [])
			
			# Sincronizamos con el administrador de cápsulas nativo
			CapsulaManager.nombre_usuario = player_name
			CapsulaManager.guardar_progreso()
			
			print("LSG-Auth: Sesión iniciada para ", player_name, " (ID: ", player_id, ")")
			login_success.emit(player_name)
		else:
			login_failed.emit("Error al parsear el JSON del perfil.")
	else:
		# Si falla la validación del perfil, invalidamos el token
		logout()
		login_failed.emit("Error al validar el token del perfil (Código " + str(response_code) + ").")

# Cerrar sesión del usuario localmente
func logout() -> void:
	# Emitimos la señal antes de limpiar el token para que ApiCore pueda cerrar la sesión activa
	logging_out.emit()
	
	access_token = ""
	logged_in = false
	player_id = -1
	player_name = ""
	player_email = ""
	player_roles = []
	
	# Restauramos al usuario por defecto
	CapsulaManager.nombre_usuario = "Usuario"
	CapsulaManager.guardar_progreso()
	
	print("LSG-Auth: Sesión cerrada localmente.")
	logged_out.emit()
