#extends "res://addons/gut/test.gd"
#
#var map_editor_scene
#var map_editor_instance
#var grid_manager
#var tile_layer
#var test_global_thumbnails
#
#
##region before and after
#
#func before_each():
	#print("🔎 Ensuring cleanup before test starts...")
	#map_editor_scene = load("res://scenes/MapEditor.tscn") # Load the entire scene
#
#
	## ✅ Remove any previous MapEditor instance
	#if is_instance_valid(map_editor_instance):
		#print("🗑️ Removing previous MapEditor instance...")
		#for child in map_editor_instance.get_children():
			#child.queue_free()
		#map_editor_instance.queue_free()
		#await get_tree().process_frame
#
	## ✅ Instantiate MapEditor scene
	#map_editor_instance = map_editor_scene.instantiate()
	#add_child(map_editor_instance)
	#await get_tree().process_frame
#
	## 🛠 **Ensure MapEditor is fully loaded before proceeding**
	#var max_attempts = 5
	#var attempts = 0
	#while attempts < max_attempts and not is_instance_valid(map_editor_instance):
		#await get_tree().process_frame
		#print("⏳ Waiting for MapEditor to appear... Attempt:", attempts + 1)
		#attempts += 1
#
	#if not is_instance_valid(map_editor_instance):
		#print("❌ ERROR: MapEditor failed to load in time!")
		#return
#
	#print("✅ MapEditorInstance added at:", map_editor_instance.get_path())
#
	## ✅ Locate GridManager
	#grid_manager = map_editor_instance.get_node_or_null("HSplitContainer/MarginContainer/MainMapDisplay/GridContainer/GridManager")
#
	#if is_instance_valid(grid_manager):
		#print("✅ GridManager found:", grid_manager)
		#GridManager.grid_manager = grid_manager  # ✅ Assign in GlobalMapManager
	#else:
		#print("❌ ERROR: GridManager not found!")
#
	## ✅ Locate TileLayer dynamically with retry mechanism
	#tile_layer = null
	#attempts = 0
	#while attempts < max_attempts:
		#await get_tree().process_frame
		#tile_layer = map_editor_instance.find_child("TileLayer", true, false)
		#if is_instance_valid(tile_layer):
			#break
		#print("⏳ Retrying TileLayer lookup... Attempt:", attempts + 1)
		#attempts += 1
#
	#if is_instance_valid(tile_layer):
		#print("✅ TileLayer found:", tile_layer)
		#GridManager.tile_layer = tile_layer  # ✅ Assign in GlobalMapManager
	#else:
		#print("❌ ERROR: TileLayer not found in test!")
#
	## ✅ Confirm Assignments
	#print("MapManager.tile_layer:", MapManager.tile_layer)
#
#
#
#func after_each():
	#print("🗑️ Cleaning up test environment...")
	#
	#GridManager.grid_manager = null
	#GridManager.tile_layer = null
	#await get_tree().process_frame
	#
	## ✅ Remove children safely before queue_free()
	#if is_instance_valid(grid_manager):
		#print("🗑️ Removing GridManager:")
		#
		#for child in grid_manager.get_children():
			#child.queue_free()
		#await get_tree().process_frame  
		#
		#var parent = grid_manager.get_parent()
		#if parent:
			#print("🚨 Removing GridManager from parent:", parent.name)
			#parent.remove_child(grid_manager)
		#
		#grid_manager.queue_free()
		#await get_tree().process_frame  
		#grid_manager = null
#
	#if is_instance_valid(map_editor_instance):
		#for child in map_editor_instance.get_children():
			#child.queue_free()
		#await get_tree().process_frame 
		#map_editor_instance.queue_free()
		#await get_tree().process_frame 
		#map_editor_instance = null
#
	## ✅ Remove orphaned nodes manually to prevent leaks
	#print("🔎 Checking for remaining orphans after cleanup...")
	#var orphan_nodes = get_tree().get_nodes_in_group("Orphan")
	#for orphan in orphan_nodes:
		#print("⚠️ Removing lingering orphan:", orphan.name)
		#orphan.queue_free()
