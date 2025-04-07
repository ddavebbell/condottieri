extends Resource

class_name Trigger


enum LocalCause {
	PIECE_CAPTURED,
	PIECE_ENTERS_TILE,
	PIECE_UPGRADED,
	PIECE_SPAWNED,
	TRAP_TRIGGERED,
	TILE_REVEALED,
	PIECE_REMOVED,
	TILE_TYPE_CHANGED,
	PIECE_MOVED,
	REGION_ENTERED
}

enum GlobalCause {
	TURN_COUNT_REACHED,
	SCORE_REACHED,
	TIMER_EXPIRED,
	ABILITY_USED,
	AI_TURN_START,
	PLAYER_TURN_START,
	ALL_ENEMIES_DEFEATED,
	PIECE_REMOVED,
	PIECE_SPAWNED
}


@export var global_cause: GlobalCause = GlobalCause.TURN_COUNT_REACHED
@export var local_cause: LocalCause = LocalCause.PIECE_SPAWNED
@export var local_cause_area_tiles: Array = [] 
@export var pop_up_text: String = ""  
