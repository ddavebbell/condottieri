extends Node2D

# Stores all triggers in a dictionary
var triggers = {}
var active_triggers = []  # List of triggers in the current game

@onready var ui_layer = get_parent().find_child("UI", true, false)


func add_trigger(trigger: Trigger):
	active_triggers.append(trigger)

func check_triggers(event_data: Dictionary):
	for trigger in active_triggers:
		if event_data["cause"] == trigger.cause:
			_execute_trigger(trigger, event_data)

func _execute_trigger(trigger: Trigger, event_data: Dictionary):
	for effect in trigger.effects:
		apply_effect(effect, trigger.effect_area)

func apply_effect(effect: Effect, effect_area: Dictionary):
	match effect.effect_type:
		"Remove Piece":
			remove_piece(effect.effect_parameters)
		"End Level":
			end_level(effect.effect_parameters)
		"Spawn Reinforcements":
			spawn_reinforcements(effect.effect_parameters)
		_:
			print("Effect not implemented:", effect.effect_type)

func remove_piece(params):
	print("Removing piece at", params["location"])

func end_level(params):
	if params["win"]:
		print("Level won!")
	else:
		print("Level lost!")

func spawn_reinforcements(params):
	print("Spawning reinforcements at", params["location"])


func open_trigger_editor():
	var trigger_editor = preload("res://scenes/TriggerEditorPanel.tscn").instantiate()
	
	if ui_layer:
		print("ui_layer found",ui_layer)
		ui_layer.add_child(trigger_editor)  # ✅ Add to UI layer instead of Node2D
		trigger_editor.z_index = 50  # ✅ Forces it to the top layer
	else:
		print("Error: UI container not found in MapEditor")


func remove_trigger(trigger_name: String):
	if triggers.has(trigger_name):
		triggers.erase(trigger_name)
		print("🗑️ Trigger removed:", trigger_name)
	else:
		print("❌ Trigger not found:", trigger_name)

func get_trigger(trigger_name: String) -> Dictionary:
	return triggers.get(trigger_name, {})

func get_all_triggers() -> Dictionary:
	print("🔍 DEBUG: Getting all triggers, current state:", triggers)
	return triggers

func clear_triggers():
	triggers.clear()
	print("🧹 All triggers cleared!")
