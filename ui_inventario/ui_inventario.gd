extends Control

@onready var grid_container: GridContainer = $PanelContainer/GridContainer
var bag: Bag


func add_item_to_bag(item_to_add: Item) -> void:
	# 1) Siempre agregar primero a la Bag (fuente de verdad)
	var item_en_bag: Item = bag.agregar_item(item_to_add)

	# 2) Si es stackable, intenta encontrar un slot con el mismo name y refrescarlo
	if item_en_bag.stackable:
		for slot in grid_container.get_children():
			var item_in_slot: Item = slot.item_data
			if item_in_slot != null and item_in_slot.name == item_en_bag.name:
				# refresca UI desde la instancia real de la Bag
				slot.llenar_espacio(item_en_bag)
				return

	# 3) Si no había slot con ese item, meterlo en un slot vacío
	var slot_empty := buscar_slot_vacio()
	if slot_empty:
		slot_empty.llenar_espacio(item_en_bag)


func buscar_slot_vacio() -> Control:
	for slot in grid_container.get_children():
		if slot.item_data == null:
			return slot
	return null
