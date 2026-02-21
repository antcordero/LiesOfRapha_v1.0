extends CharacterBody2D

@export var speed: float = 195.0
const STOP_DISTANCE: float = 30.0

# Configuración del diálogo
@export var dialogue_resource: DialogueResource = preload("res://Dialogues/dialogo_sala2_anton.dialogue")
@export var dialogue_start: String = "start"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var player: Node2D = null
var player_chase: bool = false
var last_dir: Vector2 = Vector2.DOWN

var player_in_range: bool = false
var dialogue_active: bool = false
var current_balloon: Node = null
var dialogue_done: bool = false   # solo una vez

func _ready() -> void:
	print("NPC listo: ", name)
	animated_sprite.play("idle_down")

	# Conectar una sola vez a la señal global, sin desconectarla luego
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_finished):
		DialogueManager.dialogue_ended.connect(_on_dialogue_finished)

func _physics_process(delta: float) -> void:
	if player_chase and player != null:
		var to_player: Vector2 = player.global_position - global_position
 
		if to_player.length() > STOP_DISTANCE:
			var dir: Vector2 = to_player.normalized()
			velocity = dir * speed
			last_dir = dir

			if abs(dir.x) > abs(dir.y):
				animated_sprite.play("walk_side")
				animated_sprite.flip_h = dir.x < 0
			elif dir.y > 0:
				animated_sprite.play("walk_down")
			else:
				animated_sprite.play("walk_up")
		else:
			velocity = Vector2.ZERO
			_play_idle_animation()
	else:
		velocity = Vector2.ZERO
		_play_idle_animation()

	move_and_slide()

func _process(_delta: float) -> void:
	if dialogue_done:
		return
	
	if player_in_range and not dialogue_active and Input.is_action_just_pressed("do_something"):
		print("Intentando mostrar diálogo (Anton)")
		mostrar_dialogo()
	elif dialogue_active and Input.is_action_just_pressed("cancel"):
		cerrar_dialogo_forzado()

func _play_idle_animation() -> void:
	if abs(last_dir.x) > abs(last_dir.y):
		animated_sprite.play("idle_side")
		animated_sprite.flip_h = last_dir.x < 0
	elif last_dir.y > 0:
		animated_sprite.play("idle_down")
	else:
		animated_sprite.play("idle_up")

# Persecución (detection_area)
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		player_chase = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		player_chase = false

# ---- ÁREA DE DIÁLOGO (speakArea) ----
func _on_speak_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true

func _on_speak_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		if dialogue_active:
			cerrar_dialogo_forzado()

# ---- DIÁLOGO ----
func mostrar_dialogo() -> void:
	if dialogue_done:
		return

	if dialogue_resource == null:
		print("Error: No hay recurso de diálogo en ", name)
		return
		
	dialogue_active = true
	current_balloon = DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_start)

func cerrar_dialogo_forzado() -> void:
	if current_balloon and is_instance_valid(current_balloon):
		current_balloon.queue_free()
		current_balloon = null
	dialogue_active = false

func _on_dialogue_finished(_resource: DialogueResource) -> void:
	# Esta señal se dispara para cualquier diálogo.
	# Solo reseteamos si el globo que acaba es el nuestro.
	if current_balloon and not is_instance_valid(current_balloon):
		current_balloon = null
		dialogue_active = false
		dialogue_done = true
		print("Diálogo Anton terminado; marcado como hecho")
