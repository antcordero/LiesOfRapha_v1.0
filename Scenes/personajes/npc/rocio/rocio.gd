extends CharacterBody2D

# Configuración del Diálogo
@export var dialogue_resource: DialogueResource = preload("res://Dialogues/rocio.dialogue")
@export var dialogue_start: String = "start"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var player_in_range: bool = false
var dialogue_active: bool = false
var current_balloon: Node = null

func _ready() -> void:
	animated_sprite.play("idle")
	
	var area: Area2D = get_node_or_null("areaHablar")
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	
	# IMPORTANTE: No conectamos la señal global aquí para evitar conflictos entre NPCs
	# Lo manejaremos directamente cuando mostremos el diálogo.

func _process(_delta: float) -> void:
	# Abrir diálogo
	if player_in_range and not dialogue_active and Input.is_action_just_pressed("do_something"):
		mostrar_dialogo()
	
	# Cerrar diálogo manualmente
	elif dialogue_active and Input.is_action_just_pressed("cancel"):
		cerrar_dialogo_forzado()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_range = false
		# Opcional: Si el jugador se aleja, cerramos el diálogo automáticamente
		if dialogue_active:
			cerrar_dialogo_forzado()

func mostrar_dialogo() -> void:
	if dialogue_resource == null:
		print("Error: No hay recurso de diálogo")
		return
		
	dialogue_active = true
	current_balloon = DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_start)
	
	# Conectamos la señal de cierre SOLO para esta instancia y una sola vez (CONNECT_ONE_SHOT)
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_finished):
		DialogueManager.dialogue_ended.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)

func cerrar_dialogo_forzado() -> void:
	if current_balloon and is_instance_valid(current_balloon):
		current_balloon.queue_free()
		current_balloon = null
	
	# Forzamos el reset de la variable por si la señal no llega a tiempo al borrar el nodo
	dialogue_active = false
	
	# Desconectamos la señal si existía para que no se duplique luego
	if DialogueManager.dialogue_ended.is_connected(_on_dialogue_finished):
		DialogueManager.dialogue_ended.disconnect(_on_dialogue_finished)

func _on_dialogue_finished(_resource: DialogueResource) -> void:
	# Esperamos un frame para evitar que el mismo click que cierra el diálogo lo vuelva a abrir
	await get_tree().process_frame
	dialogue_active = false
	current_balloon = null
