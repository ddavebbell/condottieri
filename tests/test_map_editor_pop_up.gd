extends "res://addons/gut/test.gd"

class_name TestMapEditorPopUp

var map_editor_popup
var map_editor_screen
var load_save_map_popup_title
var load_save_map_popup_menu
var confirmation_label
var thumbnail_view

func before_each():
	# ✅ Load and instantiate MapEditor scene properly
	var editor_scene = load("res://scenes/MapEditor.tscn") as PackedScene
	assert_true(editor_scene != null, "❌ ERROR: Failed to load MapEditor scene!")

	map_editor_screen = editor_scene.instantiate() as Control
	assert_true(map_editor_screen != null, "❌ ERROR: Failed to instantiate MapEditor!")
	
	add_child(map_editor_screen)
	await get_tree().process_frame  # Ensure the scene tree updates

	# ✅ Load and instantiate MapEditorPopUp scene properly
	var popup_scene = load("res://scenes/map_editor_pop_up.tscn") as PackedScene
	assert_true(popup_scene != null, "❌ ERROR: Failed to load MapEditorPopUp scene!")

	map_editor_popup = popup_scene.instantiate() as Control
	assert_true(map_editor_popup != null, "❌ ERROR: Failed to instantiate MapEditorPopUp!")

	add_child(map_editor_popup)
	await get_tree().process_frame  # Ensure the scene tree updates

	# ✅ Ensure map_editor_popup is properly added
	if map_editor_popup == null:
		push_error("❌ ERROR: map_editor_popup should be instantiated!")

	# ✅ Retrieve required nodes
	load_save_map_popup_menu = map_editor_popup.get_node_or_null("LoadSaveMapPopUp")
	confirmation_label = map_editor_popup.get_node_or_null("ConfirmationPopUp/MarginContainer/VBoxContainer/ConfirmationMessage")

	# ✅ Check if load_save_map_popup_menu was found
	if load_save_map_popup_menu:
		print("✅ Found load_save_map_popup_menu:", load_save_map_popup_menu)
	else:
		push_error("❌ ERROR: load_save_map_popup_menu not found in before_each()!")

	# ✅ Check if confirmation_label was found and hide it for test setup
	if confirmation_label:
		print("✅ Found confirmation_label:", confirmation_label)
		confirmation_label.hide()  # Ensure it's hidden in test setup
	else:
		push_error("❌ ERROR: confirmation_label not found in before_each()!")

	# Retrieve the pop-up title node after adding to the scene tree
	if load_save_map_popup_menu:
		load_save_map_popup_title = load_save_map_popup_menu.get_node_or_null("MarginContainer/VBoxContainer/PopUpTitle")

	if load_save_map_popup_title:
		print("✅ Found load_save_map_popup_title:", load_save_map_popup_title)
	else:
		print("❌ ERROR: load_save_map_popup_title not found!")



	# Additional safety checks
	assert_true(load_save_map_popup_menu != null, "❌ ERROR: Critical UI element load_save_map_popup_menu is missing!")
	assert_true(load_save_map_popup_title != null, "❌ ERROR: Critical UI element load_save_map_popup_title is missing!")


func after_each():
	print("🔄 Running after_each cleanup...")

	# ✅ Free all child nodes inside map_editor_popup
	if map_editor_popup:
		for child in map_editor_popup.get_children():
			child.queue_free()
		map_editor_popup.queue_free()
		map_editor_popup = null  # Prevent dangling reference

	# ✅ Free all child nodes inside map_editor_screen
	if map_editor_screen:
		for child in map_editor_screen.get_children():
			child.queue_free()
		map_editor_screen.queue_free()
		map_editor_screen = null  # Prevent dangling reference

	# ✅ Process a frame to ensure nodes are fully freed before the next test
	await get_tree().process_frame  
	print("✅ after_each() cleanup complete.")
	print("🔎 Remaining Orphans:", get_tree().get_nodes_in_group("Orphans"))



# # # # # # # # # # # # # # # # # # # #  


