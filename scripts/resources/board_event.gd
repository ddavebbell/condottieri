extends Resource

class_name BoardEvent


@export var name: String = ""
@export var description: String = ""

@export var causes: Array = []
@export var effects: Array = []

@export var sound_effects: Array = []
@export var map_name_event_belongs_to: String = ""


#this formats the Board Event for display
func get_display_name() -> String:
	var cause_str = "None"
	if not causes.is_empty():
		cause_str = str(causes[0])

	var effect_str = "None"
	if not effects.is_empty():
		effect_str = str(effects[0])

	return "%s  |  Cause: %s  |  Effect: %s" % [name, cause_str, effect_str]
