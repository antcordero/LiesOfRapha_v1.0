extends Node2D

@onready var dialogue_resource = preload("res://Dialogues/initial.dialogue")

func _ready():
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	await get_tree().create_timer(1.0).timeout
	DialogueManager.show_dialogue_balloon(dialogue_resource, "start")

func _on_dialogue_ended(_resource):
	GameManager.show_static_scene(1)  # ID 1 para escenas_estaticas.tscn
