extends Resource
class_name BoardEvent


@export var name: String = ""
@export var description: String = ""

@export var cause: Cause = null
@export var effect: Effect = null

@export var sound_effect: String = ""
@export var map_name_event_belongs_to: String = ""


# this formats the Board Event for display
func get_display_name() -> String:
	var cause_str := "None"
	if cause is Cause:
		if cause.local_cause != Cause.LocalCause.NONE:
			cause_str = Cause.LocalCause.keys()[cause.local_cause]
		elif cause.global_cause != Cause.GlobalCause.NONE:
			cause_str = Cause.GlobalCause.keys()[cause.global_cause]

	var effect_str := "None"
	if effect is Effect and effect.effect_type != Effect.EffectType.NONE:
		effect_str = Effect.EffectType.keys()[effect.effect_type]

	return "%s  |  Cause: %s  |  Effect: %s" % [name, cause_str, effect_str]
