extends CharacterBody2D

const SPEED = 80
var current_dir = "none"

# === INVENTARIO ===
@export var bag: Bag
const DB: ItemDatabase = preload("res://items/items_db.tres")
var inventory_control

func _ready() -> void:
	# 1. Inicializar Bag
	bag = GameManager.player_bag
	if bag == null:
		print("❌ GameManager.player_bag es null")
		return

	# Asegura DB (por si acaso)
	bag.db = DB

	# 2. Buscar UI del inventario por grupo
	inventory_control = get_tree().get_first_node_in_group("inventory_ui")
	if inventory_control == null:
		print("¡ERROR! Añade grupo 'inventory_ui' al nodo Control del inventario")
		return

	# 3. Conectar inventario
	inventory_control.bag = bag
	inventory_control.refresh_from_bag()

	# ✅ 4. Conectar Shop al inventario real (monedas = item "coin")
	Shops.setup(bag)

	# ✅ refrescar inventario cuando compras
	if not Shops.shop_changed.is_connected(_on_shop_changed):
		Shops.shop_changed.connect(_on_shop_changed)

	# ✅ debug mensajes shop
	if not Shops.shop_message.is_connected(_on_shop_msg):
		Shops.shop_message.connect(_on_shop_msg)

	print("Inventario listo! Pulsa 1=coin, 2=potion, 3=key")

func _on_shop_changed() -> void:
	if inventory_control:
		inventory_control.refresh_from_bag()

func _on_shop_msg(t: String) -> void:
	print("SHOP_MSG:", t)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_add_and_save("coin")
			KEY_2:
				_add_and_save("potion")
			KEY_3:
				_add_and_save("key")

func _add_and_save(item_id: String) -> void:
	if inventory_control == null:
		print("Inventario no encontrado")
		return

	bag.agregar_item(item_id)
	bag.save_to_disk()
	inventory_control.refresh_from_bag()
	print("Añadido: ", item_id)

# === MOVIMIENTO DEL PERSONAJE ===
func _physics_process(delta):
	player_movement(delta)

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		print("El input del jugador funciona. Pausa: ", get_tree().paused)

func player_movement(delta):
	if Input.is_action_pressed("right"):
		current_dir = "right"
		player_animation(1)
		velocity.x = SPEED
		velocity.y = 0
	elif Input.is_action_pressed("left"):
		current_dir = "left"
		player_animation(1)
		velocity.x = -SPEED
		velocity.y = 0
	elif Input.is_action_pressed("down"):
		current_dir = "down"
		player_animation(1)
		velocity.y = SPEED
		velocity.x = 0
	elif Input.is_action_pressed("up"):
		current_dir = "up"
		player_animation(1)
		velocity.y = -SPEED
		velocity.x = 0
	else:
		velocity.x = 0
		velocity.y = 0
		player_animation(0)

	move_and_slide()

func player_animation(movement):
	var direction = current_dir
	var animation = $AnimatedSprite2D

	if direction == "right":
		animation.flip_h = false
		if movement == 1:
			animation.play("walk_side")
		else:
			animation.play("idle_side")

	if direction == "left":
		animation.flip_h = true
		if movement == 1:
			animation.play("walk_side")
		else:
			animation.play("idle_side")

	if direction == "down":
		animation.flip_h = true
		if movement == 1:
			animation.play("walk_down")
		else:
			animation.play("idle_down")

	if direction == "up":
		animation.flip_h = true
		if movement == 1:
			animation.play("walk_up")
		else:
			animation.play("idle_up")
