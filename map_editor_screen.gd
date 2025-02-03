extends Control  # Attach this to the root node of map_editor_screen.tscn

var map_data = {}  # Store loaded map data

var current_filename: String = ""  # Tracks the current map file name

@onready var save_map_popup = $SaveMapPopup
@onready var save_map_button = $SaveMapButton  # Reference the button
@onready var grid_container = $HSplitContainer/MarginContainer/MainMapDisplay/GridContainer  # Reference to GridContainer
@onready var map_name_input = $SaveMapPopup/MarginContainer/VBoxContainer/MapNameInput
@onready var save_map_confirm_button = $SaveMapPopup/MarginContainer/VBoxContainer/HBoxContainer/SaveMapConfirmButton
@onready var save_as_button = $SaveMapPopup/MarginContainer/VBoxContainer/HBoxContainer/SaveAsMapConfirmButton  # Add reference

func _ready():
	save_map_popup.visible = false
	save_map_confirm_button.connect("pressed", Callable(self, "_on_confirm_save_map"))
	save_as_button.connect("pressed", Callable(self, "_on_save_as_button_pressed"))  # New Save As connection

func set_map_data(data):
	map_data = data
	print("Main scene received map data:", map_data)
	
	if grid_container:
		grid_container.load_map_data(map_data)

func _on_save_map_button_pressed():
	# If a map was already saved before, allow Save; otherwise, prompt for Save As
	if current_filename.is_empty():
		open_save_as_popup()
	else:
		_save_map(current_filename)
		

func open_save_as_popup():
	map_name_input.text = current_filename if current_filename != "" else ""
	save_map_popup.popup_centered()

func _save_map(map_name: String):
	if map_name.is_empty():
		print("Map name cannot be empty!")
		return
	
	current_filename = map_name  # Update the last saved filename
	grid_container.save_map(map_name)
	print("Map saved:", map_name)
	
func _on_confirm_save_map():
	var map_name = map_name_input.text.strip_edges()
	
	if map_name.is_empty():
		print("Map name cannot be empty!")
		return
		
	var file_path = "user://maps/" + map_name + ".json"
	
	# Check if the file already exists
	if FileAccess.file_exists(file_path):
		print("Overwriting existing map:", map_name)
	else:
		print("Saving new map:", map_name)
		
	grid_container.save_map(map_name)  # Call save function
	save_map_popup.hide()  # Close the pop-up
	
	print("Map saved:", map_name) 
	await get_tree().process_frame
	print("Does map exist", FileAccess.file_exists("user://maps/" + map_name + ".json"))
	print("Checking files in 'user://maps/':")
	var dir = DirAccess.open("user://maps")
	if dir:
		var files = dir.get_files()
		for f in files:
			print(f)  # List all files inside user://maps/
	else:
		print("Error: 'user://maps/' directory does not exist.")


func _on_save_map_popup_close_requested() -> void:
	save_map_popup.hide()


func _on_back_to_main_pressed() -> void:
	print("🔙 Returning to Main Screen...")
	
	# Load the main screen scene
	var main_screen_scene = load("res://first_selection_screen.tscn").instantiate()
	
	# Switch to the main screen
	get_tree().root.add_child(main_screen_scene)
	get_tree().current_scene.queue_free()  # Remove current scene
	get_tree().current_scene = main_screen_scene  # Set new scene
