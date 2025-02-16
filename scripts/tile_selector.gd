extends Node2D
class_name TileSelector

@export var board_size: Vector2 = Vector2(12, 12)  
@export var tile_size: int = 48  
@export var grid_offset: Vector2 = Vector2(0, 0)  
@export var is_chessboard: bool = true  
@export var blocked_tiles: Array[Vector2] = []  

var selected_tiles: Array[Dictionary] = []  

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var tile_pos = _get_tile_under_mouse(event.position)
		if tile_pos and tile_pos not in blocked_tiles:
			_toggle_tile_selection(tile_pos)

func _get_tile_under_mouse(mouse_pos):
	var local_pos = mouse_pos - grid_offset
	var tile_x = int(local_pos.x / tile_size)
	var tile_y = int(local_pos.y / tile_size)

	if tile_x >= 0 and tile_x < board_size.x and tile_y >= 0 and tile_y < board_size.y:
		return Vector2(tile_x, tile_y)

	return null

func _toggle_tile_selection(tile_pos):
	var tile_data = {"grid_pos": tile_pos}

	var existing_tile = null
	for t in selected_tiles:
		if t["grid_pos"] == tile_pos:
			existing_tile = t
			break

	if existing_tile:
		selected_tiles.erase(existing_tile)
	else:
		selected_tiles.append(tile_data)

	queue_redraw()

func get_selected_tiles() -> Array:
	if selected_tiles.is_empty():
		print("⚠️ WARNING: No tiles selected!")
	return selected_tiles


func _draw():
	for tile in selected_tiles:
		var rect = Rect2(tile["grid_pos"] * tile_size + grid_offset, Vector2(tile_size, tile_size))
		draw_rect(rect, Color(0, 1, 0, 0.5), true)  
