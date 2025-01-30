extends Control  # Attach this to the root node of Main.tscn

var map_data = {}  # Store loaded map data

@onready var grid_container = $HSplitContainer/MarginContainer/MainMapDisplay/GridContainer  # Reference to GridContainer
@onready var save_map_popup = $SaveMapPopup
@onready var map_name_input = $SaveMapPopup/MapNameInput
@onready var save_map_confirm_button = $SaveMapPopup/SaveMapConfirmButton
@onready var save_map_button = $SaveMapButton  # Reference the button


func _ready():
	save_map_confirm_button.connect("pressed", Callable(self, "_on_confirm_save_map"))
 

func set_map_data(data):
	map_data = data
	print("Main scene received map data:", map_data)
	
	if grid_container:
		grid_container.load_map_data(map_data)

func _on_save_map_button_pressed():
	# Open the save map pop-up
	save_map_popup.popup_centered()  # Show the pop-up when clicking "Save"
	
	
func _on_confirm_save_map():
	var map_name = map_name_input.text.strip_edges()
	
	if map_name.is_empty():
		print("Map name cannot be empty!")
		return
		
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


func _on_load_map_button_pressed():
	#var map_name = "my_saved_map"
	#grid_container.load_map(map_name)
	pass


func _on_save_map_button_mouse_entered() -> void:
	print("Hovering over save map button")
	pass # Replace with function body.
