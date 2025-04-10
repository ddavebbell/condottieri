extends "res://addons/gut/test.gd"

class_name TestMapEditorScreen

var BaseTestClass := preload("res://tests/base_map_editor_test.gd")
var base_test

var map_editor_screen
var map_editor_popup
var load_save_map_popup_menu
var load_save_map_popup_title
var cause_manager
var generated_causes = []

#region Before & After

func before_each():
	# Instantiate and add base_test safely
	if not base_test:
		base_test = BaseTestClass.new()
	if not base_test.is_inside_tree():
		add_child(base_test)

	# Setup map editor and cause manager
	await base_test._setup_map_editor()
	await base_test._setup_cause_manager()

	map_editor_screen = base_test.map_editor_screen
	cause_manager = base_test.cause_manager

	# Wait for TileLayer to exist using base_test helper
	var tile_layer_path := "HSplitContainer/MarginContainer/MainMapDisplay/GridContainer/GridManager/TileLayer"
	var tile_layer = await base_test.wait_for_node(tile_layer_path, map_editor_screen, 5)
	assert_not_null(tile_layer, "❌ TileLayer not found!")

	# Grab UI elements
	map_editor_popup = map_editor_screen.get_node_or_null("MapEditorPopUp")
	assert_not_null(map_editor_popup, "❌ MapEditorPopUp not found!")

	load_save_map_popup_menu = map_editor_popup.get_node_or_null("LoadSaveMapPopUp")
	assert_not_null(load_save_map_popup_menu, "❌ LoadSaveMapPopUp not found!")

	load_save_map_popup_title = load_save_map_popup_menu.get_node_or_null("MarginContainer/VBoxContainer/PopUpTitle")
	assert_not_null(load_save_map_popup_title, "❌ PopUpTitle not found!")

	await get_tree().process_frame
	print("✅ before_each setup complete.")


func after_each():
	print("🧹 Cleaning up TestMapEditorScreen...")
		
	# Ensure map_editor_screen exists before operating on it
	if is_instance_valid(map_editor_screen):
		# Remove tweens or any lingering children
		for child in map_editor_screen.get_children():
			if child is Tween or child is Node:
				child.queue_free()

		# Clear TileLayer
		var tile_layer_path := "HSplitContainer/MarginContainer/MainMapDisplay/GridContainer/GridManager/TileLayer"
		var tile_layer = map_editor_screen.get_node_or_null(tile_layer_path)
		if tile_layer:
			for child in tile_layer.get_children():
				child.queue_free()

		# Free all children
		for child in map_editor_screen.get_children():
			map_editor_screen.remove_child(child)
			child.queue_free()

		# Clear causes
		if map_editor_screen.causes:
			map_editor_screen.causes.clear()

	# Free popup menu
	if is_instance_valid(load_save_map_popup_menu):
		load_save_map_popup_menu.queue_free()
		load_save_map_popup_menu = null

	# Free popup and its children
	if is_instance_valid(map_editor_popup):
		for child in map_editor_popup.get_children():
			child.queue_free()
		map_editor_popup.queue_free()
		map_editor_popup = null

	# Clear generated mock causes
	generated_causes.clear()

	# Final cleanup via base_test
	if is_instance_valid(map_editor_screen):
		await base_test._cleanup_node_and_children(map_editor_screen)
	if is_instance_valid(cause_manager):
		await base_test._cleanup_node_and_children(cause_manager)

	map_editor_screen = null
	cause_manager = null

	print("🧹 Base cleanup starting...")
	await get_tree().process_frame

	await base_test._cleanup_common_nodes()

	await get_tree().process_frame
	print("✅ Base after_each complete.")

	await get_tree().process_frame
	print("✅ after_each cleanup complete.")


# debug functions #

