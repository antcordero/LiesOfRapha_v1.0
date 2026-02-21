extends CharacterBody2D

# Configuración del Diálogo
@export var dialogue_resource: DialogueResource = preload("res://Dialogues/makarienne.dialogue")
@export var dialogue_start: String = "start"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var player_in_range: bool = false
var dialogue_active: bool = false
var current_balloon: Node = null

func _ready() -> void:
	print("NPC Makarienne listo: ", name)
	animated_sprite.play("idle_makarienne")
	
	# OJO: el nodo se llama speakArea, no areaHablar
	var area: Area2D = get_node_or_null("speakArea")
	print("speakArea encontrado: ", area)
	if area:
		area.body_entered.connect(_on_speak_area_body_entered)
		area.body_exited.connect(_on_speak_area_body_exited)

	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_finished):
		DialogueManager.dialogue_ended.connect(_on_dialogue_finished)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("do_something"):
		print("Tecla de hablar pulsada (Makarienne)")

	if player_in_range and not dialogue_active and Input.is_action_just_pressed("do_something"):
		print("Intentando mostrar diálogo de Makarienne")
		mostrar_dialogo()
	elif dialogue_active and Input.is_action_just_pressed("cancel"):
		print("Cerrando diálogo de Makarienne con cancel")
		cerrar_dialogo_forzado()

func _on_speak_area_body_entered(body: Node2D) -> void:
	print("speakArea body_entered: ", body.name)
	if body.is_in_group("player"):
		print("Jugador en rango para hablar con Makarienne")
		player_in_range = true

func _on_speak_area_body_exited(body: Node2D) -> void:
	print("speakArea body_exited: ", body.name)
	if body.is_in_group("player"):
		print("Jugador sale de rango de Makarienne")
		player_in_range = false
		if dialogue_active:
			cerrar_dialogo_forzado()

func mostrar_dialogo() -> void:
	if dialogue_resource == null:
		print("Error: No hay recurso de diálogo en ", name)
		return

	if dialogue_active:
		print("Ya hay un diálogo activo en Makarienne")
		return
		
	print("Mostrando diálogo de Makarienne:", dialogue_resource.resource_path)
	dialogue_active = true
	current_balloon = DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_start)
	print("Balloon creado para Makarienne: ", current_balloon)

func cerrar_dialogo_forzado() -> void:
	print("cerrar_dialogo_forzado Makarienne")
	if current_balloon and is_instance_valid(current_balloon):
		current_balloon.queue_free()
		current_balloon = null
	dialogue_active = false

func _on_dialogue_finished(_resource: DialogueResource) -> void:
	if current_balloon and not is_instance_valid(current_balloon):
		print("Se ha cerrado el globo de Makarienne desde DialogueManager")
		current_balloon = null
		dialogue_active = false
