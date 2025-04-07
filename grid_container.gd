extends Control

class_name MapGridContainer


# this all needs editing
# this all needs editing
# this all needs editing
# this all needs editing
# this all needs editing



const GRID_SIZE = 48
const GRID_WIDTH = 14
const GRID_HEIGHT = 14

var placed_tiles = {}
var grid_offset = Vector2.ZERO # store the centered position
var hovered_tile = null  # Store currently hovered tile reference
var current_filename: String = ""  # Tracks the current map file name
var triggers: Array = []  

# WARNING these two are declared but not used
signal map_loaded(map_name)  # ✅ New signal to notify when a map is loaded
signal triggers_loaded(triggers)  # ✅ Define a signal


@onready var load_save_map_popup = $/root/MapEditor/MapEditorPopUp
@onready var board_event_manager = preload("res://scripts/core/board_event_manager.gd").new()  # Load Trigger Manager
@onready var map_editor_screen = preload("res://scenes/MapEditorScreen.tscn")


func _ready():
	position = Vector2.ZERO # ensure no initial offsets
	
	call_deferred("calculate_grid_offset")
	connect("resized", Callable(self, "on_resized"))


#func _input(event): # Tracks the mouse input events of drag and drop
	## Handle mouse motion (hovering over tiles)
	#if event is InputEventMouseMotion:
		#var local_pos = event.position - global_position  # Convert to local space
		#var adjusted_pos = local_pos - grid_offset
		#var grid_pos = snap_to_grid(adjusted_pos)
		#
		#if is_within_grid(grid_pos):
			#if is_tile_occupied(grid_pos):
				#if hovered_tile != placed_tiles[grid_pos]:
					#clear_highlight()  # Remove previous highlight
					#hovered_tile = placed_tiles[grid_pos]
					#highlight_tile(hovered_tile)
					#print("Tile being highlighted:", hovered_tile)
			#else:
				#if hovered_tile != null:
					#clear_highlight()  # Only clear if there's an active highlight
					#print("Tile highlight cleared")
		#else:
			#if hovered_tile != null:
				#clear_highlight()  # Only clear if there's an active highlight
				#print("Tile highlight cleared")
				#
#
	#if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		#var local_pos = event.position - global_position
		#var adjusted_pos = local_pos - grid_offset
		#var grid_pos = snap_to_grid(adjusted_pos)
	#
	#if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		#var local_pos = event.position - global_position
		#var adjusted_pos = local_pos - grid_offset
		#var grid_pos = snap_to_grid(adjusted_pos)
		#
		#if is_within_grid(grid_pos) and is_tile_occupied(grid_pos):
			#remove_tile(grid_pos)
			#clear_highlight()  # Clear highlight when a tile is deleted


## # CREATE GRID AND MAINTAIN IT # # # #

#func _draw():
	#var grid_color = Color(0.3, 0.3, 0.3, 0.8)
	#
	#for x in range(GRID_WIDTH + 1):
		#draw_line(
			#grid_offset + Vector2(x * GRID_SIZE, 0), 
			#grid_offset + Vector2(x * GRID_SIZE, GRID_HEIGHT * GRID_SIZE),
			#grid_color
			#)
	#for y in range(GRID_HEIGHT + 1):
		#draw_line(
			#grid_offset + Vector2(0, y * GRID_SIZE), 
			#grid_offset + Vector2(GRID_WIDTH * GRID_SIZE, y * GRID_SIZE), 
			#grid_color
			#)
	#if hovered_tile:
		#draw_rect(Rect2(hovered_tile.position, Vector2(GRID_SIZE, GRID_SIZE)), Color(0, 1, 0, 0.3), true)
#
#func _on_resized():
	#calculate_grid_offset() # Recalculate center position
	#update_tile_positions() # Adjust tiles
	#queue_redraw()
#
#func update_tile_positions():
	#for grid_pos in placed_tiles.keys():
		#var tile = placed_tiles[grid_pos]
		#tile.position = grid_to_pixel(grid_pos)
#
#
#
		### # # # GRID NAVIGATION FUNCTIONALITY # # # ##
