extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D  #Ruta al AnimatedSprite2D

func _ready():
	animated_sprite.play("goblinMercader_idle")  # Reproduce idle en loop infinito

func _physics_process(delta):
	pass  # Mantiene posición fija
