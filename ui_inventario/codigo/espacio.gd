extends Panel
# Slot individual del inventario

@onready var icono_item: TextureRect = $TextureRect
@onready var label: Label = $Label

var item_data: Item = null


func llenar_espacio(item: Item) -> void:
	item_data = item
	icono_item.texture = item.icon
	label.text = str(item.sum) if item.sum > 1 else ""


func vaciar_valores() -> void:
	item_data = null
	icono_item.texture = null
	label.text = ""


func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_data == null:
		return null

	var drag_preview := TextureRect.new()
	drag_preview.texture = icono_item.texture
	drag_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	drag_preview.custom_minimum_size = Vector2(32, 32)
	set_drag_preview(drag_preview)

	return self


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data != null \
		and data != self \
		and data.has_method("llenar_espacio") \
		and data.has_method("vaciar_valores")


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var origen = data

	if origen == null or origen == self:
		return

	if origen.item_data == null:
		return

	# 1) Destino vacío -> mover
	if item_data == null:
		llenar_espacio(origen.item_data)
		origen.vaciar_valores()
		return

	# 2) Intentar stack
	var destino_item: Item = item_data
	var origen_item: Item = origen.item_data

	var mismo_item: bool = destino_item.name == origen_item.name

	if mismo_item and destino_item.stackable:
		var espacio_disponible: int = destino_item.max_sum - destino_item.sum

		if espacio_disponible > 0:
			var mover: int = min(espacio_disponible, origen_item.sum)

			destino_item.sum += mover
			origen_item.sum -= mover

			llenar_espacio(destino_item)

			if origen_item.sum <= 0:
				origen.vaciar_valores()
			else:
				origen.llenar_espacio(origen_item)

			return

	# 3) Si no stack -> swap
	var temp: Item = item_data
	llenar_espacio(origen.item_data)
	origen.llenar_espacio(temp)
