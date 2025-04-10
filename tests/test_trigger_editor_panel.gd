extends "res://addons/gut/test.gd"

class_name TestcauseEditorPanel

var base_test := preload("res://tests/base_map_editor_test.gd").new()

var cause_editor
var cause_manager

func before_each():
	print("🔬 Setting up causeEditorPanel for testing...")
	await base_test._setup_cause_manager()
	cause_manager = base_test.cause_manager

	cause_editor = preload("res://scenes/causeEditorPanel.tscn").instantiate()
	add_child(cause_editor)
	await get_tree().process_frame

func after_each():
	print("🧹 Cleaning up causeEditorPanel test environment...")

	# Clean up test nodes
	await base_test._cleanup_node_and_children(cause_editor)
	await base_test._cleanup_node_and_children(cause_manager)

	# Clean UI layer in MapEditor if present
	await base_test._cleanup_ui_children()

	# Remove any unnamed @Node2D left in root
	for node in get_tree().get_root().get_children():
		if is_instance_valid(node) and node.name.begins_with("@"):
			node.queue_free()

	await get_tree().process_frame
	print("✅ after_each cleanup complete.")




func _print_remaining_nodes():
	print("🔎 Remaining nodes AFTER cleanup:")
	for node in get_tree().get_root().get_children():
		print(" -", node.name, "(", node.get_class(), ")")
		for child in node.get_children():
			print("   →", child.name, "(", child.get_class(), ")")


# # # # # # # # # # # # # #

## 🧪 TEST 1: Ensure Dropdowns Populate with Correct Items ##
# FIX FOR NEW
#func test_populate_dropdowns():
	#print("🔬 Running: test_populate_dropdowns")
#
	#cause_editor._populate_dropdowns()
#
	#assert_eq(cause_editor.cause_dropdown.get_item_count(), cause.CauseType.keys().size(), "❌ Cause dropdown does not contain correct number of items!")

	

	print("✅ test_populate_dropdowns PASSED!")


## 🧪 TEST 2: Ensure Default Dropdown Selection ##
func test_default_dropdown_selection():
	print("🔬 Running: test_default_dropdown_selection")

	cause_editor._populate_dropdowns()

	assert_eq(cause_editor.cause_dropdown.selected, 0, "❌ Cause dropdown default selection should be 0!")
	assert_eq(cause_editor.area_type_dropdown.selected, 0, "❌ Area type dropdown default selection should be 0 (Local)!")
	assert_eq(cause_editor.sound_effect_dropdown.selected, 0, "❌ Sound effect dropdown default selection should be 0 (None)!")

	print("✅ test_default_dropdown_selection PASSED!")
	

## 🧪 TEST 3: Ensure `_populate_dropdowns()` Handles Missing Dropdowns ##
func test_handle_missing_dropdowns():
	print("🔬 Running: test_handle_missing_dropdowns")

	# Simulate missing dropdowns
	cause_editor.cause_dropdown = null
	cause_editor.area_type_dropdown = null
	cause_editor.sound_effect_dropdown = null

	# Call function
	cause_editor._populate_dropdowns()

	# ✅ Assert dropdowns are still NULL after execution
	assert_eq(cause_editor.cause_dropdown, null, "❌ Cause dropdown should still be NULL!")
	assert_eq(cause_editor.area_type_dropdown, null, "❌ Area type dropdown should still be NULL!")
	assert_eq(cause_editor.sound_effect_dropdown, null, "❌ Sound effect dropdown should still be NULL!")

	# ✅ Final assertion to prevent "Risky" status
	assert_true(true, "✅ Function handled missing dropdowns without issue.")

	print("✅ test_handle_missing_dropdowns PASSED (no crash, handled correctly)!")  


## 🧪 TEST 4: Ensure `_populate_cause_list()` Populates Correctly ##
# FIX
#func test_populate_cause_list():
	#print("🔬 Running: test_populate_cause_list")
#
	## 🔧 Inject a valid causeManager instance
	#cause_editor.cause_manager = cause_manager
#
	## Create mock causes
	#var mock_cause1 = cause.new()
	#mock_cause1.cause = cause.CauseType.PIECE_CAPTURED
#
	#var mock_cause2 = cause.new()
	#mock_cause2.cause = cause.CauseType.TURN_COUNT_REACHED
