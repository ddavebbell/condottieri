extends Resource
class_name Cause


enum LocalCause {
	NONE,
	PIECE_CAPTURED,
	PIECE_ENTERS_TILE,
	PIECE_UPGRADED,
	PIECE_SPAWNED,
	TRAP_CAUSED,
	TILE_REVEALED,
	TILE_TYPE_CHANGED,
	PIECE_MOVED,
	REGION_ENTERED
}

enum GlobalCause {
	NONE,
	TURN_COUNT_REACHED,
	SCORE_REACHED,
	TIMER_EXPIRED,
	ABILITY_USED,
	AI_TURN_START,
	PLAYER_TURN_START,
	ALL_ENEMIES_DEFEATED,
	PIECE_REMOVED
}


@export var global_cause: GlobalCause = GlobalCause.ALL_ENEMIES_DEFEATED
@export var local_cause: LocalCause = LocalCause.PIECE_SPAWNED
@export var local_cause_area_tiles: Array = [] 
@export var pop_up_text: String = ""  


func get_display_name() -> String:
	return "%s / %s" % [
		Cause.GlobalCause.keys()[global_cause],
		Cause.LocalCause.keys()[local_cause]
	]
