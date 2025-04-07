extends Control





# Event Handler

# This goes on Board Event List as well
func _on_edit_board_event_pressed(button: Button):
	var selected_board_event = button.get_meta("board_event_data")
	emit_signal("board_event_edit_requested", selected_board_event)


func open_board_event_editor():
	# tell MainScene to open Board Event Editor
	# emit_signal() to MainScene
	# board_event_editor = _spawn_board_event_editor()
	pass
