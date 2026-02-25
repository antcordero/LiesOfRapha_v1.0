class_name Player extends CharacterBody2D

const SPEED = 80
var current_dir = "none"

# === INVENTARIO ===
@export var bag: Bag
const DB: ItemDatabase = preload("res://items/items_db.tres")
var inventory_control  # Se asigna en _ready()

func _ready() -> void:
	# 1. Inicializar Bag (carga guardado o crea nueva)
	var loaded := Bag.load_from_disk()
	if loaded != null:
		bag = loaded
	elif bag == null:
		bag = Bag.new()

	bag.db = DB

	# 2. Buscar UI del inventario por grupo (¡nunca falla!)
	inventory_control = get_tree().get_first_node_in_group("inventory_ui")
	if inventory_control == null:
		print("¡ERROR! Añade grupo 'inventory_ui' al nodo Control del inventario")
		return

	# 3. Conectar inventario
	inventory_control.bag = bag
	inventory_control.refresh_from_bag()

	print("Inventario listo! Pulsa 1=coin, 2=potion, 3=key")

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
		player_animation(0) # idle
	
	move_and_slide()

func player_animation(movement):
	var direction = current_dir
	var animation = $AnimatedSprite2D
	
	if direction == "right":
		animation.flip_h = false
		if movement == 1:
			animation.play("walk_side")
		elif movement == 0:
			animation.play("idle_side")
	
	if direction == "left":
		animation.flip_h = true
		if movement == 1:
			animation.play("walk_side")
		elif movement == 0:
			animation.play("idle_side")
	
	if direction == "down":
		animation.flip_h = true
		if movement == 1:
			animation.play("walk_down")
		elif movement == 0:
			animation.play("idle_down")
	
	if direction == "up":
		animation.flip_h = true
		if movement == 1:
			animation.play("walk_up")
		elif movement == 0:
			animation.play("idle_up")
