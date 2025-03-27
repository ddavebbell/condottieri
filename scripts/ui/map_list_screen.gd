extends Control
class_name MapListScreen

signal map_selected(map: Map)


@onready var map_list_panel = $MapListContainer/MapListPanel
@onready var map_thumbnail_panel = $MapThumbnailPanel
@onready var map_thumbnail = $MapThumbnailPanel/MapThumbnail
@onready var create_map_button = $ButtonContainer/CreateMapButton
@onready var delete_map_button = $ButtonContainer/DeleteMapButton
@onready var open_map_button = $ButtonContainer/OpenMapButton

var global_map_manager = GlobalMapManager.new()
var selected_map: Map = null
var selected_button: Button = null


#
## UI Nodes
#@onready var grid_container = null
#@onready var map_list_container = $MapListContainer  # Scrollable container for map list
#@onready var map_thumbnail_panel = $MapThumbnailPanel
#@onready var map_thumbnail = $MapThumbnailPanel/MapThumbnail  # Thumbnail preview
#@onready var create_map_button = $ButtonContainer/CreateMapButton
#@onready var delete_map_button = $ButtonContainer/DeleteMapButton
#@onready var open_map_button = $ButtonContainer/OpenMapButton
#@onready var title_label = $TitleLabel
#@onready var map_list_ui = $MapListContainer/MapListPanel  # Ensure you reference the ItemList node


func _ready():
	create_map_button.connect("pressed", Callable(self, "_on_create_map"))
	delete_map_button.connect("pressed", Callable(self, "_on_delete_map"))
	open_map_button.connect("pressed", Callable(self, "_on_open_map"))
	
	var all_maps = populate_map_list(global_map_manager.get_all_maps())
	#populate_map_list()


func populate_map_list(maps: Array):
	if maps.is_empty():
		print("No saved maps found.")
		return

	if map_list_panel.is_empty():
		print("No saved maps")
		return

	for child in map_list_panel:
		child.queue_free

	for map_resource in maps:
		var button = Button.new()
		button.text = map_resource.name
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 35)
		button.icon = map_resource.thumbnail
		button.expand_icon = true

		button.pressed.connect(func():
			_on_map_selected(map_resource, button)
		)

		var hbox = HBoxContainer.new()
		hbox.add_child(Control.new()) # left spacer
		hbox.add_child(button)
		hbox.add_child(Control.new()) # right spacer
		map_list_panel.add_child(hbox)

	_on_map_selected(maps[0], map_list_panel.get_child(0).get_child(1))


func _on_map_selected(map: Map, button: Button):
	selected_map = map

	if selected_button:
		selected_button.modulate = Color.WHITE
		selected_button.release_focus()

	selected_button = button
	button.modulate = Color(0.8, 0.5, 0.3, 1)
	button.grab_focus()

	map_thumbnail.texture = map.thumbnail
	map_thumbnail.visible = true
	map_thumbnail_panel.visible = true

# FIX THIS
func _on_delete_map():
	if selected_map:
		global_map_manager.delete_map(selected_map)
		populate_map_list(global_map_manager.get_all_maps())


