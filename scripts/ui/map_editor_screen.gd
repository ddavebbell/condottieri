extends Control
class_name MapEditorScreen

signal board_event_edit_requested(board_event)
signal open_map_info_screen
signal setup_for_edit_event

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

#endregion

# STATE
var current_map: Map = null
var current_filename: String = ""



func _ready():
	_set_show_hide_button_text()
	UiManager.register_ui("MapEditorScreen", self)
	BoardEventManager.connect("board_event_updated", Callable(self, "_on_board_event_updated"))
	BoardEventManager.board_events.clear()
	generate_dummy_board_events()
	_refresh_current_map()
	_populate_board_event_list()


func _refresh_current_map():
	current_map = MapManager.get_current_map()
	print("current_map:   ", current_map)
	_set_map_name()


func _on_board_event_updated():
	print("🔁 Board events updated — refreshing UI")
	#_get_board_events_from_board_event_manager()
	_populate_board_event_list()  # or whatever you call to redraw the list


#func _get_board_events_from_board_event_manager():
	#current_board_events = BoardEventManager._set_board_events()


# this merges both the current_map events, and the map's unsaved board events.


func _populate_board_event_list():
	board_event_list.clear()
	var seen := {}

	for event in BoardEventManager.board_events:
		var id := str(event)
		if not seen.has(id):
			board_event_list.add_item(event.get_display_name())
			seen[id] = true

	if current_map and current_map.board_events:
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
	_set_show_hide_button_text()


func _on_tile_show_hide_button_pressed():
	tiles_section.visible = !tiles_section.visible
	_set_show_hide_button_text()


func _on_pieces_show_hide_button_pressed():
	pieces_section.visible = !pieces_section.visible
	_set_show_hide_button_text()


func _on_edit_map_info_button_pressed() -> void:
	print("_on_edit_map_info_button_pressed")
	# tell UImanager to spawn MapInfoScreen
	emit_signal("open_map_info_screen")


#endregion


#region UI Actions


func _on_open_board_event_list_button_pressed() -> void:
	print("📂 Open Board Event List pressed")
	if UiManager._ui_registry.has("BoardEventEditorScreen"):
		print("🟡 BoardEventEditorScreen already exists — debug why it wasn't queue freed before.")
		# maybe have a make visible function
		return

	var main_scene = get_tree().root.get_node("MainScene")
	var board_event_editor_screen_scene = main_scene.spawn_popup(main_scene.board_event_editor_screen_scene)


func _on_create_event_button_pressed() -> void:
	if UiManager._ui_registry.has("BoardEventEditorScreen"):
		print("🟡 BoardEventEditorScreen already exists — debug why it wasn't queue freed before.")
		return
	var popup = get_tree().root.get_node("MainScene").spawn_popup(get_tree().root.get_node("MainScene").board_event_editor_screen_scene)
	popup.setup_for_new_event(BoardEventManager.board_events)


func _on_edit_event_button_pressed() -> void:
	if UiManager._ui_registry.has("BoardEventEditorScreen"):
		print("🟡 BoardEventEditorScreen already exists — debug why it wasn't queue freed before.")
		return
	var selected_items = board_event_list.get_selected_items()
	if selected_items.is_empty():
		print("⚠️ No board event selected for editing.")
		return
	var index = selected_items[0]
	if index >= BoardEventManager.board_events.size():
		push_error("❌ Selected index is out of bounds.")
		return
	var selected_event = BoardEventManager.board_events[index]
	var popup = get_tree().root.get_node("MainScene").spawn_popup(get_tree().root.get_node("MainScene").board_event_editor_screen_scene)
	popup.call_deferred("setup_for_edit_event", selected_event, BoardEventManager.board_events)


func _on_delete_event_button_pressed() -> void:
	var selected_items = board_event_list.get_selected_items()
	if selected_items.is_empty():
		print("⚠️ No board event selected to delete.")
		return
	var index = selected_items[0]
	if index >= BoardEventManager.board_events.size():
		push_error("❌ Selected index out of range.")
		return
	var event = BoardEventManager.board_events[index]
	BoardEventManager.remove_board_event(event)
	_populate_board_event_list()

#endregion

# dummy testing functions

func generate_dummy_board_events():
	var evt1 = BoardEvent.new()
	evt1.name = "Enemy Ambush"
	evt1.description = "Triggers when enemies enter the trap zone."
	var cause1 = Cause.new()
	cause1.local_cause = Cause.LocalCause.PIECE_ENTERS_TILE
	cause1.pop_up_text = "An enemy has entered the trap zone!"
	evt1.cause = cause1
	var eff1 = Effect.new()
	eff1.effect_type = Effect.EffectType.ACTIVATE_TRAP
	eff1.effect_parameters = {"tile": Vector2(3, 2), "damage": 25}
	evt1.effect = eff1
	evt1.sound_effect = "trap_triggered.wav"
	evt1.map_name_event_belongs_to = "DesertMap"
	BoardEventManager.add_board_event(evt1)

	var evt2 = BoardEvent.new()
	evt2.name = "Reinforcements Arrive"
	evt2.description = "Adds reinforcements after turn 5."
	var cause2 = Cause.new()
	cause2.global_cause = Cause.GlobalCause.TURN_COUNT_REACHED
	cause2.pop_up_text = "Turn 5 reached. Reinforcements inbound!"
	evt2.cause = cause2
	var eff2 = Effect.new()
	eff2.effect_type = Effect.EffectType.SPAWN_REINFORCEMENTS
	eff2.effect_parameters = {"position": Vector2(0, 0), "unit_type": "Archer", "count": 2}
	evt2.effect = eff2
	evt2.sound_effect = "reinforcements_arrive.wav"
	evt2.map_name_event_belongs_to = "MountainPass"
	BoardEventManager.add_board_event(evt2)

	print("\n📦 2 Dummy Board Events Created")
	for i in BoardEventManager.board_events.size():
		var evt = BoardEventManager.board_events[i]
		print("🔹 [%d] %s" % [i, evt.name])
		print("   ↪ Description: %s" % evt.description)
		print("   🧩 Cause: %s" % (evt.cause.local_cause if evt.cause.local_cause != Cause.LocalCause.NONE else evt.cause.global_cause))
		print("   ⚡ Effect: %s" % str(evt.effect.effect_type))
		print("      ▶ Params: %s" % str(evt.effect.effect_parameters))
		print("   🎧 Sound Effect: %s" % (evt.sound_effect if evt.sound_effect != "" else "None"))
		print("   📍 Map: %s\n" % evt.map_name_event_belongs_to)
	print("✅ Done printing dummy board events.")
