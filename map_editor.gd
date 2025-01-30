extends Control

var map_data = {}  # Store loaded map data


func _ready():
	print("Loading maps into selection screen...")
	load_maps_from_files()  # Ensure it runs when the screen opens


func set_map_data(data):
	map_data = data
	print("Loaded map data:", map_data)
	
	if grid_container:
		grid_container.load_map_data(map_data)


func rebuild_grid():
	if map_data.is_empty():
		print("No map data to load!")
		return
		
	for grid_pos in map_data.keys():
		var tile_texture = load(map_data[grid_pos])  # Load tile texture path
		place_tile(grid_pos, tile_texture)



# Generate a thumbnail of the current map editor view
func generate_thumbnail() -> ImageTexture:
	# Assuming the editor is rendered in a Viewport node
	var viewport = $Viewport  # Replace with the actual Viewport node in your scene
	var texture = viewport.get_texture()  # Capture the Viewport's texture
	var image = texture.get_data()  # Get the image data
	image.flip_y()  # Flip vertically (Godot textures are upside-down by default)

	# Convert the image to a usable texture
	var thumbnail = ImageTexture.new()
	thumbnail.create_from_image(image)
	
	return thumbnail

# Save the current map
func save_map(name: String, map_data: Dictionary):
	# Generate the thumbnail for the current map
	var thumbnail = generate_thumbnail()
	
	# Store the map in the GlobalData singleton
	GlobalData.add_map(name, thumbnail, map_data)
	
	# Optional: Persist to disk (see Step 4)
	print("Map saved:", name)
	
	
func load_new_map():
	## Clear all placed tiles
	#placed_tiles.clear()
	
	# Optionally, reset the grid or other settings
	#reset_grid()
	print("Loaded new blank map!")

func reset_grid():
	# Logic to clear the grid visually and reset other elements
	for child in get_children():
		if child is TextureRect:
			child.queue_free()  # Remove all tiles visually
	print("Grid reset.")
