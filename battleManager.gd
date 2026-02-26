extends Node2D
class_name BattleManager

@onready var player1: Character = $CanvasLayer/Player1
@onready var player2: Character = $CanvasLayer/Player2
@onready var enemy: Character = $CanvasLayer/Enemy
@onready var battle_cam: Camera2D = $CanvasLayer/Camera2D

@onready var attack_btn: Button = $CanvasLayer/Control/VBoxContainer/AttackButton
@onready var heal_btn: Button = $CanvasLayer/Control/VBoxContainer/HealButton
@onready var turn_label: Label = $CanvasLayer/Control/VBoxContainer/TurnLabel
@onready var result_label: Label = $CanvasLayer/Control/ResultLabel
@onready var vbox: VBoxContainer = $CanvasLayer/Control/VBoxContainer

@export var world_camera_path: NodePath
@export var reward_coins: int = 10  # ✅ monedas que das al ganar

# ✅ identifica qué SDC es esta batalla (ponerlo en el inspector en cada escena)
@export_enum("sdc", "sdc2", "sdc3") var sdc_id: String = "sdc"

var _world_cam: Camera2D
var players: Array[Character] = []
var turn_index: int = 0

const VBOX_Y_OFFSET := -150

# guardar la cámara anterior del mundo para restaurarla al salir
var _prev_cam: Camera2D

# --- Inventario ---
const DB: ItemDatabase = preload("res://items/items_db.tres")
var bag: Bag


func _ready() -> void:
	if world_camera_path != NodePath():
		_world_cam = get_node_or_null(world_camera_path) as Camera2D

	_prev_cam = get_viewport().get_camera_2d()

	# Forzar cámara de la batalla
	if battle_cam:
		battle_cam.make_current()

	players = [player1, player2]

	# Cargar inventario
	_load_bag()

	_center_vbox(VBOX_Y_OFFSET)
	_setup_result_label()
	_connect_signals()

	start_battle()


func _load_bag() -> void:
	var loaded := Bag.load_from_disk()
	if loaded != null:
		bag = loaded
	else:
		bag = Bag.new()
	bag.db = DB


func _center_vbox(y_offset: float = 0.0) -> void:
	vbox.anchor_left = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_bottom = 0.5

	await get_tree().process_frame

	vbox.offset_left = -vbox.size.x / 2
	vbox.offset_right = vbox.size.x / 2
	vbox.offset_top = -vbox.size.y / 2 + y_offset
	vbox.offset_bottom = vbox.size.y / 2 + y_offset


func _setup_result_label() -> void:
	result_label.visible = false
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	result_label.anchor_left = 0.0
	result_label.anchor_right = 1.0
	result_label.anchor_top = 0.0
	result_label.anchor_bottom = 1.0

	result_label.offset_left = 0
	result_label.offset_right = 0
	result_label.offset_top = 0
	result_label.offset_bottom = 0

	result_label.add_theme_font_size_override("font_size", 72)
	result_label.add_theme_constant_override("outline_size", 6)
	result_label.add_theme_color_override("font_outline_color", Color.BLACK)


func _connect_signals() -> void:
	# players
	for p in players:
		if p == null:
			push_error("BattleManager: Un player es null (revisa rutas Player1/Player2)")
			continue
		if not p.turn_ended.is_connected(_on_player_turn_ended):
			p.turn_ended.connect(_on_player_turn_ended)

	# enemy
	if enemy == null:
		push_error("BattleManager: Enemy es null. Revisa que exista CanvasLayer/Enemy en esta escena.")
	else:
		if not enemy.turn_ended.is_connected(_on_enemy_turn_ended):
			enemy.turn_ended.connect(_on_enemy_turn_ended)

	# botones
	if attack_btn != null and not attack_btn.pressed.is_connected(_on_attack_pressed):
		attack_btn.pressed.connect(_on_attack_pressed)

	if heal_btn != null and not heal_btn.pressed.is_connected(_on_heal_pressed):
		heal_btn.pressed.connect(_on_heal_pressed)

