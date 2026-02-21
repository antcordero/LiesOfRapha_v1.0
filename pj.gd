extends Node2D

@export var bag: Bag
@onready var control := $CanvasLayer/Control

const DB: ItemDatabase = preload("res://items/items_db.tres")

func _ready() -> void:
	# 1) Cargar bag guardada si existe
	var loaded := Bag.load_from_disk()
	if loaded != null:
		bag = loaded
	elif bag == null:
		# si no hay guardado y no has asignado ninguna en el inspector
		bag = Bag.new()

	# 2) Asegurar DB y enganchar a UI
	bag.db = DB
	control.bag = bag

	# 3) Pintar inventario al iniciar
	control.refresh_from_bag()

	print("DB ids:", DB.get_all_ids())
	print("Pulsa 1 (coin), 2 (potion), 3 (key)")

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
	bag.agregar_item(item_id)
	bag.save_to_disk()
	control.refresh_from_bag()
