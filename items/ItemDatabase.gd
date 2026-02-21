extends Resource
class_name ItemDatabase

@export var items: Array[Item] = []
var _map: Dictionary = {}

func _build_map() -> void:
	_map.clear()
	for it in items:
		if it == null:
			continue
		_map[it.get_id()] = it

func get_item(item_id: String) -> Item:
	if _map.is_empty():
		_build_map()
	return _map.get(item_id, null)

func get_all_ids() -> Array[String]:
	if _map.is_empty():
		_build_map()

	var ids: Array[String] = []
	for k in _map.keys():
		ids.append(k)
	return ids

func make_instance(item_id: String, amount: int = 1) -> Item:
	var def := get_item(item_id)
	if def == null:
		push_warning("ItemDatabase: no existe item id='" + item_id + "'")
		return null
	var inst: Item = def.duplicate(true)
	inst.sum = max(1, amount)
	return inst
