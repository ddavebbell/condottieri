extends Node
class_name GlobalMapManager

const MAPS_DIR := "user://maps/"

var grid_manager: Node = null

var current_map
var current_map_name
var piece_manager                # Future State
var trigger_manager


#region GET
func get_map_path(map_name: String) -> String:
	return MAPS_DIR + map_name.to_lower() + ".tres"


func map_exists(map_name: String) -> bool:
	return FileAccess.file_exists(get_map_path(map_name))


func get_all_maps() -> Array:
	var maps: Array[Map] = []
	var dir = DirAccess.open(MAPS_DIR)
	if not dir:
		DirAccess.make_dir_absolute(MAPS_DIR)
		return maps

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path = MAPS_DIR + file_name
			var map_res = ResourceLoader.load(path)
			if map_res == null:
				print("Failed to load:", path)
			elif map_res is Map:
				maps.append(map_res)
			else:
				print("Not a Map resource:", path)
				
		file_name = dir.get_next()
	dir.list_dir_end()
	
	return maps


func load_map(map_name: String):
	var path = MAPS_DIR + map_name.to_lower() + ".tres"
	if not FileAccess.file_exists(path):
		print("❌ Map file not found:", path)
		return

	var map_res = ResourceLoader.load(path)
	if map_res is Map:
		apply_map_resource(map_res)
		print("✅ Map loaded:", map_name)
	else:
		print("❌ Failed to load Map resource:", map_name)


func create_map():
	current_map = Map.new
	return current_map

# loads Map resource and applies it to the game board, using GridManager to place the saved tiles
func apply_map_resource(map: Map):
	if not grid_manager:
		print("❌ ERROR: GridManager is NULL")
		return
	grid_manager.clear_grid()
	for tile_pos in map.tiles.keys():
		grid_manager.set_tile(Vector2i(tile_pos), map.tiles[tile_pos])
	current_map_name = map.name
	print("🗺️ Map applied:", map.name)

#endregion

#region SAVE 
func save_map(map: Map):
	var path = MAPS_DIR + map.name + ".tres"
	var result = ResourceSaver.save(map, path)
	if result != OK:
		print("Failed to save map:", result)
	else:
		print("Map saved to:", path)


func delete_map(map: Map):
	var file_path = MAPS_DIR + map.resource_path.get_file()
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
		print("Deleted map:", file_path)
	else:
		print("Map not found:", file_path)

#endregion



#region Debugging
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
