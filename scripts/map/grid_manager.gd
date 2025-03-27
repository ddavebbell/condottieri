extends Node2D

class_name GridManager

@onready var base_grid_layer = $BaseGridLayer  # Grid visual layer
@onready var tile_layer = $TileLayer  # Tile placement layer

var grid_size: Vector2 = Vector2(12, 12)  # Default grid size

# Grid configuration
const GRID_WIDTH = 12  # Number of squares across
const GRID_HEIGHT = 12  # Number of squares down
const CELL_SIZE = 48  # Size of each square (adjust as needed)
const COLOR_1 = Color(0.4, 0.4, 0.4, 1.0)  # grey
const COLOR_2 = Color(0.25, 0.25, 0.25, 1.0)  # Dark grey

func _ready():
	create_grid(grid_size)


func create_grid(size: Vector2):
	grid_size = size  # Store the grid size
	clear_grid()

	var base_rect = create_grey_colorrect()
	
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var cloned_rect = base_rect.duplicate() as ColorRect
			# Use if/else instead of the ternary operator
			if (x + y) % 2 == 0:
				cloned_rect.color = COLOR_1
			else:
				cloned_rect.color = COLOR_2
				
			cloned_rect.position = Vector2(x * CELL_SIZE, y * CELL_SIZE)
			base_grid_layer.add_child(cloned_rect)


func clear_grid():
	# First, remove all children in the base grid layer
	for child in base_grid_layer.get_children():
		child.queue_free()
	
	# Then, clear all cells from both layers
	for layer in [base_grid_layer, tile_layer]:  # Loop through both layers
		for cell in layer.get_used_cells():  # No arguments needed in Godot 4
			layer.erase_cell(cell)  # Only needs `Vector2i` position


# Retrieve tile data from TileLayer
func get_current_map_data() -> Dictionary:
	if not tile_layer:
		print("❌ ERROR: `TileLayer` not found in `GridManager`!")
		return {}

	return tile_layer.get_tile_data()  # ✅ Fetches data from TileMap


func grid_manager_place_tile(grid_position: Vector2i, tile_type: int) -> void:
	if tile_layer:
		tile_layer.tile_layer_place_tile(grid_position, tile_type)  # ✅ Forward request
		print("✅ GridManager: Tile placed at", grid_position, "with type", tile_type)
	else:
		print("❌ ERROR: TileLayer not found in GridManager!")


# # # # Helper Function # # # # 

func create_grey_colorrect(size: int = CELL_SIZE, color: Color = Color(0.7, 0.7, 0.7, 1.0)) -> ColorRect:
	# Check for valid size
	if size <= 0:
		push_error("❌ Invalid size passed to create_grey_colorrect. Size must be greater than 0.")
		return null

	# Create a ColorRect
	var rect = ColorRect.new()
	rect.size = Vector2(size, size)
	rect.color = color

	return rect
