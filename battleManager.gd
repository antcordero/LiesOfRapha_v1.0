extends Node2D
class_name BattleManager

@onready var player1: Character = $CanvasLayer/Player1
@onready var player2: Character = $CanvasLayer/Player2
@onready var enemy: Character = $CanvasLayer/Enemy
@onready var battle_cam: Camera2D = $CanvasLayer/Camera2D


@onready var attack_btn: Button = $CanvasLayer/Control/VBoxContainer/AttackButton
@onready var turn_label: Label = $CanvasLayer/Control/VBoxContainer/TurnLabel
@onready var result_label: Label = $CanvasLayer/Control/ResultLabel
@onready var vbox: VBoxContainer = $CanvasLayer/Control/VBoxContainer

@export var world_camera_path: NodePath
var _world_cam: Camera2D


var players: Array[Character] = []
var turn_index := 0

const VBOX_Y_OFFSET := -150  # negativo = sube

# guardar la cámara anterior del mundo para restaurarla al salir
var _prev_cam: Camera2D




func _ready() -> void:
	if world_camera_path != NodePath():
		_world_cam = get_node_or_null(world_camera_path) as Camera2D

	# Guardar la cámara que estaba activa ANTES de entrar a la batalla
	_prev_cam = get_viewport().get_camera_2d()

	# Forzar cámara de la batalla
	if battle_cam:
		battle_cam.make_current()
		# Si el árbol está pausado al entrar en batalla, esto ayuda:
		# battle_cam.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	players = [player1, player2]

	_center_vbox(VBOX_Y_OFFSET)
	_setup_result_label()
	_connect_signals()

	start_battle()


func _center_vbox(y_offset: float = 0.0) -> void:
	# Centrar VBoxContainer en pantalla
	vbox.anchor_left = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_bottom = 0.5

	# Espera 1 frame para que Godot calcule tamaños
	await get_tree().process_frame

	# Centrado real + desplazamiento vertical
	vbox.offset_left = -vbox.size.x / 2
	vbox.offset_right = vbox.size.x / 2
	vbox.offset_top = -vbox.size.y / 2 + y_offset
	vbox.offset_bottom = vbox.size.y / 2 + y_offset


func _setup_result_label() -> void:
	result_label.visible = false
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Full rect
	result_label.anchor_left = 0.0
	result_label.anchor_right = 1.0
	result_label.anchor_top = 0.0
	result_label.anchor_bottom = 1.0

	result_label.offset_left = 0
	result_label.offset_right = 0
	result_label.offset_top = 0
	result_label.offset_bottom = 0

	# Tamaño + outline
	result_label.add_theme_font_size_override("font_size", 72)
	result_label.add_theme_constant_override("outline_size", 6)
	result_label.add_theme_color_override("font_outline_color", Color.BLACK)


func _connect_signals() -> void:
	for p in players:
		if not p.turn_ended.is_connected(_on_player_turn_ended):
			p.turn_ended.connect(_on_player_turn_ended)

	if not enemy.turn_ended.is_connected(_on_enemy_turn_ended):
		enemy.turn_ended.connect(_on_enemy_turn_ended)

	if not attack_btn.pressed.is_connected(_on_attack_pressed):
		attack_btn.pressed.connect(_on_attack_pressed)


func start_battle() -> void:
	print("¡Combate iniciado!")
	turn_index = 0
	next_turn()


func next_turn() -> void:
	if await check_win_lose():
		return

	# Turnos de jugadores
	if turn_index < players.size():
		var current_player := players[turn_index]

		if current_player.hp <= 0:
			turn_index += 1
			next_turn()
			return

		turn_label.text = "Turno: " + current_player.character_name
		attack_btn.visible = true
		attack_btn.disabled = false
		attack_btn.grab_focus()
		return

	# Turno enemigo
	turn_label.text = "Turno: " + enemy.character_name
	attack_btn.visible = false
	await get_tree().create_timer(0.6).timeout
	enemy_attack()


func _on_attack_pressed() -> void:
	attack_btn.disabled = true
	var current_player := players[turn_index]
	current_player.attack(enemy)


func _on_player_turn_ended() -> void:
	turn_index += 1
	await get_tree().create_timer(0.4).timeout
	next_turn()


func _on_enemy_turn_ended() -> void:
	turn_index = 0
	await get_tree().create_timer(0.8).timeout
	next_turn()


func enemy_attack() -> void:
	var alive_players := players.filter(func(p): return p.hp > 0)

	if alive_players.is_empty():
		enemy.turn_ended.emit()
		return

	# IA simple: ataca al más débil
	var target: Character = alive_players[0]
	for p in alive_players:
		if p.hp < target.hp:
			target = p

	enemy.attack(target)


func check_win_lose() -> bool:
	if enemy.hp <= 0:
		result_label.text = "¡Victoria!"
		result_label.visible = true
		attack_btn.visible = false
		end_battle()
		return true

	var alive := false
	for p in players:
		if p.hp > 0:
			alive = true
			break

	if not alive:
		result_label.text = "¡Derrota!"
		result_label.visible = true
		attack_btn.visible = false
		await get_tree().create_timer(1.2).timeout
		end_battle()
		return true

	return false


# Cerrar batalla bien: restaurar cámara anterior y borrar la batalla
func end_battle() -> void:
	if is_instance_valid(_world_cam):
		_world_cam.make_current()
	get_tree().paused = false
	GameManager.start_level(2)
	queue_free()
