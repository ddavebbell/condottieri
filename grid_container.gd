extends Control

const GRID_SIZE = 48
const GRID_WIDTH = 14
const GRID_HEIGHT = 14

var placed_tiles = {}
var grid_offset = Vector2.ZERO # store the centered position
@onready var margin_container = get_parent().get_parent()  # Adjust based on hierarchy


func _ready():
	position = Vector2.ZERO # ensure no initial offsets
	
	call_deferred("calculate_grid_offset")
	connect("resized", Callable(self, "on_resized"))
	
	

func _process(_delta):
	print("GridContainer position:", position, "Parent(MainMapDisplay) global position:", get_parent().global_position, 
	"Grid offset:", grid_offset, 
	"Parent size:", get_parent().size)

#func calculate_grid_offset():
	#grid_offset = grid_container.rect_global_position grid_container.rect_size / 2


func _draw():
	var grid_color = Color(0.3, 0.3, 0.3, 0.8)
	
	for x in range(GRID_WIDTH + 1):
		draw_line(
			grid_offset + Vector2(x * GRID_SIZE, 0), 
			grid_offset + Vector2(x * GRID_SIZE, GRID_HEIGHT * GRID_SIZE),
			grid_color
			)
	for y in range(GRID_HEIGHT + 1):
		draw_line(
			grid_offset + Vector2(0, y * GRID_SIZE), 
			grid_offset + Vector2(GRID_WIDTH * GRID_SIZE, y * GRID_SIZE), 
			grid_color
			)


func calculate_grid_offset():
	var parent = get_parent() # Get the parent MainMapDisplay
	
	if parent:
		#await get_tree().process_frame  # Wait for layout update to finish
		var parent_size = parent.size  
		# Get MainMapDisplay's actual size
		var grid_total_size = Vector2(GRID_WIDTH * GRID_SIZE, GRID_HEIGHT * GRID_SIZE)
		
		print("Calculating Grid Offset...")
		print("Parent size:", parent_size)
		print("Grid total size:", grid_total_size)
		print("Computed Grid Offset:", grid_offset)
		
		# Calculate the centered position within the parent container
		position = grid_offset 
		
		print("Parent size:", parent_size, "Grid centered at offset:", grid_offset, "GridContainer position:", position)
		update_tile_positions()
		queue_redraw()



func _can_drop_data(_pos, _data) -> bool:
	return true  # Allow all drops for now


func _drop_data(pos: Vector2, data: Variant):
	var local_pos = pos - global_position # convert to local space
	var adjusted_pos = local_pos - grid_offset # Correct for grid offset
	var grid_pos = snap_to_grid(adjusted_pos)
	
	print("Dropping tile...")
	print("Mouse Drop Position (Global):", pos)
	print("Converted Local Position:", local_pos)
	print("Adjusted Position (Grid Offset Removed):", adjusted_pos)
	print("Final Grid Position:", grid_pos)
	print("Expected Pixel Position:", grid_to_pixel(grid_pos))
	
	
	
	if is_within_grid(grid_pos) and not is_tile_occupied(grid_pos):
		place_tile(grid_pos, data["texture"])
		print("Tile successfully placed at:", grid_pos, 
			  "Actual pixel position:", grid_to_pixel(grid_pos))
	else:
		print("Invalid placement at:", grid_pos, "Adjusted Pos:", adjusted_pos)


func snap_to_grid(pos: Vector2) -> Vector2:
	var adjusted_pos = pos - grid_offset
	
	print("Snapping to grid...")
	print("Raw Position Input:", pos)
	print("Adjusted Position After Offset:", adjusted_pos)
	
	return Vector2(
		floor(adjusted_pos.x / GRID_SIZE),
		floor(adjusted_pos.y / GRID_SIZE)
		)


func grid_to_pixel(grid_pos: Vector2) -> Vector2:
	var pixel_pos = Vector2(
		grid_pos.x * GRID_SIZE + grid_offset.x, 
		grid_pos.y * GRID_SIZE + grid_offset.y
	)
	
	print("Converting grid to pixel...")
	print("Grid Position:", grid_pos)
	print("Converted Pixel Position:", pixel_pos)
	return pixel_pos

func is_within_grid(grid_pos: Vector2) -> bool:
	return grid_pos.x >= 0 and grid_pos.y >= 0 and \
	grid_pos.x < GRID_WIDTH and \
	grid_pos.y < GRID_HEIGHT

func is_tile_occupied(grid_pos: Vector2) -> bool:
	return grid_pos in placed_tiles

func place_tile(grid_pos: Vector2, texture: Texture):
	var tile = TextureRect.new()
	tile.texture = texture
	tile.stretch_mode = TextureRect.STRETCH_SCALE
	tile.expand = true
	tile.size = Vector2(GRID_SIZE, GRID_SIZE) # Ensure tile fits exactly into one grid cell
	tile.position = grid_to_pixel(grid_pos)
	tile.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED  # Keep correct scaling
	
	add_child(tile)
	placed_tiles[grid_pos] = tile
	print("Tile placed at grid pos:", grid_pos, "Positioned at:", tile.position)
	
	

func _on_resized():
	calculate_grid_offset() # Recalculate center position
	update_tile_positions() # Adjust tiles
	queue_redraw()
	print("Grid and tiles updated after resize")

func update_tile_positions():
	for grid_pos in placed_tiles.keys():
		var tile = placed_tiles[grid_pos]
		tile.position = grid_to_pixel(grid_pos)
		print("Updated tile at:", grid_pos, "New position:", tile.position)
