extends Control

# Placeholder for the list of maps
var map_list = []  

#map_list = [
	#{"name": "Map 1", "thumbnail": preload("res://path/to/thumbnail1.png")},
	#{"name": "Map 2", "thumbnail": preload("res://path/to/thumbnail2.png")}
#]

# UI Nodes
@onready var map_list_container = $MapListContainer  # Scrollable container for map list
@onready var map_thumbnail = $MapThumbnail  # Thumbnail preview
@onready var create_map_button = $CreateMapButton
@onready var delete_map_button = $DeleteMapButton
@onready var open_map_button = $OpenMapButton
@onready var title_label = $TitleLabel

func _ready():
	# Set title
	title_label.text = "Condottieri: Map Creator"

	# Connect button signals
	create_map_button.connect("pressed", Callable(self, "_on_create_map"))
	delete_map_button.connect("pressed", Callable(self, "_on_delete_map"))
	open_map_button.connect("pressed", Callable(self, "_on_open_map"))
	
	# Populate the map list
	_populate_map_list()

func _populate_map_list():
	# Clear the list first
	for child in map_list_container.get_children():
		child.queue_free()

	# Add map entries
	for map_data in map_list:
		var button = Button.new()
		button.text = map_data["name"]
		button.connect("pressed", Callable(self, "_on_map_selected").bind(map_data))
		map_list_container.add_child(button)

func _on_map_selected(map_data):
	# Display the selected map's thumbnail
	map_thumbnail.texture = map_data["thumbnail"]
	map_thumbnail.visible = true

	# Enable "Delete" and "Open" buttons
	delete_map_button.disabled = false
	open_map_button.disabled = false

func _on_create_map():
	# Placeholder for creating a new map
	print("Create Map button pressed")
	# Logic to create a new map goes here

func _on_delete_map():
	# Placeholder for deleting the selected map
	print("Delete Map button pressed")
	# Logic to delete the selected map goes here

func _on_open_map():
	# Placeholder for opening the selected map
	print("Open Map button pressed")
	# Logic to open the selected map goes here
	
func _on_create_map_pressed():
	# Load the Map Editor scene
	var map_editor_scene = preload("res://Main.tscn").instance()
	
	# Switch to the Map Editor
	get_tree().root.add_child(map_editor_scene)
	get_tree().current_scene.queue_free()  # Unload the current scene
	get_tree().current_scene = map_editor_scene
	
	# Call the function to initialize a blank map
	map_editor_scene.call("load_new_map")
	print("Switched to Map Editor with a new blank map.")


func _on_create_map_button_pressed():
	# Load the Map Editor scene
	var map_editor_scene = load("res://Main.tscn").instantiate()
	# Switch to the Map Editor
	get_tree().root.add_child(map_editor_scene)
	get_tree().current_scene.queue_free()  # Unload the current scene
	get_tree().current_scene = map_editor_scene
	# Call the function to initialize a blank map
	print("Switched to Map Editor with a new blank map.")
