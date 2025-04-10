extends Resource
class_name Effect 



enum EffectType {
	SPAWN_REINFORCEMENTS,
	UPGRADE_PIECE,
	REMOVE_PIECE,
	ACTIVATE_TRAP,
	REVEAL_HIDDEN_TILES,
	CHANGE_TILE_TYPE,
	ADD_TIME_BONUS,
	REDUCE_TIME,
	INCREASE_SCORE,
	DECREASE_SCORE,
	AI_AGGRESSION,
	SPAWN_ENEMIES,
	END_LEVEL
}

# Local vs Global Effect categorization
const LocalEffects = [
	EffectType.SPAWN_REINFORCEMENTS, # Adds extra pieces
	EffectType.UPGRADE_PIECE,		# Promote Pawn → Queen
	EffectType.REMOVE_PIECE,		# Kill a piece
	EffectType.ACTIVATE_TRAP,		# Cause a trap effect
	EffectType.REVEAL_HIDDEN_TILES,	# Make hidden tiles visible
	EffectType.CHANGE_TILE_TYPE,	# Convert a tile into something else
	EffectType.SPAWN_ENEMIES		# Adds enemy pieces
]

const GlobalEffects = [
	EffectType.ADD_TIME_BONUS,		# Give extra time
	EffectType.REDUCE_TIME,			# Decrease time left
	EffectType.INCREASE_SCORE,		# Add to the player’s score
	EffectType.DECREASE_SCORE,		# Subtract from the player’s score
	EffectType.AI_AGGRESSION,		# Make AI more aggressive
	EffectType.END_LEVEL			# Win/Lose condition
]


@export var effect_type: EffectType
@export var effect_parameters: Dictionary = {}  # Parameters like piece type, location, etc.