#
#func calculate_grid_offset():
	#var parent = get_parent() # Get the parent MainMapDisplay
	#
	#if parent:
		#position = grid_offset # Calculate the centered position within the parent container
		#
		#update_tile_positions()
		#queue_redraw()

func highlight_tile(tile):
	tile.modulate = Color(1.5, 1.5, 1.5, 1.0)  # Brighten the tile slightly

func clear_highlight():
	if hovered_tile:
		hovered_tile.modulate = Color(1, 1, 1, 1)  # Reset to normal color
		hovered_tile = null

func remove_tile(grid_pos: Vector2):
	if grid_pos in placed_tiles:
		var tile = placed_tiles[grid_pos]
		remove_child(tile)  # Remove the tile from the scene tree
		placed_tiles.erase(grid_pos)  # Remove from tracking dictionary
		
		print("Tile removed at grid position:", grid_pos)
	else:
		print("No tile to remove at:", grid_pos)


		##   ##    ##    ##    ##    ##   ##    ##
		##       DRAG AND DROP FUNCTIONALITY    ##
		##   ##    ##    ##    ##    ##   ##    ##

func _can_drop_data(_pos, _data) -> bool:
	return true  # Allow all drops for now

#func _drop_data(pos: Vector2, data: Variant):
	#var local_pos = pos - global_position # convert to local space
	#var adjusted_pos = local_pos - grid_offset # Correct for grid offset
	##var grid_pos = snap_to_grid(adjusted_pos)
	#
	#if is_within_grid(grid_pos) and not is_tile_occupied(grid_pos):
		#place_tile(grid_pos, data["texture"])
		#print("Tile successfully placed at:", grid_pos)
			  ##"Actual pixel position:", grid_to_pixel(grid_pos))
	#else:
		#print("Invalid placement at:", grid_pos, "Adjusted Pos:", adjusted_pos)
#
#func snap_to_grid(pos: Vector2) -> Vector2:
	#var adjusted_pos = pos - grid_offset
	#
	#
	#return Vector2(
		#floor(adjusted_pos.x / GRID_SIZE),
		#floor(adjusted_pos.y / GRID_SIZE)
		#)
#
#func grid_to_pixel(grid_pos: Vector2) -> Vector2:
	#var pixel_pos = Vector2(
		#grid_pos.x * GRID_SIZE + grid_offset.x, 
		#grid_pos.y * GRID_SIZE + grid_offset.y
	#) + position
	#
	#
	#return pixel_pos

func is_within_grid(grid_pos: Vector2) -> bool:
	return grid_pos.x >= 0 and grid_pos.y >= 0 and \
	grid_pos.x < GRID_WIDTH and \
	grid_pos.y < GRID_HEIGHT

func is_tile_occupied(grid_pos: Vector2) -> bool:
	return grid_pos in placed_tiles

func place_tile(grid_pos: Vector2, texture: Texture):
	if grid_pos in placed_tiles:
		print("⚠ Tile already exists at:", grid_pos)
		return
	
	var tile = TextureRect.new()
	tile.texture = texture
	tile.stretch_mode = TextureRect.STRETCH_SCALE
	tile.expand = true
	tile.size = Vector2(GRID_SIZE, GRID_SIZE) # Ensure tile fits exactly into one grid cell
	tile.modulate = Color(1, 1, 1, 1)  # Ensure new tile starts with default color
	#tile.position = grid_to_pixel(grid_pos)
	
	add_child(tile)
	placed_tiles[grid_pos] = tile
	clear_highlight()  # Ensure any previous highlight is removed
	
	print("✅ Tile placed at:", grid_pos, "Position:", tile.position)


# # # # LOADING AND SAVING MAP FUNCTIONALITY # # # #

