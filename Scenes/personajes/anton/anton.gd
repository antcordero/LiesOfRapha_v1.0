extends CharacterBody2D

@export var speed: float = 200.0
@export var max_history_size: int = 7

# Sistema de rastro
var position_history: Array[Vector2] = []

# Configuración del diálogo
@export var dialogue_resource: DialogueResource = preload("res://Dialogues/dialogo_sala2_anton.dialogue")
@export var dialogue_start: String = "start"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var player: Node2D = null
var is_following: bool = false
var last_dir: Vector2 = Vector2.DOWN

var player_in_range: bool = false
var dialogue_active: bool = false
var dialogue_done: bool = false

# 🔥 Animación independiente del movimiento/velocity
var current_anim: StringName = &""

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

	# Arranca idle fijo (no depende de velocity)
	_set_anim_idle(last_dir)

	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_finished):
		DialogueManager.dialogue_ended.connect(_on_dialogue_finished)

func _physics_process(_delta: float) -> void:
	# 1) Si no sigue o el jugador no existe: se para, pero la animación NO se toca
	if not is_following or player == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# 2) Actualizamos rastro
	actualizar_rastro()

	# 3) Movimiento hacia la posición vieja del jugador
	var target_pos: Vector2 = position_history[0]
	var to_target: Vector2 = target_pos - global_position

	if to_target.length() > 8.0:
		var dir: Vector2 = to_target.normalized()
		velocity = dir * speed

		# ✅ Solo si cambia la dirección, cambiamos animación (independiente del movimiento)
		if _dir_changed_enough(dir):
			last_dir = dir
			_set_anim_walk(last_dir)
	else:
		velocity = Vector2.ZERO
		# ✅ NO cambiamos a idle aquí (por eso es independiente y no parpadea)

	move_and_slide()

func _process(_delta: float) -> void:
	# Diálogos
	if not dialogue_done:
		if player_in_range and not dialogue_active and Input.is_action_just_pressed("do_something"):
			mostrar_dialogo()

# ---------- RASTRO ----------

func actualizar_rastro() -> void:
	if position_history.is_empty() or player.global_position.distance_to(position_history.back()) > 5.0:
		position_history.append(player.global_position)

	if position_history.size() > max_history_size:
		position_history.remove_at(0)

# ---------- ANIMACIÓN (INDEPENDIENTE) ----------

func _dir_changed_enough(new_dir: Vector2) -> bool:
	# Evita micro-cambios que te reinicien animaciones
	# Si la dirección cambia poco, no actualizamos animación.
	return new_dir.dot(last_dir) < 0.92  # cuanto más cerca de 1, más "estricto"

func _play_anim(anim_name: StringName) -> void:
	# ✅ Nunca reinicia la animación si ya está puesta
	if animated_sprite.animation == String(anim_name) and animated_sprite.is_playing():
		return
	current_anim = anim_name
	animated_sprite.play(String(anim_name))

func _set_anim_walk(dir: Vector2) -> void:
	var anim: StringName

	if abs(dir.x) > abs(dir.y):
		anim = &"walk_side"
		animated_sprite.flip_h = (dir.x > 0)
	elif dir.y > 0:
		anim = &"walk_down"
		animated_sprite.flip_h = false
	else:
		anim = &"walk_up"
		animated_sprite.flip_h = false

	_play_anim(anim)

func _set_anim_idle(dir: Vector2) -> void:
	var anim: StringName

	if abs(dir.x) > abs(dir.y):
		anim = &"idle_side"
		animated_sprite.flip_h = (dir.x > 0)
	elif dir.y > 0:
		anim = &"idle_down"
		animated_sprite.flip_h = false
	else:
		anim = &"idle_up"
		animated_sprite.flip_h = false

	_play_anim(anim)

# ---------- INTERACCIÓN ----------

func _on_speak_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true

func _on_speak_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false

func mostrar_dialogo() -> void:
	dialogue_active = true
	DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_start)

func _on_dialogue_finished(_resource: DialogueResource) -> void:
	if _resource == dialogue_resource:
		dialogue_done = true
		dialogue_active = false
		is_following = true

		# Inicializa el rastro para que no pegue tirón al empezar a seguir
		position_history.clear()
		for i in range(max_history_size):
			position_history.append(global_position)

		# Al empezar a seguir, ponemos walk con la dir actual (independiente)
		_set_anim_walk(last_dir)
