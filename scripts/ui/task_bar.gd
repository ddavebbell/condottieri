extends Control

# Emits signals to request actions from MapManager

signal save_map_requested
signal save_as_map_requested
signal open_map_requested
signal new_map_requested


var main_scene
var map_list_screen


func _ready():
	UiManager.register_ui("TaskBar", self)
	main_scene = get_parent().get_parent()


func _on_new_map_button_pressed():
	print("_on_new_map_button_pressed")
	emit_signal("new_map_requested")


func _on_save_map_button_pressed():
	print("_on_save_map_button_pressed")
	# This needs to check MapManager for is_saved method, if false, then pass along the map to the map list screen.
	if MapManager.is_saved() == false and not UiManager._ui_registry.has("map_list_screen"):
		map_list_screen = load("res://scenes/MapListScreen.tscn").instantiate()
		main_scene.PanelContainerBottom.add_child(map_list_screen)

		# if map unsaved, open map list and pass along new map object
		emit_signal("save_as_map_requested")
		
	if MapManager.is_saved() == true:
		# just call save map in MapManager and don't spawn the popup
		emit_signal("save_map_requested")


func _on_open_map_button_pressed():
	print("📂 TaskBar: Open Map button pressed")

	if not UiManager._ui_registry.has("MapListScreen"):
		UiManager.show_map_list_screen(true)  # true = is_open_context

		emit_signal("open_map_requested")
