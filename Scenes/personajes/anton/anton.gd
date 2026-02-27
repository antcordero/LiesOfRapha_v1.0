extends CharacterBody2D

# Configuración del Diálogo
@export var dialogue_resource: DialogueResource = preload("res://Dialogues/dialogo_sala2_anton.dialogue")
@export var dialogue_start: String = "start"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var player_in_range: bool = false
var dialogue_active: bool = false
var current_balloon: Node = null

# --- NUEVO: Variables de control ---
var puede_detectar: bool = false 
var dialogue_completed: bool = false # <-- Recuerda si ya hemos hablado con él

func _ready() -> void:
	if animated_sprite:
		# Pon aquí el nombre de la animación idle que prefieras que tenga
		animated_sprite.play("idle_down")
	
	# Escudo de 0.5 segundos al cargar el mapa
	await get_tree().create_timer(0.5).timeout
	puede_detectar = true


func _process(_delta: float) -> void:
	# Abrir diálogo (Añadimos la condición "not dialogue_completed")
	if player_in_range and not dialogue_active and not dialogue_completed and Input.is_action_just_pressed("do_something"):
		mostrar_dialogo()
	
	# Cerrar diálogo manualmente
	elif dialogue_active and Input.is_action_just_pressed("cancel"):
		cerrar_dialogo_forzado()


# =========================================================
# SEÑALES DEL EDITOR (Asegúrate de que están conectadas)
# =========================================================

func _on_speak_area_body_entered(body: Node2D) -> void:
	# Si el nivel acaba de cargar, ignoramos la colisión
	if not puede_detectar: return 
	
	# Comprobamos ambas (mayúscula y minúscula) por si acaso
	if body.is_in_group("Player") or body.is_in_group("player"):
		player_in_range = true

func _on_speak_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") or body.is_in_group("player"):
		player_in_range = false
		# Si el jugador se aleja, cerramos el diálogo automáticamente
		if dialogue_active:
			cerrar_dialogo_forzado()


# =========================================================
# LÓGICA DE DIÁLOGOS
# =========================================================

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
	
	dialogue_active = false
	
	if DialogueManager.dialogue_ended.is_connected(_on_dialogue_finished):
		DialogueManager.dialogue_ended.disconnect(_on_dialogue_finished)

func _on_dialogue_finished(_resource: DialogueResource) -> void:
	# Esperamos un frame para evitar que el mismo click que cierra el diálogo lo vuelva a abrir
	await get_tree().process_frame
	dialogue_active = false
	current_balloon = null
	
	# --- NUEVO: Marcamos el diálogo como completado ---
	dialogue_completed = true
