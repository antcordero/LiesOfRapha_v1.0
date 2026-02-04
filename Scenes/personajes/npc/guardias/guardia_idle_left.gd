extends CharacterBody2D

@export var dialogue_file: Resource
var player_in_range: bool = false
var dialogue_active: bool = false
var current_balloon: Node = null

const MY_DIALOGUE := preload("res://dialogues/soldier.dialogue")


func _ready() -> void:
	var area: Area2D = get_node_or_null("areaHablar")
	if area == null:
		push_error("No existe un nodo Area2D llamado 'areaHablar' como hijo del NPC.")
		return

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false


func _process(delta: float) -> void:
	# Abrir diálogo
	if player_in_range and not dialogue_active and Input.is_action_just_pressed("do_something"):
		mostrar_dialogo()

	# Cerrar diálogo con otra tecla, por ejemplo ui_cancel
	if dialogue_active and Input.is_action_just_pressed("cancel"):
		cerrar_dialogo()


func mostrar_dialogo() -> void:
	dialogue_active = true

	if dialogue_file == null:
		current_balloon = DialogueManager.show_dialogue_balloon(MY_DIALOGUE)
	else:
		var texto := ""
		var file := FileAccess.open(dialogue_file.resource_path, FileAccess.READ)
		while file.get_position() < file.get_length():
			texto += file.get_line() + "\n"
		file.close()

		var label := get_tree().root.get_node("world/CanvasLayer/DialogueLabel")
		label.text = texto
		label.visible = true


func cerrar_dialogo() -> void:
	if current_balloon and is_instance_valid(current_balloon):
		current_balloon.queue_free()

	# Si usas Label propio:
	# var label := get_tree().root.get_node("world/CanvasLayer/DialogueLabel")
	# label.visible = false

	dialogue_active = false