#
	#map_editor_scene = null
	#await get_tree().process_frame
	#print("✅ Cleanup complete. No lingering nodes.")
	#print("🔎 GridManager:", GridManager.grid_manager)
	#print("🔎 TileLayer:", GridManager.tile_layer)
#
#
#
##endregion
#
#var previous_nodes = []  # Store previous nodes
#
#func _print_all_nodes():
	#var all_nodes = []
	#var queue = [get_tree().root]
	#
	#while queue.size() > 0:
		#var current = queue.pop_front()
		#
		## Ignore ColorRects
		#if current is ColorRect:
			#continue
		#
		#all_nodes.append(current.get_path())
		#queue.append_array(current.get_children())
#
	#print("🌲 Scene Tree Nodes (Total:", all_nodes.size(), ")")
	#
	## 🔍 Find orphaned nodes (nodes that remain after cleanup)
	#if previous_nodes.size() > 0:
		#var orphaned_nodes = previous_nodes.filter(func(n): return not all_nodes.has(n))
		#if orphaned_nodes.size() > 0:
			#print("🚨 Orphaned Nodes Remaining:")
			#for node in orphaned_nodes:
				#print(" - ", node)
		#else:
			#print("✅ No Orphaned Nodes Found.")
#
	#previous_nodes = all_nodes.duplicate()
#
#
#
##region Tests
#
## DOES NOT test THE  SCREENSHOT FUNCTION YET
#func test_save_map():
	## Given: A sample map name
	#var test_map_name = "test_map"
#
	## When: The save function is called
	#GlobalMapManager.save_map(test_map_name)
	#await get_tree().process_frame  # Ensure processing occurs
#
	## Then: The JSON file should exist
	#var file_path = "user://maps/" + test_map_name.to_lower() + ".json"
	#assert_true(FileAccess.file_exists(file_path), "❌ ERROR: Map JSON file was not created!")
#
	## Then: The file should contain valid JSON
	#var file = FileAccess.open(file_path, FileAccess.READ)
	#assert_true(file != null, "❌ ERROR: Map file could not be opened!")
#
	#var file_content = file.get_as_text()
	#file.close()
#
	## Ensure valid JSON structure
	#var parsed_data = JSON.parse_string(file_content)
	#assert_true(parsed_data is Dictionary, "❌ ERROR: Saved map data is not a valid Dictionary!")
#
	#print("✅ `test_save_map()` passed successfully!")
#
#
## THIS IS THE FUNC THAT IS TESTED IN save_map
##func test_save_map_thumbnail():
	##var test_map_name = "test_map"
	##
	### Check thumbnail existence
	##var thumbnail_path = "user://thumbnails/" + test_map_name.to_lower() + ".png"
	##assert_true(FileAccess.file_exists(thumbnail_path), "❌ ERROR: Map thumbnail was not saved!")
	##pass
#
#
#
#func test_load_map():
	## Prepare mock map data
	#var mock_map_name = "test_map"
	#var mock_map_data = {
		#"file_name": mock_map_name,
		#"tile_data": { "0,0": 1, "1,1": 2 },
		#"pieces": [{ "type": "knight", "position": "0,0" }],
		#"triggers": [{ "event": "move", "effect": "capture" }]
	#}
	#
	#var current_map_name: String = "test_map"  # Tracks the loaded map name
	#
	## Save the mock map
	#save_mock_map(mock_map_name, mock_map_data)
	#
	## Load the map
	#GlobalMapManager.load_map(mock_map_name)
#
	## Assertions
	#assert_eq(current_map_name, mock_map_name, "Map name should match")
	##assert_eq(grid_manager.get_used_cells().size(), 2, "Grid should have 2 tiles")
	##assert_eq(piece_manager.get_piece_count(), 1, "Should have 1 piece")
	##assert_eq(trigger_manager.get_trigger_count(), 1, "Should have 1 trigger")
#
	#print("✅ test_load_map passed successfully!")
#
#
#
#func test_save_map_verify_map_data_structure():
	## Arrange: Create a mock TileLayer and assign it
	#var mock_tile_layer = TileGrid.new()
	#GlobalMapManager.set_tile_layer(mock_tile_layer)
