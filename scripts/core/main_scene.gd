extends Control

class_name MainScene

## MASTERMOLD ##
# This UI is only responsible for Spawning UIs #

var task_bar_scene = preload("res://scenes/TaskBar.tscn")
var map_list_screen_scene = preload("res://scenes/MapListScreen.tscn")
var board_event_editor_screen_scene = preload("res://scenes/BoardEventEditorScreen.tscn")
var map_editor_screen_scene = preload("res://scenes/MapEditorScreen.tscn")
var map_info_screen_scene = preload("res://scenes/MapInfoScreen.tscn")


@onready var top_Panel = $PanelContainerTop
@onready var bottom_panel = $PanelContainerBottom



func _ready():
	print("main scene ready")
	UiManager.register_ui("MainScene", self)


# Replaces the current full-screen UI (in PanelContainerBottom)
func replace_screen(screen_scene: PackedScene) -> Node:
	for child in $PanelContainerBottom.get_children():
		child.queue_free()

	var screen = screen_scene.instantiate()
	$PanelContainerBottom.add_child(screen)
	return screen


# For popups that float on top (modals, dialogs, etc.)
func spawn_popup(popup_scene: PackedScene) -> Node:
	var popup = popup_scene.instantiate()
	add_child(popup)  # Add directly to MainScene so it overlays
	popup.z_index = 100  # Ensure it's on top
	return popup
