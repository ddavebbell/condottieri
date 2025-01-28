extends Node

# A list to store saved maps
var saved_maps = []  # Example: [{"name": "Map 1", "thumbnail": Texture, "data": PackedScene}, ...]


func add_map(name: String, thumbnail: Texture, data: Dictionary):
	saved_maps.append({"name": name, "thumbnail": thumbnail, "data": data})

func get_maps() -> Array:
	return saved_maps
