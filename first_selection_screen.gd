extends Control

# Placeholder for the list of maps (Now loaded from GlobalData)
var map_list = []
var selected_map = null  # Store selected map globally


# UI Nodes
@onready var map_list_container = $MapListContainer  # Scrollable container for map list
@onready var map_thumbnail = $MapThumbnail  # Thumbnail preview
@onready var create_map_button = $CreateMapButton
@onready var delete_map_button = $DeleteMapButton
@onready var open_map_button = $OpenMapButton
@onready var title_label = $TitleLabel


func _ready():
	# Set title
	title_label.text = "Condottieri: Map Creator"
	
	load_maps_from_files()  # Load saved maps on startup
	
	# Connect button signals
	create_map_button.connect("pressed", Callable(self, "_on_create_map"))
	delete_map_button.connect("pressed", Callable(self, "_on_delete_map"))
	open_map_button.connect("pressed", Callable(self, "_on_open_map"))
	
	# Populate the map list from GlobalData
	_populate_map_list()

func _populate_map_list():
	# Clear the list first
	for child in map_list_container.get_children():
		child.queue_free()
		
	# Get saved maps from GlobalData
	map_list = GlobalData.get_maps()
		
	# Add map entries
	for map_data in map_list:
		var button = Button.new()
		button.text = map_data["name"]
		button.connect("pressed", Callable(self, "_on_map_selected").bind(map_data))
		map_list_container.add_child(button)

func _on_map_selected(map_data):
	# Display the selected map's thumbnail
	selected_map = map_data  # Store selected map globally
	map_thumbnail.texture = map_data["thumbnail"]
	map_thumbnail.visible = true

	# Enable "Delete" and "Open" buttons
	delete_map_button.disabled = false
	open_map_button.disabled = false

func _on_create_map():
	# Placeholder for creating a new map
	print("Create Map button pressed")
	# Logic to create a new map goes here

func _on_delete_map():
	if selected_map == null:
		print("No map selected to delete.")
		return
	
	var file_path = "user://maps/" + selected_map["name"] + ".json"
	var thumbnail_path = "user://thumbnails/" + selected_map["name"] + ".png"
	
	var dir = DirAccess.open("user://maps")
	if dir and dir.file_exists(file_path):
		dir.remove(file_path)
		print("Deleted map:", selected_map["name"])
	else:
		print("Map file not found:", selected_map["name"])
	
	# Also delete the thumbnail if it exists
	dir = DirAccess.open("user://thumbnails")
	if dir and dir.file_exists(thumbnail_path):
		dir.remove(thumbnail_path)
		print("Deleted thumbnail:", selected_map["name"])
	
	# Refresh the map list after deletion
	load_maps_from_files()


func _on_open_map():
	if selected_map == null:
		print("No map selected!")
		return
		
	print("Opening map:", selected_map["name"])
	
	# Load the Map Editor scene
	var main_scene = load("res://Main.tscn").instantiate()
	
	# Pass the selected map data
	main_scene.set_map_data(selected_map["data"])
	
	# Switch to the Map Editor
	get_tree().root.add_child(main_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = main_scene
	
func _on_create_map_pressed():
	# Load the Map Editor scene
	var map_editor_scene = preload("res://Main.tscn").instance()
	
	# Switch to the Map Editor
	get_tree().root.add_child(map_editor_scene)
	get_tree().current_scene.queue_free()  # Unload the current scene
	get_tree().current_scene = map_editor_scene
	
	# Call the function to initialize a blank map
	map_editor_scene.call("load_new_map")
	print("Switched to Map Editor with a new blank map.")


func _on_create_map_button_pressed():
	# Load the Map Editor scene
	var map_editor_scene = load("res://Main.tscn").instantiate()
	# Switch to the Map Editor
	get_tree().root.add_child(map_editor_scene)
	get_tree().current_scene.queue_free()  # Unload the current scene
	get_tree().current_scene = map_editor_scene
	# Call the function to initialize a blank map
	print("Switched to Map Editor with a new blank map.")



# Load saved maps from files
func load_maps_from_files():
	var dir = DirAccess.open("user://maps")
	if dir == null:
		print("Maps folder does not exist.")
		return
		
	var map_files = dir.get_files()
	map_list.clear()  # Clear previous maps before loading
	
	
	for file_name in map_files:
		if file_name.ends_with(".json"):
			var file_path = "user://maps/" + file_name
			var file = FileAccess.open(file_path, FileAccess.READ)
			
			if file == null:
				print("Error opening map file:", file_path)
				continue
			
			var json_text = file.get_as_text()
			file.close()
			
			var map_data = JSON.parse_string(json_text)
			
			#  Validate JSON before using it
			if typeof(map_data) != TYPE_DICTIONARY or "name" not in map_data:
				print("Error: Invalid JSON format in", file_name)
				continue  # Skip corrupted files
			
			var map_entry = {
				"name": map_data["name"]
			}
			
			
			# Check if thumbnail exists before loading
			if "thumbnail" in map_data and typeof(map_data["thumbnail"]) == TYPE_STRING:
				if FileAccess.file_exists(map_data["thumbnail"]):
					var image = Image.new()
					var err = image.load(map_data["thumbnail"])
					if err == OK:
						var tex = ImageTexture.create_from_image(image)
						map_entry["thumbnail"] = tex
					else:
						print("Error loading thumbnail for", map_data["name"])
						map_entry["thumbnail"] = null  # Handle errors gracefully
				else:
					print("No thumbnail found for", map_data["name"])
					map_entry["thumbnail"] = null
					
				map_list.append(map_entry)  # Append the map entry to the list
			
