extends Resource
class_name Trigger

enum AreaType { LOCAL, GLOBAL }

@export var cause: String  # What triggers this? (e.g., "Piece Captured", "Turn Count")

# Trigger Area Settings
@export var trigger_area_type: AreaType = AreaType.LOCAL  # Dropdown in Inspector
@export var trigger_tiles: Array[Vector2] = []  # List of affected tiles

# Effects (List of Effect Resources)
@export var effects: Array[Resource] = []  # Array of Effect resources

# Effect Area Settings
@export var effect_area_type: AreaType = AreaType.GLOBAL  # Dropdown in Inspector
@export var effect_tiles: Array[Vector2] = []  # List of tiles affected by the effect

# Sound & Pop-Up
@export var sound_effect: String  # Name of sound to play
@export var pop_up_text: String  # Text for pop-up
