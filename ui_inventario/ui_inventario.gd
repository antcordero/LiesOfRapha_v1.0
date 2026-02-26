extends Control

@onready var grid_container: GridContainer = $PanelContainer/GridContainer
@onready var coins_label: Label = $CoinsLabel   # ✅ RENOMBRA tu label de monedas a CoinsLabel

var bag: Bag

func _ready() -> void:
	# 1. Registro automático en el grupo para que el jugador nos vea
	add_to_group("inventory_ui")

	# 2. Si el GameManager ya tiene el inventario listo, lo usamos
	if GameManager.player_bag:
		bag = GameManager.player_bag
		refresh_from_bag()

func refresh_from_bag() -> void:
	if bag == null:
		return
	if bag.db == null:
		push_warning("UI inventario: bag.db es null. Asegúrate de que it_db.tres esté asignado en GameManager.")
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
			push_warning("UI inventario: no hay suficientes slots visuales para tantos items.")
			break

		var slot = grid_container.get_child(i)
		slot.llenar_espacio(item)
		i += 1
