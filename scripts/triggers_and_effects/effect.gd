extends Resource
class_name Effect 

enum EffectType {
	SPAWN_REINFORCEMENTS,  # Adds extra pieces
	UPGRADE_PIECE,         # Promote Pawn → Queen
	REMOVE_PIECE,          # Kill a piece
	ACTIVATE_TRAP,         # Trigger a trap effect
	REVEAL_HIDDEN_TILES,   # Make hidden tiles visible
	CHANGE_TILE_TYPE,      # Convert a tile into something else
	ADD_TIME_BONUS,        # Give extra time
	REDUCE_TIME,           # Decrease time left
	INCREASE_SCORE,        # Add to the player’s score
	DECREASE_SCORE,        # Subtract from the player’s score
	AI_AGGRESSION,         # Make AI more aggressive
	SPAWN_ENEMIES,         # Adds enemy pieces
	END_LEVEL,             # Win/Lose condition
}

@export var effect_type: EffectType
@export var effect_parameters: Dictionary = {}  # Parameters like piece type, location, etc.
