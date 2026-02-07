extends Area2D

@export var static_scene_id: int = 2
var triggered: bool = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if triggered or !body.is_in_group("player"): return
	triggered = true
	print("Área OK. Solo cargando escena ID:", static_scene_id)
	GameManager.show_static_scene(static_scene_id)  # ← ESCENA maneja TODO
