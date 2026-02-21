extends Resource
class_name Bag

@export var db: ItemDatabase
@export var objects: Dictionary = {}  # key: String -> value: ItemStack

const SAVE_PATH := "user://bag.tres"

func _ensure_db() -> void:
	if db == null:
		push_warning("Bag: 'db' no asignada. Asigna items_db.tres.")

func agregar_item(item_id: String) -> Item:
	_ensure_db()
	if db == null:
		return null

	var def: Item = db.get_item(item_id)
	if def == null:
		return null

	# Stack principal si es apilable
	if def.stackable and objects.has(item_id):
		var st: ItemStack = objects[item_id]
		if st.sum < def.max_sum:
			st.sum += 1
			return db.make_instance(item_id, st.sum)

	# Crear nuevo stack
	var key := item_id
	if not def.stackable or objects.has(key):
		key = item_id + "_" + str(randi())

	var new_stack := ItemStack.new()
	new_stack.item_id = item_id
	new_stack.sum = 1
	objects[key] = new_stack
	return db.make_instance(item_id, new_stack.sum)

func get_items_for_ui() -> Array[Item]:
	_ensure_db()
	var out: Array[Item] = []
	if db == null:
		return out

	for k in objects.keys():
		var st: ItemStack = objects[k]
		if st == null:
			continue
		var inst := db.make_instance(st.item_id, st.sum)
		if inst != null:
			out.append(inst)

	return out

# ---------- GUARDAR / CARGAR ----------

func save_to_disk() -> void:
	var err := ResourceSaver.save(self, SAVE_PATH)
	if err != OK:
		push_warning("No se pudo guardar Bag. Error: %s" % err)

static func load_from_disk() -> Bag:
	if not FileAccess.file_exists(SAVE_PATH):
		return null
	var res := ResourceLoader.load(SAVE_PATH)
	if res is Bag:
		return res
	return null
