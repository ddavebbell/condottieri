extends Node

# Responsible for accepting button pressed functions (requests) from MapEditorScreenUI and MapListScreenUI
# contains functions to process Map data: GET (load data), SET (save data), varify functions, helper functions
# Transfers data --> is unaware of UI

#region Variables

const MAPS_DIR := "user://maps/"

var grid_manager: Node = null
var open_context: String = ""

var current_map: Map = null
var _is_saved: bool = false


#endregion


func _on_new_map_requested():
	create_map()


func _on_open_map_requested():
	# tell map_list_screen it is open map context
	pass

func _on_save_map_requested():
	# just saves the map but no popup
	pass

func _on_save_as_map_requested():
	# save map popup spawns
	pass

func create_map():
	current_map = Map.new()
	_is_saved = false
	current_map["name"] = "Unsaved Map"
	return current_map


func load_selected_map(map: Map) -> void:
	if map == null:
		push_error("❌ No map passed to load_selected_map()")
		return

	current_map = map
	#apply_map_resource(map)  # Optional: do any setup/preprocessing here
	print("✅ Map loaded into MapManager:", map.name)



func get_is_saved_status():
	return _is_saved


func get_current_map():
	return current_map


func get_map_path(map_name: String) -> String:
	return MAPS_DIR + map_name.to_lower() + ".tres"


func get_saved_map_files() -> Array:
	var map_files := []
	var maps_path := ProjectSettings.globalize_path(MAPS_DIR)
	var dir := DirAccess.open(maps_path)
	
	if dir == null:
		push_error("Failed to open maps directory")
		return map_files

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			map_files.append(file_name)
		file_name = dir.get_next()

	dir.list_dir_end()
	print("map_files in get_saved_map_files method:  ", map_files)
	return map_files



#func map_exists(map_name: String) -> bool:
	#return FileAccess.file_exists(get_map_path(map_name))


func set_current_map(map: Map):
	current_map = map
	print("🧭 Current map set to:", current_map.name)


# loads Map resource and applies it to the game board, using GridManager to place the saved tiles
func apply_map_resource(map: Map):
	if not grid_manager:
		print("❌ ERROR: GridManager is NULL")
		return
	grid_manager.clear_grid()
	for tile_pos in map.tiles.keys():
		grid_manager.set_tile(Vector2i(tile_pos), map.tiles[tile_pos])
	print("🗺️ Map applied:", map.name)

#endregion


func save_map() -> void:
	if current_map == null:
		push_error("❌ No current map to save.")
		return

	if current_map.name.is_empty():
		push_error("❌ Map must have a name before saving.")
		return

	var file_name := current_map.name
	if not file_name.ends_with(".condomap"):
		file_name += ".condomap"

	current_map.created_date = Time.get_datetime_string_from_system()

	var full_path := "user://maps/" + file_name
	var result := ResourceSaver.save(current_map, full_path)

	if result == OK:
		print("✅ Map saved to:", full_path)
	else:
		push_error("❌ Failed to save map to: " + full_path)


func save_current_map_metadata_to_file(file_name: String, name: String, description: String, thumbnail: Texture2D, version: int = 1) -> void:
	if current_map == null:
		push_error("❌ No current map loaded to save.")
		return

	if not file_name.ends_with(".condomap"):
		file_name += ".condomap"

	# Update current_map's metadata from UI
	current_map.name = name
	current_map.description = description
	current_map.thumbnail = thumbnail
	current_map.version = version
	current_map.created_date = Time.get_datetime_string_from_system()

	#current_map.tiles = GridManager.get_tiles()						# later to add
	#current_map.board_events = BoardEventManager.serialize_events()
	#current_map.pieces = PieceManager.serialize_pieces()

	# Save to file
	var full_path := "user://maps/" + file_name
	var result := ResourceSaver.save(current_map, full_path)

	if result == OK:
		print("✅ Map saved successfully to:", full_path)
	else:
		push_error("❌ Failed to save map to: " + full_path)



# Delete map -> Not having this functionality yet
#func delete_map(file_name: String) -> void:
	#if not file_name.ends_with(".condomap"):
		#file_name += ".condomap"
#
	#var full_path := "user://maps/" + file_name
	#var full_path_absolute := ProjectSettings.globalize_path(full_path)
#
	#if not FileAccess.file_exists(full_path):
		#push_warning("⚠️ File not found: " + full_path)
		#return
#
	#var err := DirAccess.remove_absolute(full_path_absolute)
	#if err == OK:
		#print("🗑️ Map deleted:", full_path)
	#else:
		#push_error("❌ Failed to delete map file: " + full_path)


#region Debugging


func create_test_maps(count: int = 5) -> void:
	var maps_path := ProjectSettings.globalize_path(MAPS_DIR)

	if not DirAccess.dir_exists_absolute(maps_path):
		var err := DirAccess.make_dir_recursive_absolute(maps_path)
		if err != OK:
			push_error("❌ Could not create maps directory.")
			return

	for i in count:
		var test_map = Map.new()
		test_map.name = "Test Map %d" % i
		test_map.description = "This is test map #%d" % i
		test_map.version = 1
		test_map.created_date = Time.get_datetime_string_from_system()

		# Dummy tags
		var tag_pool = [
			["Test", "Tiny", "Debug"],
			["Desert", "PvE", "Challenge"],
			["Forest", "Classic", "Story"],
			["Ice", "Hard", "Featured"],
			["WIP", "Multiplayer", "Beta"]
		]
		
		var raw_tags = tag_pool[i % tag_pool.size()]
		var tags := []
		for tag in raw_tags:
			tags.append(str(tag))  # ensures string type
		test_map.tags = tags

		# Dummy thumbnail
		var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		image.fill(Color(0.4 + 0.1 * i, 0.6 - 0.1 * i, 0.9))  # Vary color slightly per map
		var texture := ImageTexture.create_from_image(image)
		test_map.thumbnail = texture

		# Save the map
		var file_name := "test_map_%d.tres" % i
		var full_path := MAPS_DIR + "/" + file_name

		var result := ResourceSaver.save(
			test_map,
			full_path,
			ResourceSaver.FLAG_CHANGE_PATH | ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS | ResourceSaver.FLAG_RELATIVE_PATHS
		)
		if result == OK:
			print("✅ Test map saved:", full_path)
		else:
			push_error("❌ Failed to save test map:", full_path)


func debug_saved_maps():
	var dir = DirAccess.open(MAPS_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var loaded = []
		while file_name != "":
			if file_name.ends_with(".tres"):
				loaded.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		print("✅ Maps found:", loaded)
	else:
		print("❌ Could not open maps directory.")


func delete_saved_maps():
	var dir = DirAccess.open(MAPS_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				DirAccess.remove_absolute(MAPS_DIR + file_name)
				print("Deleted:", file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("❌ Could not open maps directory.")

#endregion
