extends "res://addons/gut/test.gd"

class_name TestcauseManager

var base_test := preload("res://tests/base_map_editor_test.gd").new()
var cause_manager

func before_each():
	await base_test._setup_cause_manager()
	cause_manager = base_test.cause_manager

func after_each():
	await base_test._cleanup_node_and_children(cause_manager)



# FIX
#func test_get_cause_name_returns_title_case():
	#print("🔬 Running: test_get_cause_name_returns_title_case")
#
	#var cause := cause.new()
	#cause.cause = cause.CauseType.PIECE_CAPTURED  # Raw value: "piece_captured", Key: "PIECE_CAPTURED"
#
	#var result = cause_manager._get_cause_name(cause)
#
	#assert_eq(rcaesult, "Piece Captured", "❌ Expected 'Piece Captured' but got '%s'" % result)
#
	#print("✅ test_get_cause_name_returns_title_case PASSED!")
#

func test_get_area_label_returns_correct_label():
	print("🔬 Running: test_get_area_label_returns_correct_label")

	var cause := Cause.new()

	cause.cause_area_type = cause.AreaType.GLOBAL
	assert_eq(cause_manager._get_area_label(cause), "Global", "❌ Area label for GLOBAL incorrect.")

	cause.cause_area_type = cause.AreaType.LOCAL
	assert_eq(cause_manager._get_area_label(cause), "Local", "❌ Area label for LOCAL incorrect.")

	# Simulate an unknown area type
	cause.cause_area_type = -1
	assert_eq(cause_manager._get_area_label(cause), "Unknown", "❌ Area label for unknown type incorrect.")

	print("✅ test_get_area_label_returns_correct_label PASSED!")


func test_get_effect_summary_with_effect_objects():
	print("🔬 Running: test_get_effect_summary_with_effect_objects")

	var effect := Effect.new()
	effect.effect_type = Effect.EffectType.SPAWN_REINFORCEMENTS

	var summary = cause_manager._get_effect_summary([effect])
	assert_string_contains(summary, "Spawn Reinforcements", "❌ Effect summary missing expected formatted effect name.")

	print("✅ test_get_effect_summary_with_effect_objects PASSED!")



func test_get_effect_summary_with_dicts():
	print("🔬 Running: test_get_effect_summary_with_dicts")

	var effect_dict := {"effect_type": Effect.EffectType.SPAWN_REINFORCEMENTS}

	var summary = cause_manager._get_effect_summary([effect_dict])
	assert_string_contains(summary, "Spawn Reinforcements", "❌ Effect summary missing formatted name from dictionary.")

	print("✅ test_get_effect_summary_with_dicts PASSED!")



func test_get_effect_summary_with_no_effects():
	print("🔬 Running: test_get_effect_summary_with_no_effects")

	var summary = cause_manager._get_effect_summary([])
	assert_eq(summary, "No Effects", "❌ Summary should return 'No Effects' when empty.")

	print("✅ test_get_effect_summary_with_no_effects PASSED!")

# FIX
#func test_format_cause_button_text_outputs_expected_string():
	#print("🔬 Running: test_format_cause_button_text_outputs_expected_string")
#
	#var effect := Effect.new()
	#effect.effect_type = Effect.EffectType.SPAWN_REINFORCEMENTS
#
	#var cause := cause.new()
	#cause.cause = cause.CauseType.PIECE_CAPTURED
	#cause.effects = [effect]
	#cause.cause_area_type = cause.AreaType.GLOBAL
#
	#var result = cause_manager._format_cause_button_text(cause)
#
	#assert_string_contains(result, "Piece Captured", "❌ cause name (enum key) not included.")
	#assert_string_contains(result, "Global", "❌ Area label not included.")
	#assert_string_contains(result, "Spawn Reinforcements", "❌ Effect type not included.")
#
	#print("✅ test_format_cause_button_text_outputs_expected_string PASSED!")



func test_get_effect_summary_returns_formatted_effect_names():
	print("🔬 Running: test_get_effect_summary_returns_formatted_effect_names")

	var effect := Effect.new()
	effect.effect_type = Effect.EffectType.SPAWN_REINFORCEMENTS  # Key: "SPAWN_REINFORCEMENTS"

	var summary = cause_manager._get_effect_summary([effect])

	assert_eq(summary, "Spawn Reinforcements", "❌ Expected 'Spawn Reinforcements' but got '%s'" % summary)

	print("✅ test_get_effect_summary_returns_formatted_effect_names PASSED!")
