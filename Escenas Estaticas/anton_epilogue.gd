extends AnimatedSprite2D

@export var nombre_animacion: String = "idle_anton"

func _ready() -> void:
	# En cuanto la escena carga, que reproduzca esa animación
	play(nombre_animacion)
