extends PanelContainer

var events = [
	{ "name": "Spawn Enemy", "description": "Spawns an enemy at the trigger location." },
	{ "name": "Open Door", "description": "Opens a specified door." }
]


func _ready():
	print("EventMenu script is ready!")
	var style_box = StyleBoxFlat.new()
	# Set the background color to fully opaque (adjust the color as needed)
	style_box.bg_color = Color(0.18,0.18,0.18, 1)  # trying to match the default color from the start of coding
	add_theme_stylebox_override("panel", style_box) # Apply the style box to the PanelContainer

	if not populate_event_menu():
		print("Failed to populate EventsMenu")


func populate_event_menu() -> bool:
	var events_container = $ScrollContainer/EventList
	
	if not events_container:
		print("VBoxContainer under events_container not found!")
		return false
		
	# Clear existing children in VBoxContainer
	clear_children(events_container) # Clear previous children if needed
	
	for event in events: # Example: Reuse trigger data for events for now
		var event_item = create_event_item(event)
		events_container.add_child(event_item)
		
	print("EventsMenu populated with items.")
	return true
	
	
func create_event_item(event_data: Dictionary) -> VBoxContainer:
	var container = VBoxContainer.new()
	#container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var name_label = Label.new()
	name_label.text = event_data.get("name", "Unnamed Event")
	#name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	container.add_child(name_label)

	var description = Label.new()
	description.text = event_data["description"]
	#description.autowrap_mode = TextServer.AUTOWRAP_WORD\

	description.modulate = Color(0.7, 0.7, 0.7)  # Dimmed color for descriptions
	container.add_child(description)
	return container
	
	
func clear_children(container: Control):
	# Remove and free all children of the node
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
