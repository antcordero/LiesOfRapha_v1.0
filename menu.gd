extends Control


func _on_play_pressed() -> void:
	GameManager.start_dialogue()


func _on_config_pressed() -> void:
	get_tree().change_scene_to_file("res://Options.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