## ✅ Main function to load a map
func load_map(map_name: String):
	print("🟢 Entered load_map() for:", map_name)
	
	var map_data = _verify_map_name_and_data(map_name)
	
	if map_data == null:
		print("❌ ERROR: Invalid map data! Aborting load.")
		return
	
	print("✅ Successfully parsed map data:", map_data)

	## ✅ Place tiles on grid
	_place_tiles_on_grid(map_data)
	
	## ✅ Load triggers from saved map data
	if map_data.has("triggers"):
		_load_triggers(map_data["triggers"])
	else:
		print("⚠️ WARNING: No triggers found in saved map.")

	## ✅ Load thumbnail if it exists
	_load_thumbnail_for_map(map_data)

	## ✅ Save the current filename & emit map loaded signal
	current_filename = map_name
	emit_signal("map_loaded", current_filename)
	
	print("✅ Map Loaded Successfully:", current_filename)


func _load_triggers(trigger_data: Array):
	print("🔄 Loading Triggers from Map Data:", trigger_data)

	triggers.clear()

	if trigger_data.is_empty():
		print("⚠️ WARNING: No triggers found to load!")
		return

	for data in trigger_data:
		if not data.has("cause") or not data.has("effects"):
			print("❌ ERROR: Missing required trigger fields! Skipping entry:", data)
			continue  # Skip invalid trigger data
			
		var new_trigger = create_new_trigger(data)
		triggers.append(new_trigger)  ## ✅ Add to memory
		print("✅ Loaded Trigger:", new_trigger.cause, "| Effects:", new_trigger.effects)

	print("✅ Successfully loaded", triggers.size(), "triggers into memory.")

func create_new_trigger(data):
	var new_trigger = Trigger.new()
	new_trigger.cause = data["cause"]
	new_trigger.trigger_tiles = data.get("trigger_tiles", []) if data.get("trigger_tiles") is Array else []
	new_trigger.sound_effect = data.get("sound_effect", "")
	new_trigger.effects = _deserialize_effects(data.get("effects", []))
	return new_trigger
	

func _deserialize_effects(effect_data: Array) -> Array:
	var effects = []
	for data in effect_data:
		var effect = Effect.new()
		effect.effect_type = data["effect_type"]
		effect.effect_parameters = data["effect_parameters"]
		effects.append(effect)
	return effects

## ✅ Validate file path & return JSON map data
func _verify_map_name_and_data(map_name: String) -> Dictionary:
	var file_path = "user://maps/" + map_name + ".json"
	
	if not FileAccess.file_exists(file_path):
		print("❌ ERROR: Map file does not exist:", file_path)
		return {}
	
	## ✅ Open and parse JSON file
	var file = FileAccess.open(file_path, FileAccess.READ)
	var map_data = JSON.parse_string(file.get_as_text())
	file.close()

	if map_data == null or not map_data.has("tiles"):
		print("❌ ERROR: Invalid or missing map data!")
		return {}

	return map_data


func _place_tiles_on_grid(json_map_data): # Places tiles on the grid from loaded map data
	clear_grid()  ## ✅ Ensure grid is cleared before placing new tiles

	if not json_map_data.has("tiles"):
		print("❌ ERROR: No 'tiles' key found in map JSON!")
		return

	## ✅ Place Tiles on Grid
	for key in json_map_data["tiles"].keys():
		var coords = key.split(",")  
		var grid_pos = Vector2(coords[0].to_float(), coords[1].to_float())
		var tile_data = json_map_data["tiles"][key]

		var tile_texture: Texture2D
		if "atlas" in tile_data:
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = load(tile_data["atlas"])
			atlas_texture.region = Rect2(tile_data["region"][0], tile_data["region"][1], tile_data["region"][2], tile_data["region"][3])
			tile_texture = atlas_texture
		else:
			tile_texture = load(tile_data["texture"])

		place_tile(grid_pos, tile_texture)  ## ✅ Place tile on grid

	print("✅ Tiles placed on grid!")


## WARNING THIS IS NOT RETURNING THUMBNAIL AT ALL EVER
func _load_thumbnail_for_map(map_data): # Load thumbnail if it exists in map data
	if map_data.has("thumbnail") and FileAccess.file_exists(map_data["thumbnail"]):
		var image = Image.new()
		image.load(map_data["thumbnail"])
		print("✅ Thumbnail loaded for:", map_data)
	else:
		print("⚠️ No thumbnail found for", map_data)


