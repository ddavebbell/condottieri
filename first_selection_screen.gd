extends Control

# Placeholder for the list of maps (Now loaded from GlobalData)
var map_list = []
var selected_map = null  # Store selected map globally
var selected_button = null  # Store selected button reference

# UI Nodes
@onready var map_list_container = $MapListContainer  # Scrollable container for map list
@onready var map_thumbnail = $MapThumbnailPanel/MapThumbnail  # Thumbnail preview
@onready var create_map_button = $ButtonContainer/CreateMapButton
@onready var delete_map_button = $ButtonContainer/DeleteMapButton
@onready var open_map_button = $ButtonContainer/OpenMapButton
@onready var title_label = $TitleLabel
@onready var map_thumbnail_panel = $MapThumbnailPanel



func _ready():
	load_maps_from_files()  # Load saved maps on startup
	var map_list_panel = $MapListContainer/MapListPanel
	if map_list_panel:
		map_list_panel.visible = true  # ✅ Ensure the panel is visible at startup
		
	# Connect button signals
	create_map_button.connect("pressed", Callable(self, "_on_create_map"))
	delete_map_button.connect("pressed", Callable(self, "_on_delete_map"))
	open_map_button.connect("pressed", Callable(self, "_on_open_map"))
	
	# Populate the map list from GlobalData
	_populate_map_list()

func _populate_map_list():
	var map_list_panel = $MapListContainer/MapListPanel  # ✅ Get VBoxContainer
	map_list_panel.visible = true  # ✅ Keep it visible even when empty
	
	for child in map_list_panel.get_children():
		child.queue_free()
	
	if map_list.size() == 0:
		print("❌ No saved maps found.")
		return
		
	var first_button = null  # Store first button reference
		
	# Setting Button Style/Theme
	var custom_font = load("res://BLACKCASTLEMF.TTF")  # Load custom font
	var map_list_theme = Theme.new()  # Create a new theme
	map_list_theme.set_font("font", "Button", custom_font)  # Assign font
	map_list_theme.set_constant("font_size", "Button", 24)  # Force font size
	
	# ✅ Use MarginContainer for precise control over padding
	var top_margin_container = MarginContainer.new()
	top_margin_container.add_theme_constant_override("margin_top", 10)
	map_list_panel.add_child(top_margin_container)
	
	for map_data in map_list:
		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# ✅ Create a Spacer for Top Margin
		var top_spacer = Control.new()
		top_spacer.size_flags_vertical = Control.SIZE_SHRINK_BEGIN 
		map_list_panel.add_child(top_spacer)  # ✅ Add spacer to VBoxContainer
		
		var left_spacer = Control.new() # ✅ Create a spacer to add left margin
		left_spacer.custom_minimum_size = Vector2(15, 0)
		
		var button = Button.new()
		button.theme = map_list_theme
		button.text = map_data["name"]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL 
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER  
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 35)  # Prevents overlap by setting height
		
		button.connect("pressed", Callable(self, "_on_map_selected").bind(map_data, button))
		
		
		var right_spacer = Control.new() # ✅ Create a spacer to add right margin
		right_spacer.custom_minimum_size = Vector2(15, 0)  # ✅ Set right margin
		
		# ✅ Add everything to HBoxContainer
		hbox.add_child(left_spacer)  # Left margin
		hbox.add_child(button)  # Button in the center
		hbox.add_child(right_spacer)  # Right margin
		
		map_list_panel.add_child(hbox) # Add to VBoxContainer
		
		if first_button == null:
			first_button = button  # Store first button for auto-selection
		
		# Select the first map by default
	if first_button:
		_on_map_selected(map_list[0], first_button)

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





func _on_map_selected(map_data, clicked_button):
	selected_map = map_data  # Update selected map
	print("🟢 Selected Map:", selected_map["name"])
	
	if selected_button:
		selected_button.modulate = Color(1, 1, 1, 1)  # Reset to normal color
		selected_button.add_theme_color_override("font_color", Color(0.85, 0.65, 0.45))  # ✅ Light Brown text
		selected_button.release_focus()  # ✅ Remove focus from the old button
		
	# ✅ Apply Highlight to New Selected Button
	clicked_button.modulate = Color(0.8, 0.5, 0.3, 1)  # Brown color (RGB: 153, 76, 25)
	clicked_button.grab_focus()  # ✅ Ensures the button has focus (shows border)
	selected_button = clicked_button
	
	
	
	if map_data.has("thumbnail") and map_data["thumbnail"] is Texture2D:
		map_thumbnail.texture = map_data["thumbnail"]  # ✅ Update the separate panel
	else:
		map_thumbnail.texture = generate_error_thumbnail(map_data["name"])  # ✅ Use error image

	map_thumbnail_panel.visible = true  # ✅ Make sure it's visible
	print("✅ Updated thumbnail for:", map_data["name"])
	