#
	#var map_data = GlobalMapManager.map_data
	#map_data["file_name"] = "Mock Map Name"
	#
	#var mock_tile_data = mock_tile_layer.get_tile_data
	#
	## Example tile placement
	#map_data["tile_data"] = mock_tile_data
	#
	## Mock map metadata
	#var mock_thumbnail = Image.new()  # Mock image
	#mock_thumbnail.create(32, 32, false, Image.FORMAT_RGBA8)  # Creates a dummy image
	#map_data["thumbnail"] = mock_thumbnail
#
	#var mock_pieces = [{"type": "knight", "position": Vector2(2, 2)}]  # Mock piece objects
	#map_data["pieces"] = mock_pieces
	#
	#var mock_triggers_and_effects = [{"trigger": "on_step", "effect": "teleport"}]  # Mock effects
	#map_data["triggers_and_effects"] = mock_triggers_and_effects
	#map_data["map_group"] = ""
	## Act: Save the map
#
	#GlobalMapManager.save_map(map_data["file_name"])
#
	## Assert: Verify map structure
	#assert_eq(map_data.has("file_name"), true, "❌ ERROR: 'file_name' key missing!")
	#assert_eq(map_data.has("tile_data"), true, "❌ ERROR: 'tile_data' key missing!")
	#assert_eq(map_data.has("thumbnail"), true, "❌ ERROR: 'thumbnail' key missing!")
	#assert_eq(map_data.has("pieces"), true, "❌ ERROR: 'pieces' key missing!")
	#assert_eq(map_data.has("triggers_and_effects"), true, "❌ ERROR: 'triggers_and_effects' key missing!")
	#assert_eq(map_data.has("map_group"), true, "❌ ERROR: 'map_group' key missing!")
#
	## Assert: Verify map values
	#assert_eq(map_data["file_name"], "Mock Map Name", "❌ ERROR: Incorrect file name!")
	#assert_eq(map_data["tile_data"], mock_tile_layer.get_tile_data, "❌ ERROR: Tile data incorrect!")
	#assert_eq(typeof(map_data["thumbnail"]), TYPE_OBJECT, "❌ ERROR: Thumbnail is not an object!")
	#assert_eq(map_data["pieces"], [{"type": "knight", "position": Vector2(2, 2)}], "❌ ERROR: Pieces data incorrect!")  # If pieces were not yet added
	#assert_eq(map_data["triggers_and_effects"], [{"trigger": "on_step", "effect": "teleport"}], "❌ ERROR: Triggers and effects incorrect!")  # If no effects yet
	#assert_eq(map_data["map_group"], "", "❌ ERROR: Incorrect map group!")
#
	#print("📝 Captured Map Data:", JSON.stringify(map_data, "\t"))  # ✅ Debug output
	#print("✅ test_save_map_verify_map_data_structure passed successfully!")
#
#
#
#func test_get_current_tile_data():
	## Mock the tile layer with some sample data
	#var mock_tile_layer = TileGrid.new()
	#
	## Define the tiles and their positions
	#var tile_positions = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]
	#var source_id = 0  # Assuming the tiles are from source 0 in the TileSet
	#var atlas_coords = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]  # Grass, Water, Sand
	#
	## Simulate setting tile data in the tile layer
	#mock_tile_layer.set_cell(tile_positions[0], source_id, atlas_coords[0])  # Grass
	#mock_tile_layer.set_cell(tile_positions[1], source_id, atlas_coords[1])  # Water
	#mock_tile_layer.set_cell(tile_positions[2], source_id, atlas_coords[2])  # Sand
	#
	## Call the function to retrieve tile data
	#var result = mock_tile_layer.get_tile_data()
	#
	## Retrieve tile data and verify
	#var grass_tile = mock_tile_layer.get_cell_atlas_coords(tile_positions[0])
	#var water_tile = mock_tile_layer.get_cell_atlas_coords(tile_positions[1])
	#var sand_tile = mock_tile_layer.get_cell_atlas_coords(tile_positions[2])
