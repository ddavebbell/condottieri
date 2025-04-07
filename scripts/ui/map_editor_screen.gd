extends Control

class_name MapEditorScreen

signal board_event_edit_requested(board_event)
signal spawn_map_info_screen

#region NODE REFS
@onready var events_show_hide_button = $HSplitContainer/SideMenu/MarginContainer/MenuWrapper/BoardEventMenu/HBoxContainer/Show_HideButton
@onready var pieces_show_hide_button = $HSplitContainer/SideMenu/MarginContainer/MenuWrapper/PiecesMenu/HBoxContainer/Pieces_Show_HideButton
@onready var tiles_show_hide_button = $HSplitContainer/SideMenu/MarginContainer/MenuWrapper/TileMenu/HBoxContainer/Tiles_Show_HideButton
@onready var board_event_section = $HSplitContainer/SideMenu/MarginContainer/MenuWrapper/BoardEventMenu/MarginContainer/HBoxContainer
@onready var pieces_section = $HSplitContainer/SideMenu/MarginContainer/MenuWrapper/PiecesMenu/MarginContainer/ScrollContainer
@onready var tiles_section = $HSplitContainer/SideMenu/MarginContainer/MenuWrapper/TileMenu/MarginContainer/BoxContainer

@onready var grid_container = $HSplitContainer/MarginContainer/GridContainer
@onready var map_editor_popup = $MapEditorPopUp
@onready var map_list_screen = null


var current_map: Map = null
var board_event_editor: BoardEventEditorScreen = null
var board_event_manager: BoardEventManager = null

# STATE
var current_filename: String = ""

#endregion


#region LIFECYCLE
func _ready():
	_set_show_hide_button_text()
	UiManager.register_ui("map_editor_screen", self)
	
	var map = MapManager.get_current_map()
	if map:
		MapManager.load_map(map)
	else:
		push_error("❌ No map loaded into MapManager")

#endregion


#region MAP MANAGER DELEGATION



# this function is not useful?
func _on_map_loaded(current_map):
	current_filename = current_map["name"]
	print("📂 Map Editor Screen - Loaded map:", current_filename)



#endregion


func set_context(context: Dictionary) -> void:
	print("🧭 Context received by MapListScreen:", context)
	# Use this to change tabs, pre-select a map, etc.


#region BOARD EVENT MANAGER DELEGATION

# EVERYTHING HERE GOES TO TASK BAR 


#endregion


#region EVENT HANDLERS - FROM TASKBAR
#  1. tell MainScene what scene to open
#  2. tell manager the context the scene is opening
#          - open as first time, as load map, as save map, 

func open_popup():
	pass

func open_with_first_time_context():
	pass

# open popup with load map context
func open_with_load_map_context():
	MapManager.set_open_context("load_map")
	map_editor_popup.popup_centered()

func open_with_save_as_context(map_name: String):
	# Tell MapManager we're opening the save-as popup

	MapManager.set_open_context("save_map_as")

		# Get current map from MapEditor (assuming a function or var holds it)
	if current_map:
		MapManager.set_current_map(current_map)

	# Open the popup, letting it pull data from MapManager internally
	map_editor_popup.popup_centered()

# need a function to get the map object from the map editor and set it to current_map
# when you first instantiate map editor screen, create a new map
# when you are loading a map, load the map


func _set_show_hide_button_text():
	if board_event_section.visible:
		events_show_hide_button.text = "Hide"
	else:
		events_show_hide_button.text = "Show"
		
	if tiles_section.visible:
		tiles_show_hide_button.text = "Hide"
	else:
		tiles_show_hide_button.text = "Show"

	if pieces_section.visible:
		pieces_show_hide_button.text = "Hide"
	else:
		pieces_show_hide_button.text = "Show"


func _on_board_event_show_hide_button_pressed():
	board_event_section.visible = !board_event_section.visible
	
	if board_event_section.visible:
		events_show_hide_button.text = "Hide"
	else:
		events_show_hide_button.text = "Show"


func _on_tile_show_hide_button_pressed():
	tiles_section.visible = !tiles_section.visible
	
	if tiles_section.visible:
		tiles_show_hide_button.text = "Hide"
	else:
		tiles_show_hide_button.text = "Show"


func _on_pieces_show_hide_button_pressed():
	pieces_section.visible = !pieces_section.visible
	
	if pieces_section.visible:
		pieces_show_hide_button.text = "Hide"
	else:
		pieces_show_hide_button.text = "Show"


#endregion


#region FACTORIES

func _spawn_board_event_editor() -> BoardEventEditorScreen:
	board_event_editor = load("res://scenes/BoardEventEditorScreen.tscn").instantiate()
	board_event_editor.visible = true
	board_event_editor.z_index = 50
	board_event_manager.initialize(board_event_editor)
	board_event_editor.call_deferred("grab_focus")
	add_child(board_event_editor)
	return board_event_editor

#endregion


func _on_edit_map_info_button_pressed() -> void:
	# tell UImanager to spawn MapInfoScreen
	emit_signal("spawn_map_info_screen")
