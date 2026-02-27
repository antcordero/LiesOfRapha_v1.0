extends CharacterBody2D

# Configuración del Diálogo
@export var dialogue_resource: DialogueResource = preload("res://Dialogues/beatrix.dialogue")
@export var dialogue_start: String = "start"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var player_in_range: bool = false
var dialogue_active: bool = false
var current_balloon: Node = null

# --- NUEVO: Escudo anti-cargas rápidas ---
var puede_detectar: bool = false 

func _ready() -> void:
	if animated_sprite:
		animated_sprite.play("front_idle_beatrix")
	
	# Escudo de 0.5 segundos al cargar el mapa
	await get_tree().create_timer(0.5).timeout
	puede_detectar = true


func _process(_delta: float) -> void:
	# Abrir diálogo
	if player_in_range and not dialogue_active and Input.is_action_just_pressed("do_something"):
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
	
	if body.is_in_group("player"):
		print("Jugador en rango de Beatrix")
		player_in_range = true

func _on_speak_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
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
	
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_finished):
		DialogueManager.dialogue_ended.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)

func cerrar_dialogo_forzado() -> void:
	if current_balloon and is_instance_valid(current_balloon):
		current_balloon.queue_free()
		current_balloon = null
	
	dialogue_active = false
	
	if DialogueManager.dialogue_ended.is_connected(_on_dialogue_finished):
		DialogueManager.dialogue_ended.disconnect(_on_dialogue_finished)

# ⭐ AL TERMINAR DIALOGO → GAME MANAGER CARGA QUIZ
func _on_dialogue_finished(_resource: DialogueResource) -> void:
	if not dialogue_active: return # Evita ejecuciones extra
	dialogue_active = false
	print("Diálogo Beatrix → Iniciando QUIZ")
	
	# Llamar solo UNA vez al GameManager pasando el nivel padre
	GameManager.iniciar_quiz_beatrix(get_parent())