func test_open_as_save():
	assert_true(load_save_map_popup_menu != null, "LoadSaveMapPopUp should exist before testing.")

	# If null, return early to prevent further errors
	if load_save_map_popup_menu == null:
		return

	# Ensure the popup is hidden before opening
	assert_false(load_save_map_popup_menu.visible, "Pop-up should be hidden before opening.")

	# Call `open_as_save`
	map_editor_popup.open_as_save()
	await get_tree().process_frame  # Ensure UI updates

	# Ensure the popup is visible after calling
	assert_true(load_save_map_popup_menu.visible, "Pop-up should be visible after calling open_as_save().")

	# Ensure the pop-up is in "save" mode
	assert_eq(map_editor_popup.popup_mode, "save", "Pop-up should be in save mode.")

	print("`open_as_save()` test passed successfully!")



func test_open_as_load():
	assert_true(load_save_map_popup_menu != null, "LoadSaveMapPopUp should exist before testing.")

	# If null, return early to prevent further errors
	if load_save_map_popup_menu == null:
		return

	# ✅ Ensure the popup is hidden before opening
	assert_false(load_save_map_popup_menu.visible, "Pop-up should be hidden before opening.")

	# ✅ Call `open_as_load()`
	map_editor_popup.open_as_load()
	await get_tree().process_frame  # Ensure UI updates

	# ✅ Ensure the popup is visible after calling
	assert_true(load_save_map_popup_menu.visible, "Pop-up should be visible after calling open_as_load().")

	# ✅ Ensure the pop-up is in "load" mode
	assert_eq(map_editor_popup.popup_mode, "load", "Pop-up should be in load mode.")

	# ✅ Ensure map selection states are reset
	assert_eq(map_editor_popup.selected_map_name, "", "Selected map name should be reset.")
	assert_eq(map_editor_popup.selected_map_button, null, "Selected map button should be reset.")

	print("✅ `open_as_load()` test passed successfully!")

func test_load_save_map_popup_exists():
	# Ensure the popup menu exists
	assert_true(load_save_map_popup_menu != null, "Save Map pop-up menu should exist.")


func test_get_user_selected_map():
	# ✅ Ensure the function exists
	assert_true(map_editor_popup.has_method("get_user_selected_map"), "MapEditorPopUp should have method `get_user_selected_map`.")

	# ✅ Case 1: No map selected, should return an empty string
	map_editor_popup.selected_map_name = ""  # Ensure no selection
	var result_no_selection = map_editor_popup.get_user_selected_map()
	assert_eq(result_no_selection, "", "Should return an empty string when no map is selected.")

	# ✅ Case 2: A map is selected, should return the selected map name
	map_editor_popup.selected_map_name = "MyAwesomeMap"
	var result_with_selection = map_editor_popup.get_user_selected_map()
	assert_eq(result_with_selection, "MyAwesomeMap", "Should return the selected map name.")

	print("✅ `get_user_selected_map()` test passed successfully!")


## this needs to be updated WHEN save map functionality works
## this function is so wrong!
#func test_on_save_map_button_pressed():
	## Ensure pop-up instance exists
	#assert_true(map_editor_popup != null, "❌ ERROR: MapEditorPopUp should exist before testing!")
#
	## Ensure the title label exists
	#assert_true(load_save_map_popup_title != null, "❌ ERROR: Pop-up title label should exist!")
#
	## Ensure the pop-up starts hidden
	#assert_false(load_save_map_popup_menu.visible, "❌ ERROR: Pop-up should start hidden.")
#
	## If `open_save_as_popup_first_time()` is in `map_editor_screen`, call it from there
	#if map_editor_screen.has_method("open_save_as_popup_first_time"):
		#map_editor_screen.open_save_as_popup_first_time("Save Map As...")
	#else:
		#push_error("❌ ERROR: `open_save_as_popup_first_time` does not exist in `MapEditorPopUp` or `MapEditorScreen`!")
	#await get_tree().process_frame  # Ensure UI updates before checking
#
	## Ensure the title text is set correctly
	#assert_eq(load_save_map_popup_title.text.strip_edges(), "Save Map As...", "❌ ERROR: Pop-up title should be 'Save Map As...'")
#
	## Simulate setting a map name (to simulate an actual save)
	#map_editor_popup.current_filename = "test_map"
#
	## Simulate pressing save again (should NOT open the pop-up)
	#map_editor_screen._on_save_map_button_pressed()
#
	#await get_tree().process_frame  # 🔹 Ensure UI updates before checking
#
	## ✅ Ensure the pop-up does NOT open again (it should just save)
	#assert_false(load_save_map_popup_menu.visible, "❌ ERROR: Pop-up should NOT open after first save!")
#
	#print("✅ `test_on_save_map_button_pressed()` passed successfully!")
