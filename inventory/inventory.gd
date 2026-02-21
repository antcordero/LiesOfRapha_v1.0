extends Resource
class_name Bag

@export var objects: Dictionary = {}  # key: String -> value: Item

func agregar_item(item: Item) -> Item:
	var key := item.name

	# Si ya existe el stack principal (misma key base), apilar ahí si se puede
	if objects.has(key):
		var item_in_bag: Item = objects[key]
		if item_in_bag.stackable and item_in_bag.sum < item_in_bag.max_sum:
			item_in_bag.sum += 1
			return item_in_bag

	# Si no se apila (o no existe), crear nueva instancia
	var new_instance_item: Item = item.duplicate()
	var new_key := key

	# Si no es stackable o ya existe esa key, crear key única
	if not new_instance_item.stackable or objects.has(new_key):
		new_key = key + "_" + str(randi())

	objects[new_key] = new_instance_item
	return new_instance_item
