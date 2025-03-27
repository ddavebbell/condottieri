extends Panel

var dragging = false

func _ready():
	modulate = Color(1, 1, 1, 0)  # Start as invisible
	# # Initialize drag-and-drop items
	for child in get_children():
		if child.has_signal("gui_input"):
			child.connect("gui_input", Callable(self,"onitem_gui_input"))



func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
	elif event is InputEventMouseMotion and dragging:
		var delta = event.relative.y
		var above = get_above_sibling()
		var below = get_below_sibling()
		if above and below:
			# Adjust the sizes of the siblings
			above.custom_minimum_size.y += delta
			below.custom_minimum_size.y -= delta
			# Prevent negative sizes
			above.custom_minimum_size.y = max(above.custom_minimum_size.y, 50)
			below.custom_minimum_size.y = max(below.custom_minimum_size.y, 50)


func get_above_sibling():
	var index = get_index()
	if index > 0:
		return get_parent().get_child(index - 1)
	return null

func get_below_sibling():
	var index = get_index()
	if index < get_parent().get_child_count() - 1:
		return get_parent().get_child(index + 1)
	return null
	
func _on_mouse_entered():
	# Highlight the divider when hovered
	modulate = Color(5, 5, 5, 1)  # Lightly visible when hovered

func _on_mouse_exited():
	# Return to invisible when the mouse leaves
	modulate = Color(1, 1, 1, 0)
	

	
