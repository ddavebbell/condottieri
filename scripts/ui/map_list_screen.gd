extends Control
class_name MapListScreen

#region NODE REFS

const MAPS_DIR = "user://maps/"

@onready var folder_path_input = $Margin/MainVBox/UpperSection/LeftVBox/MapFolderHBox/FolderPath
@onready var browse_button = $Margin/MainVBox/UpperSection/LeftVBox/MapFolderHBox/BrowseButton
@onready var folder_picker_dialog = $FileDialog

@onready var map_name_input_section = $Margin/MainVBox/LowerSection
@onready var map_name_input = $Margin/MainVBox/LowerSection/LowerSectionLeft/MapNameInput

@onready var map_description_panel = $Margin/MainVBox/UpperSection/RightVBox/DescriptionPanel
@onready var map_tags_panel = $Margin/MainVBox/UpperSection/RightVBox/MapTagsPanel
@onready var map_name_panel = $Margin/MainVBox/UpperSection/RightVBox/MapNamePanel
@onready var map_list_panel = $Margin/MainVBox/UpperSection/LeftVBox/MapListContainer/ScrollContainer/MapList
@onready var title_label = $Margin/MainVBox/TitleLabel
@onready var map_thumbnail = $Margin/MainVBox/UpperSection/RightVBox/Thumbnail

@onready var ok_button = $Margin/MainVBox/ButtonsHBox/OKButton
@onready var cancel_button = $Margin/MainVBox/ButtonsHBox/CancelButton


var map_manager = MapManager
var selected_map: Map = null
var map_files: Array = []
# this gives us actual file for any selected list item
var file_name_map: Array = []

var selected_button: Button = null
var _is_open_map_context: bool = true

signal map_selected(map: Map)

#endregion



#region Set up UI

func _ready():
	## if open map context, connect // set up later
	# Connect Buttons
	ok_button.connect("pressed", Callable(self, "_on_ok_button_pressed"))
	cancel_button.connect("pressed", Callable(self, "_on_cancel_button_pressed"))
	
	# Load Map Context, connecting load folder picker
	folder_picker_dialog.dir_selected.connect(_on_folder_selected)
	_setup_folder_browse()
	
	# For save map context, map name input
	map_name_input.text_changed.connect(_on_map_name_input_text_changed)
	
	_populate_map_list()
	UiManager.register_ui("map_list_screen", self)
	
	
	# debug
	#if OS.has_feature("debug"):
		#print("MapManager.create_test_maps()")
		#MapManager.create_test_maps()
	
	# next new populate_map_list() function
	# call Map Manager to load data from disk (from selected/default map directory) to populate the menus
	# autoselect the first map in the list
	# populate description, and thumbnail from the Map Resource


func _setup_folder_browse():
	var global_maps_path := ProjectSettings.globalize_path(MAPS_DIR)

	# Check if the directory exists, and create it if needed
	if not DirAccess.dir_exists_absolute(global_maps_path):
		var err := DirAccess.make_dir_recursive_absolute(global_maps_path)
		if err != OK:
			push_error("Failed to create maps directory at: " + global_maps_path)
			return

	# Set the folder path input text to the absolute path
	folder_path_input.text = global_maps_path

	# Set the file dialog to start in the maps folder and use internal storage access
	folder_picker_dialog.access = FileDialog.ACCESS_USERDATA
	folder_picker_dialog.current_dir = global_maps_path


func _on_folder_selected(path: String):
	folder_path_input.text = path


func is_open_map_context(is_open: bool) -> void:
	_is_open_map_context = is_open

	if _is_open_map_context:
		title_label.text = "Load Map"
		map_name_input_section.visible = false
	else:
		title_label.text = "Save Map"
		ok_button.text = "Save"
		map_name_input_section.visible = true


## Populate UIs

func _populate_map_list():
	_clear_map_list_ui(map_list_panel)
	ok_button.disabled = true
	
	map_files = MapManager.get_saved_map_files()
	
	## Populates Map List and Descriptions
	for file_name in map_files:
		map_list_panel.add_item(file_name)
		# this gives us actual file for any selected list item
		file_name_map.append(file_name)
		
	_auto_select_first_map()
		
	print("map_files in map_list_screen method:  ", map_files)


# Step 1: This loads the correct Map resource
func _on_map_list_panel_item_selected(index: int) -> void:
	if index < 0 or index >= file_name_map.size():
		push_error("❌ Invalid map selection index")
		return

	var file_name = file_name_map[index]
	var file_path = MAPS_DIR + file_name

	var map_resource = load(file_path)
	if map_resource is Map:
		selected_map = map_resource
		_populate_map_descriptions(map_resource)
		ok_button.disabled = false
	else:
		push_error("❌ Failed to load map from: " + file_path)


# Step 2: Fill the UI
func _populate_map_descriptions(map: Map) -> void:
	_clear_map_descriptions()
	map_name_panel.text = map.name
	map_description_panel.text = map.description
	map_thumbnail.texture = map.thumbnail
	map_tags_panel.text = ", ".join(map.tags)
	print("map_tags_panel.text:   ", map_tags_panel.text)
	#$CreatedDateLabel.text = map.created_date


func _auto_select_first_map():
	if map_list_panel.item_count > 0:
		map_list_panel.select(0)
		_on_map_list_panel_item_selected(0)


func _clear_map_descriptions():
	map_name_panel.clear()
	map_description_panel.clear()
	map_thumbnail.texture = null
	map_tags_panel.clear()
	#$CreatedDateLabel.text = map.created_date


