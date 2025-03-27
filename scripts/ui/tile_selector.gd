extends Node

class_name TileSelector

#@export var board_size: Vector2 = Vector2(12, 12)  
#@export var tile_size: int = 48  
#@export var grid_offset: Vector2 = Vector2(0, 0)  
#@export var is_chessboard: bool = true  
#@export var blocked_tiles: Array[Vector2] = []  
#
#@onready var tile_buttons = $SideMenu/TerrainMenuWrapper/MenuWrapper/TerrainMenu/MarginContainer/ScrollContainer/PanelContainer
#
var selected_tiles: Array[Dictionary] = []  
#signal tile_selected(texture: Texture)
#

func _ready():
	print("🧐 TileSelector is being added to: ", get_parent(), " (", get_parent().get_class(), ")")

#func _ready():
		#for button in tile_buttons.get_children():
			#button.set_meta("tile_texture", button.texture)  # Store texture in metadata
			#button.connect("pressed", _on_tile_button_pressed.bind(button))
#
#func _on_tile_button_pressed(tile_type: String, texture: Texture):
	#emit_signal("tile_selected", tile_type, texture)  # ✅ Send both tile name and texture
#
#
#func _input(event):
	#if event is InputEventMouseButton and event.pressed:
		#var tile_pos = _get_tile_under_mouse(event.position)
		#if tile_pos and tile_pos not in blocked_tiles:
			#_toggle_tile_selection(tile_pos)
#
#func _get_tile_under_mouse(mouse_pos):
	#var local_pos = mouse_pos - grid_offset
	#var tile_x = int(local_pos.x / tile_size)
	#var tile_y = int(local_pos.y / tile_size)
#
	#if tile_x >= 0 and tile_x < board_size.x and tile_y >= 0 and tile_y < board_size.y:
		#return Vector2(tile_x, tile_y)
#
	#return null
#
#func _toggle_tile_selection(tile_pos):
	#var tile_data = {"grid_pos": tile_pos}
#
	#var existing_tile = null
	#for t in selected_tiles:
		#if t["grid_pos"] == tile_pos:
			#existing_tile = t
			#break
#
	#if existing_tile:
		#selected_tiles.erase(existing_tile)
	#else:
		#selected_tiles.append(tile_data)
#
	#queue_redraw()
#
#func get_selected_tiles() -> Array:
	#if selected_tiles.is_empty():
		#print("⚠️ WARNING: No tiles selected!")
	#return selected_tiles
#
#
#func _draw():
	#for button in tile_buttons.get_children():
		#button.connect("pressed", _on_tile_button_pressed.bind(button.texture))  # Send texture instead of name