func _on_open_map():
	if not selected_map:
		print("No map selected")
		return

	var editor_scene = preload("res://scenes/MapEditor.tscn").instantiate()
	get_tree().root.add_child(editor_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = editor_scene

	await get_tree().process_frame
	var grid_container = editor_scene.get_node("HSplitContainer/MarginContainer/MainMapDisplay/GridContainer")
	grid_container.load_map(selected_map)


func _on_create_map_button_pressed():
	var map_editor_scene = preload("res://scenes/MapEditor.tscn").instantiate()
	get_tree().root.add_child(map_editor_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = map_editor_scene
	global_map_manager.create_map()



#func generate_error_thumbnail(map_name: String) -> Texture2D:
	#var error_image = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	#error_image.fill(Color(1, 0, 0, 1))  # 🔴 Red background (error indicator)
	#
	#print("⚠️ Generated error thumbnail for:", map_name)
#
	#return ImageTexture.create_from_image(error_image)
#
#
#func _on_map_selected(map_data, clicked_button):
	#selected_map = map_data  # Update selected map
	#print("🟢 Selected Map:", selected_map["name"])
	#
	#if selected_button:
		#selected_button.modulate = Color(1, 1, 1, 1)  # Reset to normal color
		#selected_button.add_theme_color_override("font_color", Color(0.85, 0.65, 0.45))  # ✅ Light Brown text
		#selected_button.release_focus()  # ✅ Remove focus from the old button
		#
	## ✅ Apply Highlight to New Selected Button
	#clicked_button.modulate = Color(0.8, 0.5, 0.3, 1)  # Brown color (RGB: 153, 76, 25)
	#clicked_button.grab_focus()  # ✅ Ensures the button has focus (shows border)
	#selected_button = clicked_button
	#
	## ✅ Store the thumbnail in `selected_map`
	#if map_data.has("thumbnail") and map_data["thumbnail"] is Texture2D:
		#selected_map["thumbnail"] = map_data["thumbnail"]  # ✅ Save for future use
		#map_thumbnail.texture = selected_map["thumbnail"]
		#map_thumbnail.visible = true
	#else:
		#selected_map["thumbnail"] = generate_error_thumbnail(map_data["name"])
		#map_thumbnail.texture = selected_map["thumbnail"]
		#map_thumbnail.visible = true
		#
	## ✅ Ensure panel stays visible
	#map_thumbnail_panel.visible = true
	#
	#print("✅ Updated thumbnail for:", map_data["name"])
#
#
#func _on_delete_map():
	#if selected_map == null:
		#print("No map selected to delete.")
		#return
	#
	#var file_path = "user://maps/" + selected_map["name"] + ".json"
	#var thumbnail_path = "user://thumbnails/" + selected_map["name"] + ".png"
	#
	#var dir = DirAccess.open("user://maps")
	#if dir and dir.file_exists(file_path):
		#dir.remove(file_path)
		#print("🗑️ Deleted map:", selected_map["name"])
	#else:
		#print("❌ Map file not found:", selected_map["name"])
	#
	## Also delete the thumbnail if it exists
	#var thumb_dir = DirAccess.open("user://thumbnails")
	#if thumb_dir and thumb_dir.file_exists(thumbnail_path):
		#thumb_dir.remove(thumbnail_path)
		#print("🗑️ Deleted Thumbnail:", thumbnail_path)
	#else:
		#print("❌ Thumbnail not found:", thumbnail_path)
		#
	#selected_map = null
	#selected_button = null
	#
	#
		#
	#load_maps_from_files()
	#populate_map_list()
	#await get_tree().process_frame  # Ensure UI updates before selection
	#auto_select_first_map()  # Auto-select the first available map
#
#func auto_select_first_map():
	#if map_list.size() > 0:
		#var first_map = map_list[0]
		#var first_map_name = first_map["name"]
		#select_map(first_map_name)  # Select it
		#
		## ✅ Call `_on_map_selected()` instead of just `select_map()`
		#var first_button = get_first_map_button(first_map_name)
		#if first_button:
			#_on_map_selected(first_map, first_button)  # ✅ Ensure UI is updated
		#else:
			#print("❌ Could not find button for auto-selected map")
	#else:
		#reset_thumbnail()  # No maps left, clear thumbnail
#
#func select_map(map_name: String):
	#selected_map = {"name": map_name}  # Store selected map info
#
	## ✅ Update UI elements
	#delete_map_button.disabled = false
	#open_map_button.disabled = false
		#
	#update_thumbnail(map_name)  # Load the correct thumbnail
	#print("✅ Auto-selected map:", map_name)
#
#func get_first_map_button(map_name: String) -> Button:
	#var map_list_panel = $MapListContainer/MapListPanel  # Reference to your VBoxContainer
	#for child in map_list_panel.get_children():
		#if child is HBoxContainer:
			#for sub_child in child.get_children():
				#if sub_child is Button and sub_child.text == map_name:
					#return sub_child  # ✅ Return the button that matches the map name
	#return null
#
#
#
#func reset_thumbnail():
	#print("🔄 Resetting thumbnail.")
	#if map_thumbnail:
		#map_thumbnail.texture = null  # Fully clear the texture
		#map_thumbnail.visible = false  # Hide the UI element
	#if map_thumbnail_panel:
		#map_thumbnail_panel.visible = false  # Hide the whole panel if needed
		#print("🔄 Thumbnail preview fully reset.")
#
#func update_thumbnail(map_name: String):
	## ✅ Try to load from selected_map first
	#if selected_map and selected_map.has("thumbnail") and selected_map["thumbnail"] is Texture2D:
		#print("🟢 Using cached thumbnail for:", map_name)
		#map_thumbnail.texture = selected_map["thumbnail"]
		#map_thumbnail_panel.visible = true
		#map_thumbnail.visible = true
		#return
		#
	#var thumbnail_path = "user://thumbnails/" + map_name + ".png"
	#
	#if FileAccess.file_exists(thumbnail_path):
		#print("❌ Thumbnail file does not exist:", thumbnail_path)
		#reset_thumbnail()
		#return
		#
	#var texture = ImageTexture.new()
	#var image = Image.new()
		#
	#var load_result = image.load(thumbnail_path)
		#
	#if load_result != OK:
		#reset_thumbnail()
		#return
		#
	#texture.create_from_image(image)
	#
	#
	#map_thumbnail.texture = null  # Clear any existing texture
	#await get_tree().process_frame  # Let UI update before setting new texture
	#map_thumbnail.texture = texture
	#map_thumbnail.visible = true  # Ensure the image is visible
	#map_thumbnail_panel.visible = true  # Show panel
	#
	#print("✅ Loaded and displayed thumbnail for:", map_name)
#
#
## needs test
## this instantiates the map editor scene AND loads the map
#func _on_open_map():
	#if selected_map == null:
		#print("❌ No map selected!")
		#return
	#print("📂 _on_open_map :   ", selected_map["name"])
#
	#map_editor_instance = map_editor.instantiate()
	#print("🛠️ Instantiating MapEditor...")
	#get_tree().get_root().add_child(map_editor_instance)
	#await get_tree().process_frame
	#
	#grid_container = map_editor_instance.get_node_or_null("HSplitContainer/MarginContainer/MainMapDisplay/GridContainer")
	#if grid_container:
		#print("✅ Instantiating GridContainer:", grid_container)
	#else:
		#print("❌ ERROR: GridContainer NOT found inside MapEditor!")
		#
	#grid_container.call_deferred("load_map", selected_map["name"])
#
	#get_tree().current_scene.queue_free()
	#get_tree().current_scene = map_editor_instance
#
## needs test
#func _on_create_map_pressed():
	## Load the Map Editor scene
	#var map_editor_scene = preload("res://scenes/MapEditor.tscn").instance()
	#
	## Switch to the Map Editor
	#get_tree().root.add_child(map_editor_scene)
	#get_tree().current_scene.queue_free()  # Unload the current scene
	#get_tree().current_scene = map_editor_scene
	#
	## Call the function to initialize a blank map
	#map_editor_scene.call("load_new_map")
	#print("Switched to Map Editor with a new blank map.")
#
## needs test
#func _on_create_map_button_pressed():
	## Load the Map Editor scene
	#var map_editor_scene = load("res://scenes/MapEditor.tscn").instantiate()
	## Switch to the Map Editor
	#get_tree().root.add_child(map_editor_scene)
	#get_tree().current_scene.queue_free()  # Unload the current scene
	#get_tree().current_scene = map_editor_scene
	## Call the function to initialize a blank map
	#print("Switched to Map Editor with a new blank map.")
#
## needs test
#func load_map(map_name: String):
	#print("📂 Loading map from file:", map_name)
	#
	#var file_path = "user://maps/" + name + ".json"
	#var file = FileAccess.open(file_path, FileAccess.READ)
	#var map_data = JSON.parse_string(file.get_as_text())
	#file.close()
	#
	#if "triggers" in map_data:
		#print("📡 Sending Triggers to Map Editor...")
		#map_editor._load_triggers(map_data["triggers"])
	#
	#_place_tiles_on_grid(map_data)
#
	#print("✅ Map Loaded Successfully!")
#
## needs test
#func _place_tiles_on_grid(json_map_data):
	## ✅ Ensure map_data is valid
	#if not json_map_data or typeof(json_map_data) != TYPE_DICTIONARY:
		#print("❌ ERROR: Invalid map data format!")
		#return
	#
	### clear grid before placing tiles
	#if not grid_container:
		#print("❌ Error: GridContainer not found in Map Editor!")
		#return
	#else:
		#grid_container.clear_grid()  # Clear any previous tiles before loading
	#
	### place tiles from JSON on grid
	#if not json_map_data:
		#print("❌ Error loading map data!")
		#return
	#for key in json_map_data["tiles"].keys():
		#var coords = key.split(",")  # 🔹 Convert JSON key back into Vector2
		#var grid_pos = Vector2(coords[0].to_float(), coords[1].to_float())
		#
		#var tile_data = json_map_data["tiles"][key]
		#
		#var tile_texture: Texture2D
		#if "atlas" in tile_data:
			#var atlas_texture = AtlasTexture.new()
			#atlas_texture.atlas = load(tile_data["atlas"])
			#atlas_texture.region = Rect2(tile_data["region"][0], tile_data["region"][1], tile_data["region"][2], tile_data["region"][3])
			#tile_texture = atlas_texture
		#else:
			#tile_texture = load(tile_data["texture"])
			#
		#grid_container.place_tile(grid_pos, tile_texture)
	#return json_map_data
#
## Load saved maps from files
#func load_maps_from_files():
	#var dir = DirAccess.open("user://maps")
	#if dir == null:
		#print("❌ Maps folder does not exist.")
		#return
		#
	#var map_files = dir.get_files()
	#map_list.clear()  # Clear previous maps before loading
	#
	#
	#for file_name in map_files:
		#if file_name.ends_with(".json"):
			#var file_path = "user://maps/" + file_name
			#var file = FileAccess.open(file_path, FileAccess.READ)
			#
			#if file == null:
				#print("❌ Error opening map file:", file_path)
				#continue
			#
			#var json_text = file.get_as_text()
			#file.close()
			#var map_data = JSON.parse_string(json_text)
			#
			##  Validate JSON before using it
			#if typeof(map_data) != TYPE_DICTIONARY or "name" not in map_data:
				#print("❌ Error: Invalid JSON format in", file_name)
				#continue  # Skip corrupted files
			#
			#var map_entry = { "name": map_data["name"] }
			#
			 ##✅ Check if thumbnail exists before loading
			#var thumbnail_path = "user://thumbnails/" + map_data["name"] + ".png"
			#if FileAccess.file_exists(thumbnail_path):
				#var image = Image.new()
				#if image.load(thumbnail_path) == OK:
					#map_entry["thumbnail"] = ImageTexture.create_from_image(image)
				#else:
					#print("❌ Error loading thumbnail for", map_data["name"])
					#map_entry["thumbnail"] = null  # Handle errors gracefully
			#else:
				#print("No thumbnail found for", map_data["name"])
				#map_entry["thumbnail"] = null
				#
			#map_list.append(map_entry)  # Append the map entry to the list
			#
	#print("✅ Maps loaded:", map_list)
#
#
#func clear_map_cache():
	#var map_dir = DirAccess.open("user://maps")
	#if map_dir:
		#for file in map_dir.get_files():
			#var file_path = "user://maps/" + file
			#map_dir.remove(file_path)
			#print("🗑️ Deleted map file:", file_path)
	#else:
		#print("❌ Failed to access map directory.")
		#
	#var thumb_dir = DirAccess.open("user://thumbnails")
	#if thumb_dir:
		#for file in thumb_dir.get_files():
			#var file_path = "user://thumbnails/" + file
			#thumb_dir.remove(file_path)
			#print("🗑️ Deleted thumbnail file:", file_path)
	#else:
		#print("❌ Failed to access thumbnail directory.")
		#
## ✅ Reset in-memory map list
	#var current_filename: String = ""  # Tracks the current map file name
	#print("🧹 Cleared all cached maps and thumbnails.")
	#
	#get_tree().root.call_deferred("emit_signal", "map_list_updated")
