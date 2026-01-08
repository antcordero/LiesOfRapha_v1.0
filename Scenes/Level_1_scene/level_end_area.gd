extends Area2D

func _on_body_entered(body: Node2D) -> void:
	print("BODY ENTERED:", body)
	if body.is_in_group("Player"):
		GameManager.start_level(2)