func _clear_map_list_ui(container: Node):
	for child in container.get_children():
		child.queue_free()


#endregion


#region Event Handlers

# If there is not at least 4 characters in map name input, don't enable OK button
func _on_map_name_input_text_changed() -> void:
	if not is_open_map_context:
		var is_it_less_than_five = map_name_input.text.length() < 5
		ok_button.disabled = is_it_less_than_five


func _on_ok_button_pressed():
	print("_on_ok_button_pressed")
	if selected_map == null:
		push_error("❌ No map selected to open.")
		return
	
	#apply_map_metadata_to_current_map()
	
	# LOAD MAP CONTEXT
	# if is_open_map_context:
	# tell map_manager --> to load selected_map
	
	# SAVE MAP CONTEXT
	# if not is_open_map_context:
	# tell map_manager --> to save selected_map
	
	#then clear map list screen scene
	call_deferred("queue_free")
	MapManager.save_map()


# buttons pressed

func _on_browse_button_pressed():
	# unhides file browser window
	folder_picker_dialog.popup_centered()


func _on_cancel_button_pressed():
	# when coming here from MapEditorScreen you will be sent a selected_map object
	if selected_map:
		print("Coming to MapListScreen from MapEditorScreen")
		call_deferred("queue_free") 
	else:
		print("_return_to_title_screen")
		_return_to_title_screen()


func _return_to_title_screen():
	var title_screen = load("res://scenes/TitleScreen.tscn").instantiate()
	call_deferred("queue_free") 
	get_tree().root.add_child(title_screen)




## Logic / Load Save

#region Thumbnail

#func generate_error_thumbnail(map_name: String) -> Texture2D:
	#var error_image = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	#error_image.fill(Color(1, 0, 0, 1))  # 🔴 Red background (error indicator)
	#print("⚠️ Generated error thumbnail for:", map_name)
	#return ImageTexture.create_from_image(error_image)


#func reset_thumbnail():
	#print("🔄 Resetting thumbnail.")
	#if map_thumbnail:
		#map_thumbnail.texture = null  # Fully clear the texture
		#map_thumbnail.visible = false  # Hide the UI element
	#if map_thumbnail_panel:
		#map_thumbnail_panel.visible = false  # Hide the whole panel if needed
		#print("🔄 Thumbnail preview fully reset.")


#func update_thumbnail(map_name: String):
	## ✅ Try to load from selected_map first
	#if selected_map and selected_map.has("thumbnail") and selected_map["thumbnail"] is Texture2D:
		#print("🟢 Using cached thumbnail for:", map_name)
		#map_thumbnail.texture = selected_map["thumbnail"]
		#map_thumbnail_panel.visible = true
		#map_thumbnail.visible = true
		#return
		#
	#var thumbnail_path = "user://thumbnails/" + map_name + ".png"
	#
	#if FileAccess.file_exists(thumbnail_path):
		#print("❌ Thumbnail file does not exist:", thumbnail_path)
		#reset_thumbnail()
		#return
		#
	#var texture = ImageTexture.new()
	#var image = Image.new()
		#
	#var load_result = image.load(thumbnail_path)
		#
	#if load_result != OK:
		#reset_thumbnail()
		#return
		#
	#texture.create_from_image(image)
	#
	#
	#map_thumbnail.texture = null  # Clear any existing texture
	#await get_tree().process_frame  # Let UI update before setting new texture
	#map_thumbnail.texture = texture
	#map_thumbnail.visible = true  # Ensure the image is visible
	#map_thumbnail_panel.visible = true  # Show panel
	#
	#print("✅ Loaded and displayed thumbnail for:", map_name)

#endregion



#func _place_tiles_on_grid(json_map_data):
	## ✅ Ensure map_data is valid
	#if not json_map_data or typeof(json_map_data) != TYPE_DICTIONARY:
		#print("❌ ERROR: Invalid map data format!")
		#return
	#
	### clear grid before placing tiles
	#if not grid_container:
		#print("❌ Error: GridContainer not found in Map Editor!")
		#return
	#else:
		#grid_container.clear_grid()  # Clear any previous tiles before loading
	#
	### place tiles from JSON on grid
	#if not json_map_data:
		#print("❌ Error loading map data!")
		#return
	#for key in json_map_data["tiles"].keys():
		#var coords = key.split(",")  # 🔹 Convert JSON key back into Vector2
		#var grid_pos = Vector2(coords[0].to_float(), coords[1].to_float())
		#
		#var tile_data = json_map_data["tiles"][key]
		#
		#var tile_texture: Texture2D
		#if "atlas" in tile_data:
			#var atlas_texture = AtlasTexture.new()
			#atlas_texture.atlas = load(tile_data["atlas"])
			#atlas_texture.region = Rect2(tile_data["region"][0], tile_data["region"][1], tile_data["region"][2], tile_data["region"][3])
			#tile_texture = atlas_texture
		#else:
			#tile_texture = load(tile_data["texture"])
			#
		#grid_container.place_tile(grid_pos, tile_texture)
	#return json_map_data


#endregion



#region UTILITY

func apply_map_metadata_to_current_map():
	if MapManager.current_map == null:
		push_error("❌ No current map to update.")
		return

	# Example node paths — update to match your scene
	var name_input = $NameInput
	var desc_input = $DescriptionInput
	var thumbnail_texture = $ThumbnailPreview.texture
	var version = 1  # Or get from a version field if needed

	# Update the current map
	MapManager.current_map.name = name_input.text
	MapManager.current_map.description = desc_input.text
	MapManager.current_map.thumbnail = thumbnail_texture
	MapManager.current_map.version = version
