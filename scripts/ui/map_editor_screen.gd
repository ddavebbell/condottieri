extends Control

class_name MapEditorScreen

signal board_event_edit_requested(board_event)
signal open_map_info_screen

#region NODE REFS

@onready var map_name_label = $ContextMenuContainer/MarginContainer/Panel/MapNameLabel
@onready var edit_map_info_button = $ContextMenuContainer/MarginContainer/Panel/EditMapInfoButton

@onready var create_event_button = $HSplitContainer/SideMenu/MarginContainer/MenuWrapper/BoardEventMenu/MarginContainer/HBoxContainer/VBoxContainer/CreateEventButton
@onready var edit_event_button = $HSplitContainer/SideMenu/MarginContainer/MenuWrapper/BoardEventMenu/MarginContainer/HBoxContainer/VBoxContainer/EditEventButton
@onready var delete_event_button = $HSplitContainer/SideMenu/MarginContainer/MenuWrapper/BoardEventMenu/MarginContainer/HBoxContainer/VBoxContainer/DeleteEventButton
@onready var open_event_list_button = $HSplitContainer/SideMenu/MarginContainer/MenuWrapper/BoardEventMenu/MarginContainer/HBoxContainer/VBoxContainer/OpenListButton
@onready var board_event_section = $HSplitContainer/SideMenu/MarginContainer/MenuWrapper/BoardEventMenu/MarginContainer/HBoxContainer
@onready var board_event_list = $HSplitContainer/SideMenu/MarginContainer/MenuWrapper/BoardEventMenu/MarginContainer/HBoxContainer/ScrollContainer/BoardEventList

@onready var events_show_hide_button = $HSplitContainer/SideMenu/MarginContainer/MenuWrapper/BoardEventMenu/HBoxContainer/Show_HideButton
@onready var pieces_show_hide_button = $HSplitContainer/SideMenu/MarginContainer/MenuWrapper/PiecesMenu/HBoxContainer/Pieces_Show_HideButton
@onready var tiles_show_hide_button = $HSplitContainer/SideMenu/MarginContainer/MenuWrapper/TileMenu/HBoxContainer/Tiles_Show_HideButton
@onready var pieces_section = $HSplitContainer/SideMenu/MarginContainer/MenuWrapper/PiecesMenu/MarginContainer/ScrollContainer
@onready var tiles_section = $HSplitContainer/SideMenu/MarginContainer/MenuWrapper/TileMenu/MarginContainer/BoxContainer

@onready var grid_container = $HSplitContainer/MarginContainer/GridContainer
@onready var map_editor_popup = $MapEditorPopUp
@onready var map_list_screen = null

# STATE
var current_map: Map = null
var current_filename: String = ""
var current_board_events: Array = []
# get the board events from the Map object and populate this array


#endregion


func _ready():
	_set_show_hide_button_text()
	UiManager.register_ui("MapEditorScreen", self)
	_refresh_current_map()
	_populate_item_list()
	_generate_dummy_board_events()
	BoardEventManager.connect("board_event_updated", Callable(self, "_on_board_event_updated"))



func _refresh_current_map():
	current_map = MapManager.get_current_map()
	print("current_map:   ", current_map)
	_set_map_name()


func _on_board_event_updated():
	print("🔁 Board events updated — refreshing UI")
	_get_board_events_from_board_event_manager()
	_populate_item_list()  # or whatever you call to redraw the list


func _get_board_events_from_board_event_manager():
	current_board_events = BoardEventManager._set_board_events()


# this merges both the current_map events, and the map's unsaved board events.
func _populate_item_list():
	board_event_list.clear()

	var seen := {}

	# Add new unsaved board events first
	for event in current_board_events:
		var id := str(event)  # or use a unique property if you have one, like event.id
		if not seen.has(id):
			board_event_list.add_item(event.get_display_name())
			seen[id] = true

	# Add events already on the map, but only if not duplicated
	if current_map.board_events:
		for event in current_map.board_events:
			var id := str(event)
			if not seen.has(id):
				board_event_list.add_item(event.get_display_name())
				seen[id] = true


# this function is not useful ? ? ?
func _on_map_loaded(current_map):
	current_filename = current_map["name"]
	print("📂 Map Editor Screen - Loaded map:", current_filename)


