extends Control


# Spawn UI functions

func _on_new_map_button_pressed():
	print("➡️ TitleScreen: new map requested")
	
	UiManager.open_new_map_flow()
	call_deferred("queue_free")


func _on_open_map_button_pressed():
	print("_on_open_map_button_pressed")
	
	UiManager.open_open_map_flow_from_title_screen()
	call_deferred("queue_free")
