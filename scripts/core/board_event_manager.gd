extends Node

signal board_event_updated

var board_events: Array[BoardEvent] = []

# === GET/SET ===

func get_board_events() -> Array[BoardEvent]:
	return board_events

func set_board_events(new_events: Array[BoardEvent]) -> void:
	board_events = new_events.duplicate()
	emit_signal("board_event_updated")
	print("📋 Board events list replaced. Total:", board_events.size())

# === ADD/REMOVE ===

func add_board_event(board_event: BoardEvent) -> void:
		# Check if an identical event already exists based on key fields
	for existing_event in board_events:
		if (
			existing_event.cause == board_event.cause
			and existing_event.effect == board_event.effect
			and existing_event.sound_effect == board_event.sound_effect
		):
			print("⚠️ Duplicate board event detected based on content. Skipping add:", board_event.name)
			return

	if board_events.has(board_event):
		print("⚠️ Board event already exists. Skipping add:", board_event.name)
		return
	
	board_events.append(board_event)
	emit_signal("board_event_updated")
	print("➕ Added board event:", board_event.name)

func remove_board_event(board_event: BoardEvent) -> void:
	if board_events.has(board_event):
		board_events.erase(board_event)
		emit_signal("board_event_updated")
		print("🗑 Removed board event:", board_event.name)
	else:
		print("⚠️ Tried to remove board event that doesn't exist:", board_event.name)

# === UI CLOSE CALLBACK ===

func _on_board_event_editor_close_requested():
	print("📢 Board Event Editor closed, refreshing editor screen if visible")
	
	if UiManager._ui_registry.has("BoardEventEditorScreen"):
		var editor = UiManager._ui_registry["BoardEventEditorScreen"]
		editor._get_board_events_from_board_event_manager()
	
	if UiManager._ui_registry.has("MapEditorPanel"):
		var panel = UiManager._ui_registry["MapEditorPanel"]
		panel._populate_board_event_list()

	emit_signal("board_event_updated")