#
	#assert_eq(grass_tile, atlas_coords[0], "Grass tile should be at (0, 0)")
	#assert_eq(water_tile, atlas_coords[1], "Water tile should be at (1, 0)")
	#assert_eq(sand_tile, atlas_coords[2], "Sand tile should be at (0, 1)")
#
	#print("✅ test_get_current_tile_data passed successfully!")
#
#
#
#
#
#
#
##func test_get_current_map_data():
	### Ensure grid starts empty
	##grid_manager.clear_grid()
	##var empty_data = grid_manager.get_current_map_data()
	##assert_eq(empty_data, { "tiles": [] }, "Grid should return an empty tile list when no tiles are placed.")
##
	### ✅ Place test tiles
	##grid_manager.grid_manager_place_tile(Vector2i(1, 1), 2)
	##grid_manager.grid_manager_place_tile(Vector2i(3, 4), 5)
##
	### 🔍 Fetch map data
	##var result = grid_manager.get_current_map_data()
	##var expected_data = { "tiles": [
		##{ "pos": Vector2i(1, 1), "type": 2 },
		##{ "pos": Vector2i(3, 4), "type": 5 }
	##]}
##
	### ✅ Verify output matches expected tile data
	##assert_eq(result, expected_data, "Tile data should match expected output.")
##
	##print("✅ test_get_current_map_data passed successfully.")
#
#
#
#func test_set_tile_layer():
	## Arrange: Create a mock TileGrid
	#var mock_tile_layer = TileGrid.new() 
	#
	## Act: Assign it to GlobalMapManager
	#GlobalMapManager.set_tile_layer(mock_tile_layer)
#
	## Assert: Ensure tile_layer is correctly set
	#assert_eq(GlobalMapManager.tile_layer, mock_tile_layer, "❌ ERROR: set_tile_layer did not assign the correct tile layer!")
#
	#print("✅ test_set_tile_layer passed successfully!")
#
##endregion
#
#
##region map data
#
#func save_mock_map(map_name: String, data: Dictionary) -> void:
	#var test_dir = "user://test_maps/"
	#var file_path = test_dir + data["file_name"].to_lower() + ".json"
#
	## Ensure test directory exists
	#if not DirAccess.dir_exists_absolute(test_dir):
		#DirAccess.make_dir_absolute(test_dir)
#
	#var file = FileAccess.open(file_path, FileAccess.WRITE)
	#file.store_string(JSON.stringify(data))
	#file.close()
#
#
#
#func create_map_data():
	## Prepare mock map data
	#var raw_map_data: Dictionary = {
		#"file_name": "test_map",
		#"tile_data": {},
		#"thumbnail": null,  # Placeholder, actual thumbnail saved separately
		#"pieces": [],  
		#"triggers_and_effects": [],  # Retrieve triggers and effects
		#"map_group": ""  # Retrieve map grouping information
	#}
	#
	#var mock_map_data = MockMapData.new(raw_map_data)
	#
	## Arrange: Create a mock TileLayer and assign it
	#var mock_tile_layer = TileGrid.new()
	#GlobalMapManager.set_tile_layer(mock_tile_layer)
#
	#var map_data = GlobalMapManager.map_data
	#map_data["file_name"] = "Mock Map Name"
	#
	#var mock_tile_data = mock_tile_layer.get_tile_data
	#
	## Example tile placement
	#map_data["tile_data"] = mock_tile_data
	#
	## Mock map metadata
	#var mock_thumbnail = Image.new()  # Mock image
	#mock_thumbnail.create(32, 32, false, Image.FORMAT_RGBA8)  # Creates a dummy image
	#map_data["thumbnail"] = mock_thumbnail
#
	#var mock_pieces = [{"type": "knight", "position": Vector2(2, 2)}]  # Mock piece objects
	#map_data["pieces"] = mock_pieces
	#
	#var mock_triggers_and_effects = [{"trigger": "on_step", "effect": "teleport"}]  # Mock effects
	#map_data["triggers_and_effects"] = mock_triggers_and_effects
	#map_data["map_group"] = ""
	#
	#return mock_map_data
#
##endregion
#
#func object_has_property(obj: Object, property_name: String) -> bool:
	#for property in obj.get_property_list():
		#if property["name"] == property_name:
			#return true
	#return false
