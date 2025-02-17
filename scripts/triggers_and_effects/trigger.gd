extends Resource
class_name Trigger

enum AreaType { LOCAL, GLOBAL }

@export var cause: String = ""
@export var trigger_area_type: int = 0  # ✅ Dropdown in Inspector
@export var trigger_tiles: Array = []  # ✅ List of affected tiles
@export var effects: Array = []  # ✅ Ensure effects is always an array of Effect resources
@export var effect_area_type: AreaType = AreaType.GLOBAL  # ✅ Dropdown in Inspector
@export var effect_tiles: Array[Vector2] = []  # ✅ List of tiles affected by the effect
@export var sound_effect: String = ""  
@export var pop_up_text: String = ""  

# ✅ Ensure Effects List is Always Initialized
func _init():
	effects = []
	trigger_tiles = []
	effect_tiles = []
