extends "res://addons/gut/test.gd"

class_name TestTileLayer

var grid
var grid_manager 
var map_manager 


func before_each():
	# Create a new TileGrid instance before each test
	grid = TileGrid.new()
	add_child(grid)
	map_manager = GlobalMapManager
	

func after_each():
	if grid:
		grid.queue_free()
		await get_tree().process_frame  # Ensure cleanup
		grid = null
	
	if grid_manager:
		grid_manager.queue_free()
		await get_tree().process_frame  # Ensure cleanup
		grid_manager = null
	map_manager = null


# # # # # # # #


#func test_place_tile():
	#pass



#func test_clear_grid():
	#grid.selected_tile_type = 1  # Set a test tile ID
	#grid.tile_layer_place_tile(Vector2i(0, 0),1)  # Place tile
#
	#assert_eq(grid.get_used_cells().size(), 1, "TileGrid should contain one placed tile before clearing.")
#
	#grid.clear_grid()  # Clear the tile grid
#
	#assert_eq(grid.get_used_cells().size(), 0, "TileGrid should have no placed tiles after clearing.")
