extends CanvasLayer

signal quiz_completado(exito: bool)

@onready var DisplayText: Label = $DisplayText
@onready var ListItem: ItemList = $ItemList

var items: Array = []
var index_item: int = 0
var correct: int = 0

func _ready():
	print("QUIZ VISIBLE? ", visible, " Parent: ", get_parent())
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	cargar_json("res://quiz/beatrix_questions.json")
	refresh_scene()

func cargar_json(filename: String):
	if not FileAccess.file_exists(filename):
		print("¡Error! JSON no existe: ", filename)
		return
	
	var file = FileAccess.open(filename, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result == OK:
		items = json.data
		print("JSON cargado: ", items.size(), " preguntas")
	else:
		print("¡Error parseando JSON: ", json.get_error_message())

func refresh_scene():
	if index_item >= items.size():
		finalizar_quiz(true)
	else:
		show_questions()

func show_questions():
	ListItem.visible = true
	ListItem.clear()
	
	var item = items[index_item]
	DisplayText.text = "Pregunta %d/4\n%s" % [index_item + 1, item.question]
	
	var options = item.options
	for option in options:
		ListItem.add_item(option)

func finalizar_quiz(exito: bool):
	ListItem.visible = false
	
	if exito:
		DisplayText.text = "¡PERFECTO!\\n¡Pasas al siguiente nivel!"
		get_tree().paused = false
		await get_tree().create_timer(2.0).timeout
		quiz_completado.emit(true)
		queue_free()
	else:
		DisplayText.text = "¡ERROR!\\nInténtalo de nuevo..."
		
		# Despausamos el árbol para que GameManager pueda recargar
		get_tree().paused = false
		
		await get_tree().create_timer(1.5).timeout
		
		# Solo avisamos al GameManager de que ha fallado
		quiz_completado.emit(false)
		
		# Eliminamos el overlay del quiz
		queue_free()

func _on_item_list_item_selected(index: int) -> void:
	var item = items[index_item]
	ListItem.deselect(index)
	
	if index == item.correctOptionIndex:
		correct += 1
		print("¡Correcta! %d/4" % correct)
	else:
		print("Fallaste pregunta %d" % (index_item + 1))
		finalizar_quiz(false)
		return
	
	index_item += 1
	refresh_scene()
