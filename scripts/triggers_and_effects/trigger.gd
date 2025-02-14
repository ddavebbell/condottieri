extends Resource
class_name Trigger

enum AreaType { LOCAL, GLOBAL }

@export var cause: String = ""  # ✅ Default to an empty string to prevent null errors

# ✅ Trigger Area Settings
@export var trigger_area_type: AreaType = AreaType.LOCAL  # ✅ Dropdown in Inspector
@export var trigger_tiles: Array[Vector2] = []  # ✅ List of affected tiles

# ✅ Effects (List of Effect Resources)
@export var effects: Array[Effect] = []  # ✅ Ensure effects is always an array of Effect resources

# ✅ Effect Area Settings
@export var effect_area_type: AreaType = AreaType.GLOBAL  # ✅ Dropdown in Inspector
@export var effect_tiles: Array[Vector2] = []  # ✅ List of tiles affected by the effect

# ✅ Sound & Pop-Up
@export var sound_effect: String = ""  # ✅ Default empty to prevent null issues
@export var pop_up_text: String = ""  # ✅ Default empty to prevent null issues

# ✅ Ensure Effects List is Always Initialized
func _init():
	effects = []  # ✅ Prevents "Invalid assignment" errors when adding effects dynamically
