extends Resource
class_name Item

@export var id: String = ""
@export var name: String = "Item"
@export var icon: Texture2D
@export var stackable: bool = true
@export var sum: int = 1
@export var max_sum: int = 99999
@export var curation: int = 0;

func get_id() -> String:
	return id if id != "" else name
