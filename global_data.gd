extends Node

# List of saved maps: [{"name": "Map 1", "thumbnail": Texture, "data": Dictionary}, ...]
var map_list = []

# Load saved maps from files on startup
func _ready():
	var dir_path = "user://maps"
	
	var dir = DirAccess.open("user://")
	if not dir.dir_exists(dir_path):
		print("❌ Directory does not exist, creating:", dir_path)
		dir.make_dir_recursive(dir_path)  # ✅ Create directory if missing
	else:
		print("✅ Directory exists:", dir_path)
	
	# ✅ List files inside the "maps" folder (for debugging)
	dir = DirAccess.open(dir_path)
	if dir == null:
		print("❌ Failed to open directory:", dir_path)
		return
		
	print("📁 Checking files in:", dir_path)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var found_files = false  # ✅ Track if any files exist
	
	while file_name != "":
		if file_name.ends_with(".json"):
			print("📄 Found saved map:", file_name)
			found_files = true
		file_name = dir.get_next()
		
		
	# ✅ Test data (if no maps exist)
	if not found_files:
		print("⚠ No saved maps found inside", dir_path, ". Using test data.")
		map_list = [
			{
				"name": "Test Map", 
				#"thumbnail": preload("res://test_thumbnail.png"), # Placeholder thumbnail
				"thumbnail": null,
				"data": { 
					Vector2(2, 3): "res://tile_texture.png", 
					Vector2(4, 5): "res://tile_texture.png" 
					}
			}
		]

# Add a new map entry
func add_map(map_name: String, thumbnail: Texture, data: Dictionary):
	map_list.append({"name": map_name, "thumbnail": thumbnail, "data": data})
	save_map_to_file(map_name, data, thumbnail)

# Retrieve all saved maps
func get_maps() -> Array:
	return map_list

# Save map to a file (including its thumbnail)
func save_map_to_file(map_name: String, data: Dictionary, thumbnail: Texture):
	var file = FileAccess.open("user://maps/" + map_name + ".json", FileAccess.WRITE)
	var map_data = {
		"name": map_name,
		"data": data,
		"thumbnail": thumbnail.get_image().save_png_to_buffer().to_base64()
	}
	file.store_string(JSON.stringify(map_data))
	file.close()
