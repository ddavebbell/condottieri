extends Node

# Responsible for accepting button pressed functions (requests) from MapEditorScreenUI and MapListScreenUI
# contains functions to process Trigger and Effects data: GET (load data), SET (save data), varify functions, helper functions
# Transfers Trigger data --> is unaware of UI


var triggers: Array = []
var active_triggers: Array = []





#region Getter
#This needs fixing
func get_all_triggers() -> Array:
	# Ensure `triggers` array exists
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

#endregion


#region Setter

func add_trigger(trigger: Trigger):
	triggers.append(trigger)
	emit_signal("trigger_added", trigger)

func set_triggers(new_triggers: Array):
	triggers.clear()
	for trigger in new_triggers:
		if trigger is Trigger:
			triggers.append(trigger)
	emit_signal("triggers_loaded")

#endregion


#region Utility

func _format_trigger_button_text(trigger: Trigger) -> String:
	if not trigger:
		return "❌ ERROR: Missing Trigger Data"

	var trigger_name = _get_trigger_name(trigger)
	var effect_summary = _get_effect_summary(trigger.effects)

	return "Triggers: %s\n%s\n🔽 Effects:\n%s" % [trigger_name, effect_summary]

func _get_trigger_name(trigger: Trigger) -> String:
	var cause_value_local = trigger.local_cause
	var cause_value_global = trigger.global_cause
	
	if cause_value_local and not cause_value_global:
		var formatted_cause_name_local = _format_enum_key(cause_value_local)
		return formatted_cause_name_local

	if cause_value_global and not cause_value_local:
		var formatted_cause_name_global = _format_enum_key(cause_value_global)
		return formatted_cause_name_global
	
	return "Unassigned Trigger"

func _get_effect_summary(effects: Array) -> String:
	var names := []

	for e in effects:
		if typeof(e) == TYPE_DICTIONARY and e.has("effect_type"):
			var key = Effect.EffectType.keys()[e.effect_type]
			names.append(_format_enum_key(key))
		elif typeof(e) == TYPE_OBJECT and e is Effect:
			var key = Effect.EffectType.keys()[e.effect_type]
			names.append(_format_enum_key(key))

	if names.is_empty():
		names.append("No Effects")

	return "\n".join(names)

func _format_enum_key(key: String) -> String:
	# Convert "LIKE_THIS" → "Like This"
	var words = key.split("_")
	for i in words.size():
		words[i] = words[i].capitalize()
	return " ".join(words)

# Logic
func _serialize_effects(effects: Array) -> Array:
	var serialized_effects = []
	for effect in effects:
		serialized_effects.append({
			"effect_type": effect.effect_type,
			"effect_parameters": effect.effect_parameters
		})
	return serialized_effects

#endregion