func _print_scene_tree(node: Node, indent: int = 0):
	var prefix = " ".repeat(indent)
	print(prefix + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		_print_scene_tree(child, indent + 2)

func _debug_remaining_scene_tree():
	print("🔎 Remaining children in root (post-cleanup):")
	for node in get_tree().get_root().get_children():
		print(" -", node.name, "(", node.get_class(), ")")
		for child in node.get_children():
			print("   →", child.name, "(", child.get_class(), ")")


# # # # # # #

#endregion



func test_on_toggle_map_menu_button_pressed():
	map_editor_screen.map_menu_panel.visible = false
	map_editor_screen._on_toggle_map_menu_button_pressed()
	assert_eq(map_editor_screen.map_menu_panel.visible, true, "❌ ERROR: Menu should be visible after toggling!")
	print("✅ Toggle Menu Button works correctly.")


# # # # # # # # # # # # # #
#region Button Pressed Tests

func test_on_save_as_button_pressed():
	print("load_save_map_popup_menu before test:", load_save_map_popup_menu)
	map_editor_screen._on_save_as_button_pressed()
	
	assert_true(load_save_map_popup_menu.visible, "Pop-up should be visible after pressing save as button")
	assert_eq(load_save_map_popup_title.text, "Save map as...", "Pop-up title should be 'Save map as...'")


func test_on_save_map_button_pressed():
	# Given that the save map popup menu is accessible
	assert_true(map_editor_screen.load_save_map_popup_menu != null, "load_save_map_popup_menu should not be null")
	
	# When pressing the save map button
	map_editor_screen._on_save_map_button_pressed()
	
	# Then the popup should be visible
	assert_true(map_editor_screen.load_save_map_popup_menu.visible, "Popup should be visible after pressing save map button")


func test_on_load_map_button_pressed():
	map_editor_screen._on_load_map_button_pressed()
	print("✅ Load Map button should cause pop-up.")


func test_on_map_loaded():
	var mock_map_name = "test_map.json"
	map_editor_screen._on_map_loaded(mock_map_name)
	assert_eq(map_editor_screen.current_filename, mock_map_name, "❌ ERROR: Map filename not stored correctly!")
	print("✅ _on_map_loaded works correctly.")

#endregion


#region cause Related Logic

# func test_serialize_causes():
#     var serialized_causes = map_editor_screen._serialize_causes()
#     assert_eq(serialized_causes.size(), map_editor_screen.causes.size(), "❌ ERROR: Serialized causes mismatch!")
#     print("✅ Serialization works.")


# func test_on_edit_cause_pressed():
#     var mock_button = Button.new()
#     mock_button.set_meta("cause_data", { "cause": "piece_captured" })
#     map_editor_screen._on_edit_cause_pressed(mock_button)
#     print("✅ Edit cause button works.")

# func test_on_cause_saved():
#     var mock_cause = cause.new()
#     mock_cause.cause = "piece_captured"
#     map_editor_screen._on_cause_saved(mock_cause)
#     print("✅ cause saved successfully.")


func test_on_create_cause_pressed():
	map_editor_screen._on_create_cause_pressed()
	assert_not_null(map_editor_screen.cause_manager, "❌ ERROR: causeManager was not created!")
	print("✅ cause Manager created successfully.")


func test_on_causes_loaded():
	var mock_cause_data = generate_mock_causes()
	map_editor_screen._on_causes_loaded(mock_cause_data)
	assert_eq(map_editor_screen.causes.size(), generate_mock_causes().size(), "❌ ERROR: causes not loaded correctly!")
	print("✅ causes loaded successfully.")
	

func test_on_causes_loaded_with_valid_causes():
	print("🔬 Running: test_on_causes_loaded_with_valid_causes")

	# Create mock causes
	var mock_cause1 = cause.new()
	var mock_cause2 = cause.new()

	var cause_data = [mock_cause1, mock_cause2]

	# Call function
	map_editor_screen._on_causes_loaded(cause_data)

	# Check if causes list was updated
	assert_eq(map_editor_screen.causes.size(), 2, "❌ causes were not added correctly!")

	# Ensure UI buttons were updated
	assert_eq(map_editor_screen.cause_list.get_child_count(), 2, "❌ cause List UI buttons not updated!")

	print("✅ test_on_causes_loaded_with_valid_causes PASSED!")


func test_on_causes_loaded_with_invalid_data():
	print("🔬 Running: test_on_causes_loaded_with_invalid_data")

	# Create mixed invalid data
	var invalid_cause1 = { "cause": "Invalid", "effects": ["Effect1"] }  # ❌ Dictionary instead of cause
	var invalid_cause2 = 42  # ❌ Integer (completely invalid)
	var invalid_cause3 = "InvalidString"  # ❌ String (invalid)
	var cause_data = [invalid_cause1, invalid_cause2, invalid_cause3]

	# Call function
	map_editor_screen._on_causes_loaded(cause_data)

	# Ensure no invalid data was added
	assert_eq(map_editor_screen.causes.size(), 0, "❌ Invalid causes should not be added!")

	print("✅ test_on_causes_loaded_with_invalid_data PASSED!")


func test_update_or_add_cause_button():
	print("🔬 Running: test_update_or_add_cause_button")

	# Step 1: Ensure cause_list is empty at start
	assert_eq(map_editor_screen.cause_list.get_child_count(), 0, "❌ cause List should be empty at start!")

	# Step 2: Create a mock cause
	var mock_cause = cause.new()
	mock_cause.cause = "Piece Captured"
	mock_cause.effects = []

	# Step 3: Call function to add the cause button
	var button = map_editor_screen._update_or_add_cause_button(mock_cause)

	# Step 4: Validate button was created
	assert_true(button is Button, "❌ Function did not return a Button!")
	assert_eq(map_editor_screen.cause_list.get_child_count(), 1, "❌ cause List should contain 1 button after first addition!")
	assert_eq(button.get_meta("cause_data"), mock_cause, "❌ Button metadata (cause) does not match!")

	# Step 5: Modify the cause and update again
	mock_cause.cause = "Turn Count Reached"
	map_editor_screen._update_or_add_cause_button(mock_cause)

	# Step 6: Ensure button text was updated, not duplicated
	assert_eq(map_editor_screen.cause_list.get_child_count(), 1, "❌ No duplicate buttons should be added!")
	assert_eq(button.text, cause_manager._format_cause_button_text(mock_cause), "❌ Button text was not updated correctly!")

	# Step 7: Add another distinct cause
	var mock_cause2 = cause.new()
	mock_cause2.cause = "Piece Enters Tile"
	map_editor_screen._update_or_add_cause_button(mock_cause2)

	# Step 8: Validate the new cause was added
	assert_eq(map_editor_screen.cause_list.get_child_count(), 2, "❌ Second cause was not added!")

	print("✅ test_update_or_add_cause_button PASSED!")


#endregion


#region UI Tests


func test_ui_elements_initialized():
	assert_not_null(map_editor_screen.map_menu_panel, "❌ ERROR: MapMenuPanel missing!")
	assert_not_null(map_editor_screen.toggle_menu_button, "❌ ERROR: ToggleMenuButton missing!")
	assert_not_null(map_editor_screen.cause_menu, "❌ ERROR: causeMenu missing!")
	print("✅ UI Elements initialized successfully!")


func test_open_save_as_popup():
	# Given a title text to set
	var title_text = "Save map as..."

	# Ensure map_name_input and load_save_map_popup_menu are accessible
	assert_true(map_editor_screen.map_name_input != null, "map_name_input should not be null")
	assert_true(map_editor_screen.load_save_map_popup_menu != null, "load_save_map_popup_menu should not be null")

	# When calling the open_save_as_popup function
	map_editor_screen.open_save_as_popup(title_text)

	# Then the popup should be visible
	assert_true(map_editor_screen.load_save_map_popup_menu.visible, "Popup should be visible after calling open_save_as_popup")

	# And the popup title should be updated
	assert_eq(map_editor_screen.load_save_map_popup_title.text, title_text, "Popup title should match the provided title text")

#endregion


#region Helper Functions

func generate_mock_causes() -> Array:
	var mock_causes = []
	
	for i in range(3):  # Create 3 mock causes
		var cause = cause.new()
		cause.cause = "Test Cause %d" % i
		cause.cause_area_type = cause.AreaType.GLOBAL if i % 2 == 0 else cause.AreaType.LOCAL
		cause.cause_tiles = [Vector2(i, i)]
		cause.effects = []  # Empty list for now
		cause.effect_area_type = cause.AreaType.GLOBAL
		cause.effect_tiles = [Vector2(i + 1, i + 1)] as Array[Vector2]
		cause.sound_effect = "sound_%d.ogg" % i
		cause.pop_up_text = "cause %d Activated!" % i

		mock_causes.append(cause)
		generated_causes.append(cause)  # Store the created instance
	
	print("✅ Mock cause Data Generated:", mock_causes)
	return mock_causes


func print_node_tree(node: Node, indent: int = 0):
	var prefix = "  ".repeat(indent)
	print(prefix + "- " + node.name)
	for child in node.get_children():
		print_node_tree(child, indent + 1)

#endregion
