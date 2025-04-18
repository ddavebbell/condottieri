extends Resource
class_name MapTile

enum MapTileTypeEnum {
	GRASS,
	WATER,
	TRAP,
	MOUNTAIN,
	HEAL_PAD
}

# === Identification ===
@export var tile_type: MapTileTypeEnum = MapTileTypeEnum.GRASS 
@export var is_passable: bool = true
@export var is_visible: bool = true

# === Interaction & Triggers ===
@export var local_cause: Cause.LocalCause = Cause.LocalCause.NONE
@export var attached_board_event: BoardEvent = null  # Optional direct link

# === Visual / Theme Related ===
@export var tile_texture: Texture2D = null
@export var tile_position: Vector2i = Vector2i.ZERO

# === Gameplay Specific (Optional) ===
@export var trap_damage: int = 0
@export var score_bonus: int = 0
