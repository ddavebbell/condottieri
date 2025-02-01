extends Control

# Placeholder for the list of maps (Now loaded from GlobalData)
var map_list = []
var selected_map = null  # Store selected map globally


# UI Nodes
@onready var map_list_container = $MapListContainer  # Scrollable container for map list
@onready var map_thumbnail = $MapThumbnailPanel/MapThumbnail  # Thumbnail preview
@onready var create_map_button = $ButtonContainer/CreateMapButton
@onready var delete_map_button = $ButtonContainer/DeleteMapButton
@onready var open_map_button = $ButtonContainer/OpenMapButton
@onready var title_label = $TitleLabel
@onready var map_thumbnail_panel = $MapThumbnailPanel


func _ready():
	
	map_thumbnail_panel.visible = false  # ✅ Hide panel until selection
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
	var custom_font = load("res://BLACKCASTLEMF.TTF")  # ✅ Load custom font
	var theme = Theme.new()  # ✅ Create a new theme
	theme.set_font("font", "Button", custom_font)  # ✅ Assign font
	theme.set_constant("font_size", "Button", 24)  # ✅ Force font size
	
	for map_data in map_list:
		var button = Button.new()
		button.text = map_data["name"]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL # ✅ Stretch Button to Fill the Container
		
		button.theme = theme
		
		
		button.connect("pressed", Callable(self, "_on_map_selected").bind(map_data))
		map_list_container.add_child(button)
		
		


func generate_error_thumbnail(map_name: String) -> Texture2D:
	var error_image = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	error_image.fill(Color(1, 0, 0, 1))  # 🔴 Red background (error indicator)
		
	var font = ThemeDB.fallback_font  # Get a default font
	var text_position = Vector2(30, 120)  # Center-ish placement

	error_image.lock()
	error_image.draw_string(font, text_position, "ERROR", Color(1, 1, 1, 1), 24)
	error_image.unlock()

	print("⚠️ Generated error thumbnail for:", map_name)

	return ImageTexture.create_from_image(error_image)





func _on_map_selected(map_data):
	# Display the selected map's thumbnail
	selected_map = map_data  # ✅ Store selected map
	
	if map_data.has("thumbnail") and map_data["thumbnail"] is Texture2D:
		map_thumbnail.texture = map_data["thumbnail"]  # ✅ Update the separate panel
	else:
		map_thumbnail.texture = generate_error_thumbnail(map_data["name"])  # ✅ Use error image

	map_thumbnail_panel.visible = true  # ✅ Make sure it's visible
	print("✅ Updated thumbnail for:", map_data["name"])
	

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
	var main_scene = load("res://map_editor_screen.tscn").instantiate()
	
	# Pass the selected map data
	main_scene.set_map_data(selected_map["data"])
	
	# Switch to the Map Editor
	get_tree().root.add_child(main_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = main_scene
	
func _on_create_map_pressed():
	# Load the Map Editor scene
	var map_editor_scene = preload("res://map_editor_screen.tscn").instance()
	
	# Switch to the Map Editor
	get_tree().root.add_child(map_editor_scene)
	get_tree().current_scene.queue_free()  # Unload the current scene
	get_tree().current_scene = map_editor_scene
	
	# Call the function to initialize a blank map
	map_editor_scene.call("load_new_map")
	print("Switched to Map Editor with a new blank map.")


func _on_create_map_button_pressed():
	# Load the Map Editor scene
	var map_editor_scene = load("res://map_editor_screen.tscn").instantiate()
	# Switch to the Map Editor
	get_tree().root.add_child(map_editor_scene)
	get_tree().current_scene.queue_free()  # Unload the current scene
	get_tree().current_scene = map_editor_scene
	# Call the function to initialize a blank map
	print("Switched to Map Editor with a new blank map.")



# Load saved maps from files
func load_maps_from_files():
	print("Loading maps from files...")

	var dir = DirAccess.open("user://maps")
	if dir == null:
		print("❌ Maps folder does not exist.")
		return
		
	var map_files = dir.get_files()
	map_list.clear()  # Clear previous maps before loading
	
	
	for file_name in map_files:
		if file_name.ends_with(".json"):
			var file_path = "user://maps/" + file_name
			var file = FileAccess.open(file_path, FileAccess.READ)
			
			if file == null:
				print("❌ Error opening map file:", file_path)
				continue
			
			var json_text = file.get_as_text()
			file.close()
			var map_data = JSON.parse_string(json_text)
			
			#  Validate JSON before using it
			if typeof(map_data) != TYPE_DICTIONARY or "name" not in map_data:
				print("❌ Error: Invalid JSON format in", file_name)
				continue  # Skip corrupted files
			
			var map_entry = { "name": map_data["name"] }
			
			 #✅ Check if thumbnail exists before loading
			var thumbnail_path = "user://thumbnails/" + map_data["name"] + ".png"
			if FileAccess.file_exists(thumbnail_path):
				var image = Image.new()
				if image.load(thumbnail_path) == OK:
					map_entry["thumbnail"] = ImageTexture.create_from_image(image)
					print("✅ Loaded thumbnail for:", map_data["name"])
				else:
					print("❌ Error loading thumbnail for", map_data["name"])
					map_entry["thumbnail"] = null  # Handle errors gracefully
			else:
				print("No thumbnail found for", map_data["name"])
				map_entry["thumbnail"] = null
				
			map_list.append(map_entry)  # Append the map entry to the list
			
		print("✅ Maps loaded:", map_list)


func delete_all_maps():
	print("Deleting all saved maps...")
	
	# ✅ Open the "maps" directory
	var dir = DirAccess.open("user://maps")
	if dir:
		var files = dir.get_files()
		for file_name in files:
			if file_name.ends_with(".json"):  # ✅ Only delete JSON files
				var file_path = "user://maps/" + file_name
				dir.remove(file_path)
				print("Deleted map file:", file_name)
		
	# ✅ Open the "thumbnails" directory (if using separate thumbnail storage)
	var thumb_dir = DirAccess.open("user://thumbnails")
	if thumb_dir:
		var thumb_files = thumb_dir.get_files()
		for thumb_file in thumb_files:
			if thumb_file.ends_with(".png"):  # ✅ Only delete PNG thumbnails
				var thumb_path = "user://thumbnails/" + thumb_file
				thumb_dir.remove(thumb_path)
				print("Deleted thumbnail:", thumb_file)
				
	# ✅ Clear the map list
	map_list.clear()
	print("Cleared map_list variable.")
	
	# ✅ Refresh UI by reloading maps (this will show an empty list)
	load_maps_from_files()
	
	print("All maps deleted.")
	


func _on_delete_all_button_temp_pressed() -> void:
	delete_all_maps()