func _on_delete_map():
	if selected_map == null:
		print("No map selected to delete.")
		return
	
	var file_path = "user://maps/" + selected_map["name"] + ".json"
	var thumbnail_path = "user://thumbnails/" + selected_map["name"] + ".png"
	
	var dir = DirAccess.open("user://maps")
	if dir and dir.file_exists(file_path):
		dir.remove(file_path)
		print("🗑️ Deleted map:", selected_map["name"])
	else:
		print("❌ Map file not found:", selected_map["name"])
	
	
	# Also delete the thumbnail if it exists
	var thumb_dir = DirAccess.open("user://thumbnails")
	if thumb_dir and thumb_dir.file_exists(thumbnail_path):
		thumb_dir.remove(thumbnail_path)
		print("🗑️ Deleted Thumbnail:", thumbnail_path)
	else:
		print("❌ Thumbnail not found:", thumbnail_path)
		
		
	# ✅ Reset Thumbnail Container (Hides Previous Map Thumbnail)
	map_thumbnail.visible = false  # Hide the thumbnail preview
	
	# Refresh the map list after deletion
	selected_map = null
	delete_map_button.disabled = true
	open_map_button.disabled = true
	
	load_maps_from_files()
	_populate_map_list()


func _on_open_map():
	if selected_map == null:
		print("❌ No map selected!")
		return
		
	print("🟢 Opening map:", selected_map["name"])
	
	# Load the Map Editor scene
	var map_editor_scene = load("res://map_editor_screen.tscn").instantiate()
	get_tree().root.add_child(map_editor_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = map_editor_scene
	
	var grid_container = map_editor_scene.get_node_or_null("HSplitContainer/MarginContainer/MainMapDisplay/GridContainer")
	if grid_container == null:
		print("❌ ERROR: GridContainer not found inside map_editor_scene!")
		return
		
	print("✅ GridContainer found. Calling load_map()...")
	
	grid_container.call_deferred("load_map", selected_map["name"])
	
	
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


func load_map(map_name: String):
	print("🟢 Loading Map:", map_name)

	var file_path = "user://maps/" + map_name + ".json"
	if not FileAccess.file_exists(file_path):
		print("❌ Map file does not exist:", file_path)
		return
		
	# ✅ Load JSON Data
	var file = FileAccess.open(file_path, FileAccess.READ)
	var map_data = JSON.parse_string(file.get_as_text())
	file.close()

	if map_data == null:
		print("❌ Error loading map data!")
		return
		
	# ✅ Find `GridContainer` in the current scene
	var grid_container = $HSplitContainer/MarginContainer/MainMapDisplay/GridContainer  # Adjust path if necessary
	if grid_container == null:
		print("❌ Error: GridContainer not found in Map Editor!")
		return
		
	print("✅ Grid container found. Clearing grid...")
	grid_container.clear_grid()  # Clear any previous tiles before loading
		
	# ✅ Place Tiles on Grid
	for key in map_data["tiles"].keys():
		var coords = key.split(",")  # 🔹 Convert JSON key back into Vector2
		var grid_pos = Vector2(coords[0].to_float(), coords[1].to_float())
		
		var tile_data = map_data["tiles"][key]
		
		var tile_texture: Texture2D
		if "atlas" in tile_data:
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = load(tile_data["atlas"])
			atlas_texture.region = Rect2(tile_data["region"][0], tile_data["region"][1], tile_data["region"][2], tile_data["region"][3])
			tile_texture = atlas_texture
		else:
			tile_texture = load(tile_data["texture"])
			
		grid_container.place_tile(grid_pos, tile_texture)
		
		print("✅ Placed tile at:", grid_pos)
	print("✅ Map Loaded Successfully!")



# Load saved maps from files
func load_maps_from_files():
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
