extends Control

var puntaje_actual: int = 0

# Esta variable guarda la referencia directa al Label que tiene el número "0"
@onready var label_numero = $PanelContainer/MarginContainer/HBoxContainer/Numero

# Función que llamaremos cada vez que el jugador acierte
func sumar_punto(cantidad: int = 1) -> void:
	puntaje_actual += cantidad
	label_numero.text = str(puntaje_actual) # Convertimos el número a texto para mostrarlo
