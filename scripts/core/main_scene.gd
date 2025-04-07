extends Control

class_name MainScene

## MASTERMOLD ##
# This UI is only responsible for Spawning UIs #

var task_bar_scene = preload("res://scenes/TaskBar.tscn")
var map_list_screen_scene = preload("res://scenes/MapListScreen.tscn")
var board_event_editor_screen_scene = preload("res://scenes/BoardEventEditorScreen.tscn")
var map_editor_screen_scene = preload("res://scenes/MapEditorScreen.tscn")

var map_list_screen: Control = null
var map_editor_screen: Control = null
var board_event_editor_screen: Control = null

var map_manager = MapManager
var board_event_manager = BoardEventManager

@onready var scene_container = $PanelContainerBottom




func _ready():
	pass
	# Only run the Task Bar by default
	
	#this is getting moved
	#var task_bar = task_bar_scene.instantiate()
	#$PanelContainerTop.add_child(task_bar)
	#task_bar.call_deferred("grab_focus")


# Then Spawn Appropriate UI
func on_open_map_list_screen_requested():
	if not map_list_screen:
		map_list_screen = map_list_screen_scene.instantiate()
		$PanelContainerBottom.add_child(map_list_screen)
	else:
		print("map_list_screen exists already so skipped instantiate()")

		

	# Replace current scene with map list
	map_list_screen.call_deferred("grab_focus")




func on_open_map_editor_screen_requested():
	if not map_editor_screen:
		print("map_editor_screen is null")
		map_editor_screen = map_editor_screen_scene.instantiate()
		$PanelContainerBottom.add_child(map_editor_screen)


	# Replace current scene with map list
	map_editor_screen.call_deferred("grab_focus")


func on_board_event_editor_screen_requested():
	if not board_event_editor_screen:
		print("board_event_editor_screen is null")
		board_event_editor_screen = board_event_editor_screen_scene.instantiate()
		$PanelContainerBottom.add_child(board_event_editor_screen)
	else:
		board_event_editor_screen.visible = true
	
	# Replace current scene with board_event_editor_screen
	board_event_editor_screen.call_deferred("grab_focus")
