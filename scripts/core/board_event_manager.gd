extends Node

# Responsible for accepting button pressed functions (requests) from MapEditorScreenUI and MapListScreenUI
# contains functions to process Trigger and Effects data: GET (load data), SET (save data), varify functions, helper functions
# Transfers Trigger data --> is unaware of UI

signal board_event_updated

var board_events: Array = []



func _set_board_events():
	return board_events


func _on_board_event_editor_close_requested():
	print("📢 Board Event Editor closed, refreshing editor screen if visible")
	if UiManager._ui_registry.has("BoardEventEditorScreen"):
		var board_event_editor_screen = UiManager._ui_registry["BoardEventEditorScreen"]
		board_event_editor_screen._get_board_events_from_board_event_manager()
		
	if UiManager._ui_registry.has("MapEditorPanel"):
		var map_editor_panel = UiManager._ui_registry["MapEditorPanel"]
		map_editor_panel._populate_item_list()
		emit_signal("board_event_updated")

func _add_board_event(board_event: BoardEvent):
	board_events.append(board_event)
