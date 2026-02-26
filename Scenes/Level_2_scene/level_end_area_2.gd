extends Area2D

func _on_body_entered(body: Node2D) -> void:
	# Solo si el objeto que entra está en el grupo "player"
	if body.is_in_group("player"):
		print("¡Jugador detectado al final del Nivel 2!")
		print("LLAMANDO A start_level(3)")
		GameManager.start_level(3)
	else:
		# Esto te sirve para ver qué otros objetos están chocando por error
		print("Algo entró al área, pero no es el jugador: ", body.name)
