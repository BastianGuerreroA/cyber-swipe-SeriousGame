extends Node

##
## CryptoManager
##
## Descifra archivos .lsg generados por encrypt_capsule.py
## Algoritmo:
##
## AES-256-CBC
## PKCS7
##
## Formato del archivo:
##
## [16 bytes IV]
## [CipherText]
##

var AES_KEY: PackedByteArray = PackedByteArray([
	216,159,99,164,211,178,86,149,
	70,65,192,153,222,234,174,136,
	232,107,140,46,156,203,66,216,
	65,240,188,83,95,84,161,42
])


############################################################
# API PÚBLICA
############################################################

func load_capsule(path:String) -> Dictionary:
	return _load_json(path)


func load_index(path:String) -> Dictionary:
	return _load_json(path)



############################################################
# CARGAR ARCHIVO
############################################################

func _load_json(path:String) -> Dictionary:

	if !FileAccess.file_exists(path):
		push_error("CryptoManager -> No existe: " + path)
		return {}

	var encrypted := FileAccess.get_file_as_bytes(path)

	if encrypted.is_empty():
		push_error("CryptoManager -> Archivo vacío.")
		return {}

	return _decrypt(encrypted)



############################################################
# DESCIFRADO AES
############################################################

func _decrypt(file_bytes:PackedByteArray) -> Dictionary:

	if file_bytes.size() <= 16:
		push_error("CryptoManager -> Archivo inválido.")
		return {}

	#--------------------------------------
	# IV
	#--------------------------------------

	var iv:PackedByteArray = file_bytes.slice(0,16)

	#--------------------------------------
	# CipherText
	#--------------------------------------

	var ciphertext:PackedByteArray = file_bytes.slice(16)

	#--------------------------------------
	# AES
	#--------------------------------------

	var aes := AESContext.new()

	var err := aes.start(
		AESContext.MODE_CBC_DECRYPT,
		AES_KEY,
		iv
	)

	if err != OK:
		push_error("CryptoManager -> Error AES start().")
		return {}

	var decrypted := aes.update(ciphertext)

	aes.finish()

	#--------------------------------------
	# PKCS7
	#--------------------------------------

	decrypted = _remove_padding(decrypted)

	#--------------------------------------
	# UTF8
	#--------------------------------------

	var json_text := decrypted.get_string_from_utf8()

	#--------------------------------------
	# JSON
	#--------------------------------------

	var json := JSON.new()

	err = json.parse(json_text)

	if err != OK:

		push_error(
			"CryptoManager -> JSON inválido.\n" +
			json.get_error_message() +
			"\nLínea: " +
			str(json.get_error_line())
		)

		return {}

	return json.data



############################################################
# REMOVER PKCS7
############################################################

func _remove_padding(data:PackedByteArray)->PackedByteArray:

	if data.is_empty():
		return data

	var padding := data[data.size()-1]

	if padding <= 0:
		return data

	if padding > 16:
		return data

	return data.slice(
		0,
		data.size()-padding
	)
