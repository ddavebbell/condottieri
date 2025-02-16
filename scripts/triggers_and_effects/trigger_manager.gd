extends Node2D

var triggers = {}
var active_triggers = []  

@onready var ui_layer = null

func _ready():
	var ui_layers = get_tree().get_nodes_in_group("UI")  
	if ui_layers.size() > 0:
		ui_layer = ui_layers[0]  
		print("✅ UI Layer Found:", ui_layer.name)
	else:
		print("❌ ERROR: UI Layer NOT found! Creating one manually...")
		ui_layer = Control.new()
		ui_layer.name = "UI"
		get_tree().get_root().add_child(ui_layer)
		ui_layer.add_to_group("UI")  
		print("✅ New UI Layer Created:", ui_layer.name)

func open_trigger_editor(): 
	var trigger_editor = preload("res://scenes/TriggerEditorPanel.tscn").instantiate()
	if ui_layer:
		ui_layer.add_child(trigger_editor)
		trigger_editor.visible = true
		trigger_editor.z_index = 50  
		trigger_editor.connect("trigger_added", Callable(get_parent(), "_on_trigger_added"))
		print("✅ TriggerEditorPanel Successfully Added to UI!")
	else:
		print("❌ ERROR: UI container not found in MapEditor")

func get_all_triggers() -> Array:
	# ✅ Ensure `triggers` array exists
	if not "triggers" in self:
		triggers = []
	
	var trigger_data = []
	
	# ✅ Convert each trigger into a dictionary
	for trigger in triggers:
		var trigger_dict = {
			"cause": trigger.cause,
			"trigger_area_type": trigger.trigger_area_type,
			"trigger_tiles": trigger.trigger_tiles,
			"sound_effect": trigger.sound_effect,
			"effects": _serialize_effects(trigger.effects)
		}
		trigger_data.append(trigger_dict)
	
	print("✅ Serialized Triggers for Save:", trigger_data)
	return trigger_data

# ✅ Helper function to serialize effects
func _serialize_effects(effects: Array) -> Array:
	var serialized_effects = []
	for effect in effects:
		serialized_effects.append({
			"effect_type": effect.effect_type,
			"effect_parameters": effect.effect_parameters
		})
	return serialized_effects
