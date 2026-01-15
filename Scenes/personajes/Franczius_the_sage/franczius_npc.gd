extends CharacterBody2D

@export var battle_scene: PackedScene = preload("res://sdc.tscn")
@export var one_time_only: bool = true
@export var start_delay: float = 0.2

@onready var area: Area2D = get_node_or_null("area")

var _battle_started := false
var _can_trigger := false
var _battle_instance: Node = null


func _ready() -> void:
	if area == null:
		push_error("❌ NPC: No existe un nodo llamado 'area'")
		return

	area.monitoring = true
	area.monitorable = true

	if not area.body_entered.is_connected(_on_area_body_entered):
		area.body_entered.connect(_on_area_body_entered)

	_can_trigger = false
	await get_tree().create_timer(start_delay).timeout
	_can_trigger = true


func _on_area_body_entered(body: Node2D) -> void:
	if not _can_trigger:
		return

	# Ignorar mapa/paredes (lo que te está entrando ahora)
	if body is TileMap or body.get_class() == "TileMapLayer":
		return

	# Solo el player
	if not body.is_in_group("player"):
		return

	if _battle_started and one_time_only:
		return

	_battle_started = true
	area.monitoring = false
	area.monitorable = false
	start_battle()


func start_battle() -> void:
	if battle_scene == null:
		push_error("❌ NPC: battle_scene es null")
		return

	_battle_instance = battle_scene.instantiate()
	get_tree().root.add_child(_battle_instance)

	get_tree().paused = true
	_battle_instance.process_mode = Node.PROCESS_MODE_ALWAYS
