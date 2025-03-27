extends "res://addons/gut/test.gd"

class_name TestGridManager

var grid_manager
var tile_layer
var base_grid_layer

# Redefining constants from Grid manager. IN THE FUTURE, put constants in an autoload.
const GRID_WIDTH = 12
const GRID_HEIGHT = 12
const CELL_SIZE = 48
const COLOR_1 = Color(0.4, 0.4, 0.4, 1.0)  # grey
const COLOR_2 = Color(0.25, 0.25, 0.25, 1.0)  # Dark grey


func before_each():
	grid_manager = GridManager.new()
	
	# ✅ Manually create and attach the TileMapLayers to simulate scene structure
	base_grid_layer = TileMapLayer.new()
	base_grid_layer.name = "BaseGridLayer"
	
	tile_layer = TileMapLayer.new()
	tile_layer.name = "TileLayer"

	grid_manager.add_child(base_grid_layer)
	grid_manager.add_child(tile_layer)
	
	add_child(grid_manager)


func after_each():
	if base_grid_layer and base_grid_layer.get_children().size() > 0:
		for child in base_grid_layer.get_children():
			child.queue_free()
		await get_tree().process_frame
	
	if grid_manager:
		for child in grid_manager.get_children():
			child.queue_free()
		grid_manager.queue_free()
		await get_tree().process_frame
		


# # # # # # # #


func test_create_grid():
	grid_manager.create_grid(Vector2(GRID_WIDTH, GRID_HEIGHT))  # Create grid using constants
	
	assert_eq(grid_manager.grid_size, Vector2(GRID_WIDTH, GRID_HEIGHT), "Grid should match defined size")
	
		# Clean up
	for child in base_grid_layer.get_children():
		child.queue_free()



func test_clear_grid_manager():
	grid_manager.create_grid(Vector2(GRID_WIDTH, GRID_HEIGHT))  # ✅ Create a 5x5 grid
	grid_manager.clear_grid()  # Clear the grid

	assert_eq(grid_manager.tile_layer.get_used_cells().size(), 0, "TileLayer should have no active grid cells after clearing.")



func test_create_grey_colorrect():
	# Given a size and color
	var test_size = CELL_SIZE
	var test_color = COLOR_1

	# When we call create_grey_colorrect
	var rect = grid_manager.create_grey_colorrect(test_size, test_color)

	# Then it should return a ColorRect
	assert_true(rect is ColorRect, "Expected a ColorRect")

	# And the ColorRect should have the correct size
	assert_eq(rect.size, Vector2(test_size, test_size), "ColorRect size should match the specified size")

	# And the ColorRect should have the correct color
	assert_eq(rect.color, test_color, "ColorRect color should match the specified color")
	
