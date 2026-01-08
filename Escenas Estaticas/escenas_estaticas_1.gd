extends Node2D

@onready var dialogue_resource = preload("res://Dialogues/dialogo_1.dialogue")

func _ready():
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	await get_tree().create_timer(1.0).timeout
	DialogueManager.show_dialogue_balloon(dialogue_resource, "start")

func _on_dialogue_ended(_resource):
	GameManager.start_level(1)
