extends "res://addons/gut/test.gd"

class_name TestMapEditorScreen

var BaseTestClass := preload("res://tests/base_map_editor_test.gd")
var base_test

var map_editor_screen
var map_editor_popup
var load_save_map_popup_menu
var load_save_map_popup_title
var trigger_manager
var generated_triggers = []

#region Before & After

func before_each():
	# Instantiate and add base_test safely
	if not base_test:
		base_test = BaseTestClass.new()
	if not base_test.is_inside_tree():
		add_child(base_test)

	# Setup map editor and trigger manager
	await base_test._setup_map_editor()
	await base_test._setup_trigger_manager()

	map_editor_screen = base_test.map_editor_screen
	trigger_manager = base_test.trigger_manager

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

		# Clear triggers
		if map_editor_screen.triggers:
			map_editor_screen.triggers.clear()

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

	# Clear generated mock triggers
	generated_triggers.clear()

	# Final cleanup via base_test
	if is_instance_valid(map_editor_screen):
		await base_test._cleanup_node_and_children(map_editor_screen)
	if is_instance_valid(trigger_manager):
		await base_test._cleanup_node_and_children(trigger_manager)

	map_editor_screen = null
	trigger_manager = null

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
	print("✅ Load Map button should trigger pop-up.")


func test_on_map_loaded():
	var mock_map_name = "test_map.json"
	map_editor_screen._on_map_loaded(mock_map_name)
	assert_eq(map_editor_screen.current_filename, mock_map_name, "❌ ERROR: Map filename not stored correctly!")
	print("✅ _on_map_loaded works correctly.")

#endregion


#region Trigger Related Logic

# func test_serialize_triggers():
#     var serialized_triggers = map_editor_screen._serialize_triggers()
#     assert_eq(serialized_triggers.size(), map_editor_screen.triggers.size(), "❌ ERROR: Serialized triggers mismatch!")
#     print("✅ Serialization works.")


# func test_on_edit_trigger_pressed():
#     var mock_button = Button.new()
#     mock_button.set_meta("trigger_data", { "cause": "piece_captured" })
#     map_editor_screen._on_edit_trigger_pressed(mock_button)
#     print("✅ Edit Trigger button works.")

# func test_on_trigger_saved():
#     var mock_trigger = Trigger.new()
#     mock_trigger.cause = "piece_captured"
#     map_editor_screen._on_trigger_saved(mock_trigger)
#     print("✅ Trigger saved successfully.")


func test_on_create_trigger_pressed():
	map_editor_screen._on_create_trigger_pressed()
	assert_not_null(map_editor_screen.trigger_manager, "❌ ERROR: TriggerManager was not created!")
	print("✅ Trigger Manager created successfully.")


func test_on_triggers_loaded():
	var mock_trigger_data = generate_mock_triggers()
	map_editor_screen._on_triggers_loaded(mock_trigger_data)
	assert_eq(map_editor_screen.triggers.size(), generate_mock_triggers().size(), "❌ ERROR: Triggers not loaded correctly!")
	print("✅ Triggers loaded successfully.")
	

func test_on_triggers_loaded_with_valid_triggers():
	print("🔬 Running: test_on_triggers_loaded_with_valid_triggers")

	# Create mock triggers
	var mock_trigger1 = Trigger.new()
	var mock_trigger2 = Trigger.new()

	var trigger_data = [mock_trigger1, mock_trigger2]

	# Call function
	map_editor_screen._on_triggers_loaded(trigger_data)

	# Check if triggers list was updated
	assert_eq(map_editor_screen.triggers.size(), 2, "❌ Triggers were not added correctly!")

	# Ensure UI buttons were updated
	assert_eq(map_editor_screen.trigger_list.get_child_count(), 2, "❌ Trigger List UI buttons not updated!")

	print("✅ test_on_triggers_loaded_with_valid_triggers PASSED!")