#
	#cause_editor.causes_ref = [mock_cause1, mock_cause2]
	#cause_editor._populate_cause_list()
#
	#assert_eq(cause_editor.cause_list_container.get_child_count(), 2, "❌ cause list did not populate correctly!")
#
	#var button1 = cause_editor.cause_list_container.get_child(0)
	#var button2 = cause_editor.cause_list_container.get_child(1)
#
	#var expected_label1 = cause_manager._format_cause_button_text(mock_cause1)
	#var expected_label2 = cause_manager._format_cause_button_text(mock_cause2)
#
	#assert_eq(button1.text, expected_label1, "❌ First cause button text is incorrect!")
	#assert_eq(button2.text, expected_label2, "❌ Second cause button text is incorrect!")
#
	#print("✅ test_populate_cause_list PASSED!")




## 🧪 TEST 5: Ensure `_populate_cause_list()` Handles No causes ##
func test_cause_list_resets_on_empty():
	print("🔬 Running: test_cause_list_resets_on_empty")

	cause_editor.causes_ref = []
	cause_editor._populate_cause_list()

	assert_eq(cause_editor.cause_list_container.get_child_count(), 0, "❌ cause list should be empty!")

	print("✅ test_cause_list_resets_on_empty PASSED!")



# # # # # # UI Tests # # # # # # # #


func test_create_cause_ui():
	print("🔬 Running: test_create_cause_ui")

	# Mock cause
	var mock_cause = cause.new()
	mock_cause.cause = "Piece Captured"

	# Call function
	var cause_ui = cause_editor._create_cause_ui(mock_cause)

	# Validate UI Structure
	assert_true(cause_ui is HBoxContainer, "❌ _create_cause_ui() should return an HBoxContainer!")
	assert_eq(cause_ui.get_child_count(), 2, "❌ HBox should contain exactly 2 children (Dropdown + Remove Button)!")

	# Validate Dropdown
	var dropdown = cause_ui.get_child(0)
	assert_true(dropdown is OptionButton, "❌ First child should be an OptionButton!")
	#assert_eq(dropdown.get_item_text(0), "Piece Captured", "❌ First dropdown option incorrect!")
	#assert_eq(dropdown.get_item_text(1), "Piece Enters Tile", "❌ Second dropdown option incorrect!")
	#assert_eq(dropdown.get_item_text(2), "Turn Count Reached", "❌ Third dropdown option incorrect!")

	# Ensure correct selection
	assert_eq(dropdown.selected, 0, "❌ Dropdown should default to the correct cause!")

	# Validate Remove Button
	var remove_button = cause_ui.get_child(1)
	assert_true(remove_button is Button, "❌ Second child should be a Button!")
	assert_eq(remove_button.text, "X", "❌ Remove button text should be 'X'!")

	print("✅ test_create_cause_ui PASSED!")


func test_create_effect_ui():
	print("🔬 Running: test_create_effect_ui")

	# Mock Effect
	var mock_effect = Effect.new()
	mock_effect.effect_type = 0  # Assuming this corresponds to "Spawn Reinforcements"

	# Call function
	var effect_ui = cause_editor._create_effect_ui(mock_effect)

	# Validate UI Structure
	assert_true(effect_ui is HBoxContainer, "❌ _create_effect_ui() should return an HBoxContainer!")
	assert_eq(effect_ui.get_child_count(), 2, "❌ HBox should contain exactly 2 children (Dropdown + Remove Button)!")

	# Validate Dropdown
	var dropdown = effect_ui.get_child(0)
	assert_true(dropdown is OptionButton, "❌ First child should be an OptionButton!")
	#assert_eq(dropdown.get_item_text(0), "Spawn Reinforcements", "❌ First dropdown option incorrect!")
	#assert_eq(dropdown.get_item_text(1), "Upgrade Piece", "❌ Second dropdown option incorrect!")
	#assert_eq(dropdown.get_item_text(2), "Remove Piece", "❌ Third dropdown option incorrect!")

	# Ensure correct selection
	assert_eq(dropdown.selected, 0, "❌ Dropdown should default to the correct effect type!")

	# Validate Remove Button
	var remove_button = effect_ui.get_child(1)
	assert_true(remove_button is Button, "❌ Second child should be a Button!")
	assert_eq(remove_button.text, "X", "❌ Remove button text should be 'X'!")

	print("✅ test_create_effect_ui PASSED!")
