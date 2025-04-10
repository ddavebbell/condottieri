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

@onready var top_Panel = $PanelContainerTop
@onready var bottom_panel = $PanelContainerBottom



func _ready():
	print("main scene ready")
	
	
	#this is getting moved
	#var task_bar = task_bar_scene.instantiate()
	#$PanelContainerTop.add_child(task_bar)
	#task_bar.call_deferred("grab_focus")


# This is for big screen swaps not modals or popups
func load_screen(screen_path: String) -> void:
	# Clear old screen
	for child in bottom_panel.get_children():
		child.queue_free()

	# Load and add new screen
	var new_screen = load(screen_path).instantiate()
	bottom_panel.add_child(new_screen)


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
