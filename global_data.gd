extends Node

# List of saved maps: [{"name": "Map 1", "thumbnail": Texture, "data": Dictionary}, ...]
var map_list = []

# Load saved maps from files on startup
func _ready():
	print("Cleaning up old maps...")
	var file_path = "user://maps/MyOldMap.json"
	
	var dir = DirAccess.open("user://maps")
	if dir:
		if dir.file_exists(file_path):
			var result = dir.remove(file_path)  #  Now correctly using an instance
			if result == OK:
				print("Deleted:", file_path)	
			else:
				print("Failed to delete:", file_path)
		else:
			print("File does not exist:", file_path)
	else:
		print("Directory 'user://maps/' does not exist.")
		# Temporary test data (simulating a saved map)
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
func add_map(name: String, thumbnail: Texture, data: Dictionary):
	map_list.append({"name": name, "thumbnail": thumbnail, "data": data})
	save_map_to_file(name, data, thumbnail)

# Retrieve all saved maps
func get_maps() -> Array:
	return map_list

# Save map to a file (including its thumbnail)
func save_map_to_file(name: String, data: Dictionary, thumbnail: Texture):
	var file = FileAccess.open("user://maps/" + name + ".json", FileAccess.WRITE)
	var map_data = {
		"name": name,
		"data": data,
		"thumbnail": thumbnail.get_image().save_png_to_buffer().to_base64()
	}
	file.store_string(JSON.stringify(map_data))
	file.close()
