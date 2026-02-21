extends Control

@onready var grid_container: GridContainer = $PanelContainer/GridContainer

var bag: Bag

func refresh_from_bag() -> void:
	if bag == null:
		push_warning("UI inventario: bag es null")
		return
	if bag.db == null:
		push_warning("UI inventario: bag.db es null")
		return

	# 1) Vaciar todos los slots
	for slot in grid_container.get_children():
		if slot.has_method("vaciar_valores"):
			slot.vaciar_valores()

	# 2) Rellenar slots desde Bag
	var items: Array[Item] = bag.get_items_for_ui()
	var i := 0
	for item in items:
		if i >= grid_container.get_child_count():
			push_warning("UI inventario: no hay suficientes slots")
			return

		var slot = grid_container.get_child(i)
		slot.llenar_espacio(item)
		i += 1


func add_item_id_and_save(item_id: String) -> void:
	if bag == null:
		push_warning("UI inventario: bag es null")
		return

	bag.agregar_item(item_id)
	bag.save_to_disk()
	refresh_from_bag()
