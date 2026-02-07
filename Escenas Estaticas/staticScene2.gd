extends Node2D

@onready var dialogue_resource = preload("res://Dialogues/dialogo_sala2.dialogue")

func _ready():
	print("staticScene2 LISTA!")
	
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	await get_tree().create_timer(1.0).timeout
	print("Mostrando diálogo:", dialogue_resource)  # ← DEBUG
	DialogueManager.show_dialogue_balloon(dialogue_resource, "start")

func _on_dialogue_ended(_resource):
	print("Final → Level1")
	GameManager.start_level(1)
