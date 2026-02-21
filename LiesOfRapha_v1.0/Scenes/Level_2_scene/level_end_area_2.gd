extends Area2D

func _on_body_entered(body: Node2D) -> void:
	print("BODY ENTERED LEVEL 2:", body)
	print("LLAMANDO A start_level(3)")
	GameManager.start_level(3)
