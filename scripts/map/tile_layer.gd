extends TileMapLayer

class_name TileGrid

var grid_manager: GridManager

var tile_size: int = 32  # Define tile size to prevent undefined errors
var selected_tile_type: int = -1  # Store selected tile ID instead of a string

var tile_data = {}  # Stores all tile placements
var tile_layer: TileGrid = null

func _ready():
	grid_manager = get_tree().get_first_node_in_group("GridManager")


func tile_layer_place_tile(grid_position: Vector2i, tile_type: int):
	pass

# Fetch all active tiles in a structured dictionary
func get_tile_data() -> Dictionary:
	return tile_data


func clear_grid():
	for cell: Vector2i in get_used_cells():  # ✅ Ensure `cell` is `Vector2i`
		erase_cell(cell)  # ✅ Removes tile from the tilemap layer


#func set_tile_layer(current_tile_layer: TileGrid):
	#if current_tile_layer == null:
		#print("❌ ERROR: Trying to set NULL TileLayer!")
		#return
	#tile_layer = current_tile_layer
	#print("✅ TileLayer set:", tile_layer)


#func get_current_tile_data():
	#if tile_layer == null:
		#print("❌ ERROR: TileLayer is NULL")
		#return null
	#return tile_layer.get_tile_data()
	## change to grid_manager.get_tile_layer().get_tile_data()????
