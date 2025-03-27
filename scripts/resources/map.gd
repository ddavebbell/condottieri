extends Resource

class_name Map


# === Metadata ===
@export var name: String = "New Map"
@export var thumbnail: Texture2D

@export var description: String = ""		# Future functionality
@export var version: int = 1    			# Future functionality
@export var tags: Array[String] = []		# Future functionality

# === Core Data ===
@export var tiles: Dictionary = {}        # From GridManager
@export var board_events: Dictionary = {}    # From BoardEventManager
@export var pieces: Dictionary = {}          # From PieceManager

#@icon("res://path_to_icon/map_icon.svg") # Optional: icon for the resource



func _init():
	name = ""
	thumbnail = null
	tiles = {}
	board_events = {}


## Saving Example:
	#var map = Map.new()
	#map.name = "Custom Map 01"
	#map.map_data = grid_manager.get_map_data()
	#map.board_events = board_event_manager.get_all_events()
	#map.thumbnail = generate_thumbnail() # Or assign from a screenshot
	
	#ResourceSaver.save("user://maps/custom_map_01.tres", map)
