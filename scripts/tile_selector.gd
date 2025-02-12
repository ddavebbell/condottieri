extends Node2D
class_name TileSelector

@export var board_size: Vector2 = Vector2(12, 12)  # ✅ Default 12x12 grid
@export var tile_size: int = 48  # Tile dimensions
@export var grid_offset: Vector2 = Vector2(0, 0)  # Position offset
@export var is_chessboard: bool = true  # Toggle chess notation
@export var blocked_tiles: Array[Vector2] = []  # ✅ Non-playable tiles (invisible to player)

var selected_tiles: Array[String] = []  # Stores selections

func _ready():
	set_process_input(true)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var tile_pos = _get_tile_under_mouse(event.position)
		
		if tile_pos and tile_pos not in blocked_tiles:  # ✅ Prevents selecting non-playable tiles
			_toggle_tile_selection(tile_pos)

func _get_tile_under_mouse(mouse_pos):
	var local_pos = mouse_pos - grid_offset
	var tile_x = int(local_pos.x / tile_size)
	var tile_y = int(local_pos.y / tile_size)

	if tile_x >= 0 and tile_x < board_size.x and tile_y >= 0 and tile_y < board_size.y:
		if is_chessboard:
			return _convert_to_chess_notation(tile_x, tile_y)
		return Vector2(tile_x, tile_y)

	return null

func _convert_to_chess_notation(x, y):
	var chess_columns = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".substr(0, int(board_size.x))  # ✅ Supports 12x12+ grids
	var chess_x = chess_columns[x]
	var chess_y = str(int(board_size.y) - y)  # Flip Y axis for chess notation
	return chess_x + chess_y  # Example: "E4"

func _toggle_tile_selection(tile_pos):
	if tile_pos in selected_tiles:
		selected_tiles.erase(tile_pos)
	else:
		selected_tiles.append(tile_pos)

	queue_redraw()

func _draw():
	for tile in selected_tiles:
		var tile_pos = _convert_from_chess_notation(tile) if is_chessboard else tile
		var rect = Rect2(tile_pos * tile_size + grid_offset, Vector2(tile_size, tile_size))
		draw_rect(rect, Color(0, 1, 0, 0.5), true)  # ✅ Green highlight for selection

func _convert_from_chess_notation(chess_pos):
	var chess_columns = {}
	for i in range(int(board_size.x)):
		chess_columns["ABCDEFGHIJKLMNOPQRSTUVWXYZ"[i]] = i  # ✅ Supports up to column "Z"

	var x = chess_columns[chess_pos[0]]
	var y = int(board_size.y) - int(chess_pos.substr(1))  # Convert notation back to grid
	return Vector2(x, y)