func test_on_triggers_loaded_with_invalid_data():
	print("🔬 Running: test_on_triggers_loaded_with_invalid_data")

	# Create mixed invalid data
	var invalid_trigger1 = { "cause": "Invalid", "effects": ["Effect1"] }  # ❌ Dictionary instead of Trigger
	var invalid_trigger2 = 42  # ❌ Integer (completely invalid)
	var invalid_trigger3 = "InvalidString"  # ❌ String (invalid)
	var trigger_data = [invalid_trigger1, invalid_trigger2, invalid_trigger3]

	# Call function
	map_editor_screen._on_triggers_loaded(trigger_data)

	# Ensure no invalid data was added
	assert_eq(map_editor_screen.triggers.size(), 0, "❌ Invalid triggers should not be added!")

	print("✅ test_on_triggers_loaded_with_invalid_data PASSED!")


func test_update_or_add_trigger_button():
	print("🔬 Running: test_update_or_add_trigger_button")

	# Step 1: Ensure trigger_list is empty at start
	assert_eq(map_editor_screen.trigger_list.get_child_count(), 0, "❌ Trigger List should be empty at start!")

	# Step 2: Create a mock trigger
	var mock_trigger = Trigger.new()
	mock_trigger.cause = "Piece Captured"
	mock_trigger.effects = []

	# Step 3: Call function to add the trigger button
	var button = map_editor_screen._update_or_add_trigger_button(mock_trigger)

	# Step 4: Validate button was created
	assert_true(button is Button, "❌ Function did not return a Button!")
	assert_eq(map_editor_screen.trigger_list.get_child_count(), 1, "❌ Trigger List should contain 1 button after first addition!")
	assert_eq(button.get_meta("trigger_data"), mock_trigger, "❌ Button metadata (trigger) does not match!")

	# Step 5: Modify the trigger and update again
	mock_trigger.cause = "Turn Count Reached"
	map_editor_screen._update_or_add_trigger_button(mock_trigger)

	# Step 6: Ensure button text was updated, not duplicated
	assert_eq(map_editor_screen.trigger_list.get_child_count(), 1, "❌ No duplicate buttons should be added!")
	assert_eq(button.text, trigger_manager._format_trigger_button_text(mock_trigger), "❌ Button text was not updated correctly!")

	# Step 7: Add another distinct trigger
	var mock_trigger2 = Trigger.new()
	mock_trigger2.cause = "Piece Enters Tile"
	map_editor_screen._update_or_add_trigger_button(mock_trigger2)

	# Step 8: Validate the new trigger was added
	assert_eq(map_editor_screen.trigger_list.get_child_count(), 2, "❌ Second trigger was not added!")

	print("✅ test_update_or_add_trigger_button PASSED!")


#endregion


#region UI Tests


func test_ui_elements_initialized():
	assert_not_null(map_editor_screen.map_menu_panel, "❌ ERROR: MapMenuPanel missing!")
	assert_not_null(map_editor_screen.toggle_menu_button, "❌ ERROR: ToggleMenuButton missing!")
	assert_not_null(map_editor_screen.trigger_menu, "❌ ERROR: TriggerMenu missing!")
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

func generate_mock_triggers() -> Array:
	var mock_triggers = []
	
	for i in range(3):  # Create 3 mock triggers
		var trigger = Trigger.new()
		trigger.cause = "Test Cause %d" % i
		trigger.trigger_area_type = Trigger.AreaType.GLOBAL if i % 2 == 0 else Trigger.AreaType.LOCAL
		trigger.trigger_tiles = [Vector2(i, i)]
		trigger.effects = []  # Empty list for now
		trigger.effect_area_type = Trigger.AreaType.GLOBAL
		trigger.effect_tiles = [Vector2(i + 1, i + 1)] as Array[Vector2]
		trigger.sound_effect = "sound_%d.ogg" % i
		trigger.pop_up_text = "Trigger %d Activated!" % i

		mock_triggers.append(trigger)
		generated_triggers.append(trigger)  # Store the created instance
	
	print("✅ Mock Trigger Data Generated:", mock_triggers)
	return mock_triggers


func print_node_tree(node: Node, indent: int = 0):
	var prefix = "  ".repeat(indent)
	print(prefix + "- " + node.name)
	for child in node.get_children():
		print_node_tree(child, indent + 1)

#endregion
