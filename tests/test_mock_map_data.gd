extends Object

class_name MockMapData 

var file_name: String
var tile_data: Dictionary
var thumbnail: Object
var pieces: Array
var triggers_and_effects: Array
var map_group: String

func _init(data: Dictionary):
	file_name = data.get("file_name", "")
	tile_data = data.get("tile_data", {})
	thumbnail = data.get("thumbnail", null)
	pieces = data.get("pieces", [])
	triggers_and_effects = data.get("triggers_and_effects", [])
	map_group = data.get("map_group", "")
