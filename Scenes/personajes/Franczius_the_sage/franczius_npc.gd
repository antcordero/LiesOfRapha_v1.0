extends CharacterBody2D

@export var battle_scene: PackedScene = preload("res://Combat/sdc.tscn")
@export var one_time_only: bool = true
@export var start_delay: float = 0.2

# Diálogo del boss
@export var dialogue_resource: DialogueResource = preload("res://Dialogues/franczius_the_sage.dialogue")
@export var dialogue_start: String = "start"

@onready var battle_area: Area2D = get_node_or_null("area")        # área de combate
@onready var speak_area: Area2D = get_node_or_null("speakArea")    # área grande de diálogo

var _battle_started: bool = false
var _can_trigger: bool = false
var _battle_instance: Node = null

var dialogue_active: bool = false
var dialogue_done: bool = false
var current_balloon: Node = null

func _ready() -> void:
	# --- COMBATE (area) ---
	if battle_area == null:
		push_error("❌ NPC: No existe un nodo llamado 'area' (combate)")
	else:
		battle_area.monitoring = true
		battle_area.monitorable = true
		if not battle_area.body_entered.is_connected(_on_battle_area_body_entered):
			battle_area.body_entered.connect(_on_battle_area_body_entered)

	_can_trigger = false
	await get_tree().create_timer(start_delay).timeout
	_can_trigger = true

	# --- DIÁLOGO (speakArea) ---
	if speak_area == null:
		push_error("❌ NPC: No existe un nodo llamado 'speakArea' (diálogo)")
	else:
		if not speak_area.body_entered.is_connected(_on_speak_area_body_entered):
			speak_area.body_entered.connect(_on_speak_area_body_entered)
		if not speak_area.body_exited.is_connected(_on_speak_area_body_exited):
			speak_area.body_exited.connect(_on_speak_area_body_exited)

	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_finished):
		DialogueManager.dialogue_ended.connect(_on_dialogue_finished)

# -------- COMBATE --------
func _on_battle_area_body_entered(body: Node2D) -> void:
	if not _can_trigger:
		return
	if body is TileMap or body.get_class() == "TileMapLayer":
		return
	if not body.is_in_group("player"):
		return
	if _battle_started and one_time_only:
		return

	_battle_started = true
	battle_area.monitoring = false
	battle_area.monitorable = false
	start_battle()

func start_battle() -> void:
	if battle_scene == null:
		push_error("❌ NPC: battle_scene es null")
		return

	_battle_instance = battle_scene.instantiate()
	get_tree().root.add_child(_battle_instance)

	get_tree().paused = true
	_battle_instance.process_mode = Node.PROCESS_MODE_ALWAYS

# -------- DIÁLOGO AUTOMÁTICO (speakArea) --------
func _on_speak_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if dialogue_active or dialogue_done:
		return
	if _battle_started:
		return   # por si entra en el área después de empezar la batalla

	mostrar_dialogo()

func _on_speak_area_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if dialogue_active:
		cerrar_dialogo_forzado()

func mostrar_dialogo() -> void:
	if dialogue_resource == null:
		push_error("❌ NPC: dialogue_resource es null en boss")
		return
	if dialogue_active:
		return

	dialogue_active = true
	current_balloon = DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_start)

func cerrar_dialogo_forzado() -> void:
	if current_balloon and is_instance_valid(current_balloon):
		current_balloon.queue_free()
		current_balloon = null
	dialogue_active = false

func _on_dialogue_finished(_resource: DialogueResource) -> void:
	if current_balloon and not is_instance_valid(current_balloon):
		current_balloon = null
		dialogue_active = false
		dialogue_done = true
