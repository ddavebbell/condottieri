extends Control

const GRID_SIZE = 48
const GRID_WIDTH = 14
const GRID_HEIGHT = 14

var placed_tiles = {}
var grid_offset = Vector2.ZERO # store the centered position
var hovered_tile = null  # Store currently hovered tile reference


func _ready():
	position = Vector2.ZERO # ensure no initial offsets
	
	call_deferred("calculate_grid_offset")
	connect("resized", Callable(self, "on_resized"))
	
	

#func _input(event):
	#if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		#var local_pos = event.position - global_position  # Convert to local space
		#var adjusted_pos = local_pos - grid_offset
		#var grid_pos = snap_to_grid(adjusted_pos)
	#
	#
		#if is_within_grid(grid_pos):
			#if is_tile_occupied(grid_pos):
				#if hovered_tile != placed_tiles[grid_pos]:
					#clear_highlight()  # Remove previous highlight
					#hovered_tile = placed_tiles[grid_pos]
					#highlight_tile(hovered_tile)
					#print("tile being highlighted:", hovered_tile)
			#else:
				#if hovered_tile != null:
					#clear_highlight()  # Only clear if there's an active highlight
					#print("Tile highlight cleared")
				#
		#else:
			#if hovered_tile != null:
					#clear_highlight()  # Only clear if there's an active highlight
					#print("Tile highlight cleared")
			#
		#if is_within_grid(grid_pos) and is_tile_occupied(grid_pos):
			#remove_tile(grid_pos)
			#
			#
	#if event is InputEventMouseMotion:
		#var local_pos = event.position - global_position  # Convert to local space
		#var adjusted_pos = local_pos - grid_offset
		#var grid_pos = snap_to_grid(adjusted_pos)
		#
			#
	#if event is InputEventMouseButton and event.pressed:
		#var local_pos = event.position - global_position
		#var adjusted_pos = local_pos - grid_offset
		#var grid_pos = snap_to_grid(adjusted_pos)
		#
		#if event.button_index == MOUSE_BUTTON_RIGHT and is_within_grid(grid_pos) and is_tile_occupied(grid_pos):
			#remove_tile(grid_pos)
			#
func _input(event):
	# Handle mouse motion (hovering over tiles)
	if event is InputEventMouseMotion:
		var local_pos = event.position - global_position  # Convert to local space
		var adjusted_pos = local_pos - grid_offset
		var grid_pos = snap_to_grid(adjusted_pos)
		
		if is_within_grid(grid_pos):
			if is_tile_occupied(grid_pos):
				if hovered_tile != placed_tiles[grid_pos]:
					clear_highlight()  # Remove previous highlight
					hovered_tile = placed_tiles[grid_pos]
					highlight_tile(hovered_tile)
					print("Tile being highlighted:", hovered_tile)
			else:
				if hovered_tile != null:
					clear_highlight()  # Only clear if there's an active highlight
					print("Tile highlight cleared")
		else:
			if hovered_tile != null:
				clear_highlight()  # Only clear if there's an active highlight
				print("Tile highlight cleared")
				
	# Handle left mouse button click (selection)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos = event.position - global_position
		var adjusted_pos = local_pos - grid_offset
		var grid_pos = snap_to_grid(adjusted_pos)
	
		if is_within_grid(grid_pos) and is_tile_occupied(grid_pos):
			print("Tile selected at:", grid_pos)
		
	# Handle right mouse button click (tile removal)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var local_pos = event.position - global_position
		var adjusted_pos = local_pos - grid_offset
		var grid_pos = snap_to_grid(adjusted_pos)
		
		if is_within_grid(grid_pos) and is_tile_occupied(grid_pos):
			remove_tile(grid_pos)
			clear_highlight()  # Clear highlight when a tile is deleted
			hovered_tile = null  # Reset hovered tile reference
			print("Tile removed at:", grid_pos)


func highlight_tile(tile):
	tile.modulate = Color(1.5, 1.5, 1.5, 1.0)  # Brighten the tile slightly
	print("Tile highlighted at:", tile.position)

func clear_highlight():
	if hovered_tile:
		hovered_tile.modulate = Color(1, 1, 1, 1)  # Reset to normal color
		print("Tile highlight cleared at:", hovered_tile.position)
		hovered_tile = null


func remove_tile(grid_pos: Vector2):
	if grid_pos in placed_tiles:
		var tile = placed_tiles[grid_pos]
		remove_child(tile)  # Remove the tile from the scene tree
		placed_tiles.erase(grid_pos)  # Remove from tracking dictionary
		
		print("Tile removed at grid position:", grid_pos)
	else:
		print("No tile to remove at:", grid_pos)


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
	if hovered_tile:
		draw_rect(Rect2(hovered_tile.position, Vector2(GRID_SIZE, GRID_SIZE)), Color(0, 1, 0, 0.3), true)
		

func calculate_grid_offset():
	var parent = get_parent() # Get the parent MainMapDisplay
	
	if parent:
		#await get_tree().process_frame  # Wait for layout update to finish
		var parent_size = parent.size  
		# Get MainMapDisplay's actual size
		var grid_total_size = Vector2(GRID_WIDTH * GRID_SIZE, GRID_HEIGHT * GRID_SIZE)
		
		
		
		# Calculate the centered position within the parent container
		position = grid_offset 
		
		
		update_tile_positions()
		queue_redraw()



func _can_drop_data(_pos, _data) -> bool:
	return true  # Allow all drops for now


func _drop_data(pos: Vector2, data: Variant):
	var local_pos = pos - global_position # convert to local space
	var adjusted_pos = local_pos - grid_offset # Correct for grid offset
	var grid_pos = snap_to_grid(adjusted_pos)
	
	
	
	if is_within_grid(grid_pos) and not is_tile_occupied(grid_pos):
		place_tile(grid_pos, data["texture"])
		print("Tile successfully placed at:", grid_pos, 
			  "Actual pixel position:", grid_to_pixel(grid_pos))
	else:
		print("Invalid placement at:", grid_pos, "Adjusted Pos:", adjusted_pos)


func snap_to_grid(pos: Vector2) -> Vector2:
	var adjusted_pos = pos - grid_offset
	
	
	return Vector2(
		floor(adjusted_pos.x / GRID_SIZE),
		floor(adjusted_pos.y / GRID_SIZE)
		)


func grid_to_pixel(grid_pos: Vector2) -> Vector2:
	var pixel_pos = Vector2(
		grid_pos.x * GRID_SIZE + grid_offset.x, 
		grid_pos.y * GRID_SIZE + grid_offset.y
	) + position
	
	
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
	tile.modulate = Color(1, 1, 1, 1)  # Ensure new tile starts with default color
	
	add_child(tile)
	placed_tiles[grid_pos] = tile
	
	clear_highlight()  # Ensure any previous highlight is removed
	print("clear_highlight after, highlight cleared from placed tile")
	
	

func _on_resized():
	calculate_grid_offset() # Recalculate center position
	update_tile_positions() # Adjust tiles
	queue_redraw()
	

func update_tile_positions():
	for grid_pos in placed_tiles.keys():
		var tile = placed_tiles[grid_pos]
		tile.position = grid_to_pixel(grid_pos)
		
