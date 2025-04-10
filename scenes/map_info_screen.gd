extends Control

const MUSIC_DIR = "user://map_music/"

@onready var music_file_dialog = $FileDialog
@onready var map_title = $MarginContainer/VBoxContainer/HBoxContainer/MapTitle
@onready var map_description_panel = $MarginContainer/VBoxContainer/HBoxContainer3/MapDescriptionPanel
@onready var bg_map_music_lineedit = $MarginContainer/VBoxContainer/HBoxContainer2/BGMapMusicLineEdit
@onready var browse_button = $MarginContainer/VBoxContainer/HBoxContainer2/BrowseButton

@onready var ok_button = $MarginContainer/VBoxContainer/ButtonsHBox/OKButton
@onready var cancel_button = $MarginContainer/VBoxContainer/ButtonsHBox/CancelButton

var current_map: Map = null

signal popup_closed


func _ready() -> void:
	UiManager.register_ui("MapInfoScreen", self)
	current_map = MapManager.get_current_map()
	_populate_ui()
	_setup_music_file_dialog()
	

func _setup_music_file_dialog():
	# Ensure music folder exists
	var dir = DirAccess.open("user://")
	if not dir.dir_exists(MUSIC_DIR):
		dir.make_dir(MUSIC_DIR)

	# Configure FileDialog
	music_file_dialog.access = FileDialog.ACCESS_USERDATA
	music_file_dialog.current_dir = MUSIC_DIR
	music_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	music_file_dialog.filters = PackedStringArray(["*.wav", "*.ogg", "*.mp3"])


func _populate_ui():
	if current_map:
		map_title.text = current_map.name
	else:
		map_title.text = "Untitled Map"
		
	if map_description_panel.text:
		map_description_panel.text = current_map.description



#region EventHandlers


func _on_cancel_button_pressed() -> void:
	# go back to previous screen
	UiManager.deregister_ui("MapInfoScreen")
	emit_signal("popup_closed")
	self.call_deferred("queue_free")


func _on_ok_button_pressed() -> void:
	#pass on the information present in the UI and add it onto the current_map
	current_map.description = map_description_panel.text
	current_map.bg_music_filepath = bg_map_music_lineedit.text
	
	# ? tell UIManager to spawn MapEditorScreen, or if this is a popup then the main scene should already be loaded here
	UiManager.deregister_ui("MapInfoScreen")
	
	# signal that this is closing so the current_map can be refreshed in map_editor_screen
	emit_signal("popup_closed")
	
	self.call_deferred("queue_free")


func _on_browse_button_pressed():
	#music_file_dialog.current_dir = MUSIC_DIR
	music_file_dialog.popup_centered()


func _on_music_file_dialog_file_selected(path: String):
	# Only store the filename (not full path)
	var file_name = path.get_file()
	bg_map_music_lineedit.text = file_name



#endregion
