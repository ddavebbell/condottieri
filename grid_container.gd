extends Control

const GRID_SIZE = 48
const GRID_WIDTH = 14
const GRID_HEIGHT = 14


var placed_tiles = {}
var grid_offset = Vector2.ZERO # store the centered position

func _ready():
	call_deferred("calculate_grid_offset")
	connect("resized", Callable(self, "on_resized"))
	

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

#func calculate_grid_offset():
	#var parent_size = get_parent().size  # Get the parent container's size
	#var grid_total_size = Vector2(GRID_WIDTH * GRID_SIZE, GRID_HEIGHT * GRID_SIZE)
	## Center the grid inside the parent
	#grid_offset = (parent_size - grid_total_size) / 2.0
	#
	#print("Updated Grid Offset:", grid_offset)
	#update_tile_positions()
	#queue_redraw()

func calculate_grid_offset():
	var parent = get_parent()  # Get the parent MainMapDisplay
	if parent:
		await get_tree().process_frame  # Wait for layout update to finish
		var parent_size = parent.get_rect().size  # Get accurate parent size
		var grid_total_size = Vector2(GRID_WIDTH * GRID_SIZE, GRID_HEIGHT * GRID_SIZE)

		# Calculate the centered position within the parent container
		grid_offset = (parent_size - grid_total_size) / 2.0

		# Ensure proper alignment within the parent
		position = grid_offset

		print("Parent size:", parent_size, "Grid centered at offset:", grid_offset)

	update_tile_positions()
	queue_redraw()




func _can_drop_data(_pos, _data) -> bool:
	return true  # Allow all drops for now


func _drop_data(pos, data):
	var local_pos = pos - global_position - grid_offset  # adjust by offset
	var grid_pos = snap_to_grid(local_pos)
	
	print("Drop position:", pos, "Local position:", local_pos, "Grid position:", grid_pos)
	
	if is_within_grid(grid_pos) and not is_tile_occupied(grid_pos):
		place_tile(grid_pos, data["texture"])
		print("Tile placed at:", grid_pos, "Actual pixel position:", grid_to_pixel(grid_pos))
	else:
		print("Invalid placement at:", grid_pos)

func snap_to_grid(pos: Vector2) -> Vector2:
	var grid_x = floor((pos.x + GRID_SIZE / 2) / GRID_SIZE)
	var grid_y = floor((pos.y + GRID_SIZE / 2) / GRID_SIZE)
	return Vector2(grid_x, grid_y)


func grid_to_pixel(grid_pos: Vector2) -> Vector2:
	return Vector2(
		grid_pos.x * GRID_SIZE + position.x, 
		grid_pos.y * GRID_SIZE + position.y
		)

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
