extends Node2D

@export var bag: Bag
@onready var control: Control = $CanvasLayer/Control

const coin: Item = preload("res://items/Coin.tres")

func _ready() -> void:
	# 1) Si no asignaste bag en el inspector, crear una nueva
	if bag == null:
		bag = Bag.new()

	# 2) Pasar la bag al UI
	control.bag = bag

	# 3) Agregar la moneda
	control.add_item_to_bag(coin)

	# 4) Debug: ver contenido real de la bag
	print("Bag objects:")
	for k in bag.objects.keys():
		var it: Item = bag.objects[k]
		print(k, " -> ", it.name, " x", it.sum)