func start_battle() -> void:
	print("¡Combate iniciado!", " (", sdc_id, ")")
	turn_index = 0
	next_turn()


func next_turn() -> void:
	if await check_win_lose():
		return

	# Turnos de jugadores
	if turn_index < players.size():
		var current_player: Character = players[turn_index]

		if current_player.hp <= 0:
			turn_index += 1
			next_turn()
			return

		turn_label.text = "Turno: " + current_player.character_name
		attack_btn.visible = true
		attack_btn.disabled = false

		# ✅ Curar solo si hay pociones
		if heal_btn:
			heal_btn.visible = true
			heal_btn.disabled = (bag == null or bag.contar_item("potion") <= 0)

		attack_btn.grab_focus()
		return

	# Turno enemigo
	turn_label.text = "Turno: " + enemy.character_name
	attack_btn.visible = false
	if heal_btn:
		heal_btn.visible = false

	await get_tree().create_timer(0.6).timeout
	enemy_attack()


func _on_attack_pressed() -> void:
	attack_btn.disabled = true
	if heal_btn:
		heal_btn.disabled = true

	var current_player: Character = players[turn_index]
	current_player.attack(enemy)


func _on_heal_pressed() -> void:
	if bag == null:
		return

	var current_player: Character = players[turn_index]
	if current_player.hp <= 0:
		return

	# gastar 1 poción
	var ok: bool = bag.consumir_item("potion", 1)
	if not ok:
		print("No tienes pociones")
		if heal_btn:
			heal_btn.disabled = true
		return

	# curación desde DB (Potion.tres tiene curation)
	var potion_def: Item = DB.get_item("potion")
	var heal_amount: int = 0
	if potion_def != null:
		heal_amount = int(potion_def.curation)

	current_player.set_hp(current_player.hp + heal_amount)

	bag.save_to_disk()

	# termina turno tras curar
	turn_index += 1
	await get_tree().create_timer(0.4).timeout
	next_turn()


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
	if enemy == null:
		push_error("BattleManager: enemy es null en check_win_lose(). Revisa la ruta CanvasLayer/Enemy.")
		return false

	if enemy.hp <= 0:
		result_label.text = "¡Victoria!"
		result_label.visible = true
		attack_btn.visible = false
		if heal_btn:
			heal_btn.visible = false
		end_battle_victory()
		return true

	var alive := false
	for p in players:
		if p != null and p.hp > 0:
			alive = true
			break

	if not alive:
		result_label.text = "¡Derrota!"
		result_label.visible = true
		attack_btn.visible = false
		if heal_btn:
			heal_btn.visible = false
		await get_tree().create_timer(1.2).timeout
		end_battle_defeat()
		return true

	return false
func _restore_world_and_close() -> void:
	if is_instance_valid(_world_cam):
		_world_cam.make_current()
	elif is_instance_valid(_prev_cam):
		_prev_cam.make_current()

	get_tree().paused = false
	queue_free()


func end_battle_victory() -> void:
	# 1. Guardar recompensas
	if bag != null and reward_coins > 0:
		bag.agregar_cantidad("coin", reward_coins)
		bag.save_to_disk()

	# 2. Volver a mostrar el mapa (pero no cerramos el manager aún)
	GameManager.return_to_level()

	# 3. Disparar el diálogo correspondiente
	match sdc_id:
		"sdc":
			GameManager.show_boss1_defeated_dialogue()
		"sdc2":
			GameManager.show_boss2_defeated_dialogue()
		"sdc3":
			GameManager.show_boss3_defeated_dialogue()
		_:
			# Por si acaso sdc_id está vacío o mal escrito
			GameManager.show_boss1_defeated_dialogue()
	
	# 4. Limpiar la escena de batalla y restaurar cámara
	# Solo UNA VEZ y al final de la función
	_restore_world_and_close()


func end_battle_defeat() -> void:
	GameManager.restart_current_level()
	_restore_world_and_close()