func save_map(map_name: String, map_data: Dictionary) -> String: # Save map and capture thumbnail
	print("💾 Saving map:", map_name, " with Data:", JSON.stringify(map_data, "\t"))

	# ✅ Ensure `map_data` contains required fields without overriding it
	if not map_data.has("tiles"):
		map_data["tiles"] = {}
	
	#change to boardevents
	#if not map_data.has("board event"):
		#map_data["board_events"] = board_event_manager.get_all_triggers() if board_event_manager else []

	# ✅ Ensure tiles are stored properly
	for grid_pos in placed_tiles.keys():
		var tile_node = placed_tiles[grid_pos] 
		var tile_texture = tile_node.texture 

		var tile_data = {}

		if tile_texture is AtlasTexture:
			tile_data = {
				"atlas": tile_texture.atlas.resource_path, 
				"region": [
					tile_texture.region.position.x, 
					tile_texture.region.position.y, 
					tile_texture.region.size.x, 
					tile_texture.region.size.y
				]
			}
		else:
			tile_data = { "texture": tile_texture.resource_path }
		
		map_data["tiles"][str(grid_pos.x) + "," + str(grid_pos.y)] = tile_data
		print("✅ Saved Tile at:", grid_pos, "→", tile_data)

	# ✅ Save JSON
	var file_path = "user://maps/" + map_name.to_lower() + ".json"
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(map_data, "\t"))
	file.close()

	# ✅ Capture thumbnail
	await capture_screenshot(map_name, map_data)  # ✅ Pass updated map data
	load_save_map_popup.show_confirmation_popup("✅ Map saved successfully!")
	print("✅ Map saved successfully:", file_path)

	return map_name  # ✅ Return the saved map name


func capture_screenshot(map_name: String, map_data: Dictionary):
	var map_editor_popup = get_tree().get_root().find_child("MapEditorPopUp", true, false)
	var save_menu = map_editor_popup.get_node_or_null("LoadSaveMapPopUp") if map_editor_popup else null
	
	# 🔹 Hide Save Menu Before Capturing
	if save_menu:
		save_menu.visible = false
		await get_tree().process_frame  # ✅ Wait for one frame
		await RenderingServer.frame_post_draw  # ✅ Ensure UI fully updates before capture
		
	# 🔹 NEW: Delay the screenshot by 0.1 seconds to fully hide the menu
	await get_tree().create_timer(0.2).timeout  
	
	# ✅ Capture the Grid Only (Avoid Side Menu)
	var viewport_texture = get_viewport().get_texture()
	var full_image = viewport_texture.get_image()
	
	var grid_position = Vector2(100, 100)  # Adjust this based on the grid's actual position
	var grid_size = Vector2(512, 512)  # Make this a square region (adjustable)
	var cropped_image = full_image.get_region(Rect2(grid_position, grid_size)) # ✅ Define the Crop Region (Centered on the Grid)
	cropped_image.resize(256, 256)
	
	
	# ✅ Save Thumbnail
	var thumbnail_path = "user://thumbnails/" + map_name + ".png"
	var err = cropped_image.save_png(thumbnail_path)
	if err == OK:
		map_data["thumbnail"] = thumbnail_path
		print("✅ Thumbnail saved successfully:", thumbnail_path)
	else:
		print("❌ Error saving thumbnail:", err)
		
	print("🔍 Checking if thumbnail exists:", thumbnail_path)
	if FileAccess.file_exists(thumbnail_path):
		print("✅ Thumbnail successfully saved:", thumbnail_path)
	else:
		print("❌ ERROR: Thumbnail was NOT saved!")
		

func map_exists(map_name: String) -> bool:
	var file_path = "user://maps/" + map_name.to_lower() + ".json"
	return FileAccess.file_exists(file_path)




## Grid helper functions ##

func str_to_vector(pos_str: String) -> Vector2:
	var parts = pos_str.split(",")
	return Vector2(int(parts[0]), int(parts[1]))


func clear_grid():
	for tile in placed_tiles.values(): # ✅ Remove all child nodes that represent tiles
		tile.queue_free()
		
	placed_tiles.clear()
	print("✅ Grid cleared successfully!")