func set_context(context: Dictionary) -> void:
	print("🧭 Context received by MapListScreen:", context)
	# Use this to change tabs, pre-select a map, etc.


func _set_map_name():
	if current_map:
		map_name_label.text = current_map.name


#region EVENT HANDLERS - FROM TASKBAR



func open_with_save_as_context(map_name: String):
	# Tell MapManager we're opening the save-as popup

	MapManager.set_open_context("save_map_as")

		# Get current map from MapEditor (assuming a function or var holds it)
	if current_map:
		MapManager.set_current_map(current_map)

	# Open the popup, letting it pull data from MapManager internally
	map_editor_popup.popup_centered()


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


func _on_edit_map_info_button_pressed() -> void:
	print("_on_edit_map_info_button_pressed")
	# tell UImanager to spawn MapInfoScreen
	emit_signal("open_map_info_screen")


#endregion

# FIX THIS # FIX THIS # FIX THIS #
func _on_open_board_event_list_button_pressed() -> void:
	print("📂 Open Board Event List pressed")
	if UiManager._ui_registry.has("BoardEventEditorScreen"):
		print("🟡 BoardEventEditorScreen already exists — debug why it wasn't queue freed before.")
		# maybe have a make visible function
		return

	var main_scene = get_tree().root.get_node("MainScene")
	var board_event_editor_screen_scene = main_scene.spawn_popup(main_scene.board_event_editor_screen_scene)


func _on_create_event_button_pressed() -> void:
	print("📂 Create Board Event Button pressed")
	if UiManager._ui_registry.has("BoardEventEditorScreen"):
		print("🟡 BoardEventEditorScreen already exists — debug why it wasn't queue freed before.")
		return

	var main_scene = get_tree().root.get_node("MainScene")
	var popup = main_scene.spawn_popup(main_scene.board_event_editor_screen_scene)

	# 🧠 Call the setup method to initialize board_event
	# ✅ Step 2 debug prints
	print("⏳ Waiting for popup to be ready...")
	await popup.ready
	print("✅ Popup ready — calling setup_for_new_event")
	
	popup.setup_for_new_event(current_board_events)



# pass on the Board Event object
func _on_edit_event_button_pressed() -> void:
	# Check if the editor screen is already open
	if UiManager._ui_registry.has("BoardEventEditorScreen"):
		print("🟡 BoardEventEditorScreen already exists — debug why it wasn't queue freed before.")
		return

	# Get selected index from ItemList
	var selected_items = board_event_list.get_selected_items()
	if selected_items.is_empty():
		print("⚠️ No board event selected for editing.")
		return

	var selected_index = selected_items[0]

	if selected_index >= current_board_events.size():
		push_error("❌ Selected index is out of bounds for current_board_events.")
		return

	# Get the selected board event
	var selected_event: BoardEvent = current_board_events[selected_index]

	# Spawn the BoardEventEditorScreen
	var main_scene = get_tree().root.get_node("MainScene")
	var popup = main_scene.spawn_popup(main_scene.board_event_editor_screen_scene)

	# Send the event to the popup
	await popup.ready
	popup.setup_for_edit_event(selected_event, current_board_events)



func _on_delete_event_button_pressed(board_event: BoardEvent) -> void:
	if board_event_list.get_selected_items().is_empty():
		print("⚠️ No item selected to delete.")
		return

	var selected_idx = board_event_list.get_selected_items()
	
	var index = board_event_list.get_selected_items()[0]
	current_board_events.remove_at(index)

	pass # Replace with function body.



# dummy testing functions

func _generate_dummy_board_events(count: int = 5):
	current_board_events.clear()

	for i in count:
		var event := preload("res://scripts/resources/board_event.gd").new()
		event.name = "Dummy Event %d" % i
		event.description = "This is a fake event used for testing (#%d)" % i

		event.causes = ["Turn %d" % (i + 1)]
		event.effects = ["Effect Type %d" % (i + 1)]
		event.sound_effects = ["sound_%d.wav" % (i + 1)]

		current_board_events.append(event)

	print("🐛 Generated %d dummy board events for debugging" % count)
