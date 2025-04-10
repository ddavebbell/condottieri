extends Control

class_name BoardEventEditorScreen

const SOUND_EFFECTS_DIR := "user://sound_effects"

#region Variables

@onready var effect_list_container = $Popups/BackgroundPanel/Padding/MainLayout/HBoxContainerB/HBoxContainerL/EffectPanel/MarginContainer/EffectSelection/ScrollContainer/EffectListContainer
@onready var cause_list_container = $Popups/BackgroundPanel/Padding/MainLayout/HBoxContainerB/HBoxContainerL/CausePanel/MarginContainer/VBoxContainer/ScrollContainer/CauseListContainer

@onready var sound_fx_browse_button = $Popups/BackgroundPanel/Padding/MainLayout/HBoxContainerT/SoundEffectPanel/MarginContainer/SoundEffect/VBoxContainer2/BrowseButton
@onready var sound_fx_container = $Popups/BackgroundPanel/Padding/MainLayout/HBoxContainerT/SoundEffectPanel/MarginContainer/SoundEffect/VBoxContainer/SoundEffectDropdown/SoundFXListContainer
@onready var sound_fx_folder_browse_line = $Popups/BackgroundPanel/Padding/MainLayout/HBoxContainerT/SoundEffectPanel/MarginContainer/SoundEffect/VBoxContainer/SFXLineEdit
@onready var sound_fx_player = $AudioStreamPlayer2D
@onready var sound_fx_preview_button = $Popups/BackgroundPanel/Padding/MainLayout/HBoxContainerT/SoundEffectPanel/MarginContainer/SoundEffect/VBoxContainer2/PreviewSFXButton


@onready var board_event_description = $Popups/BackgroundPanel/Padding/MainLayout/HBoxContainerT/DescriptionInputPanel/MarginContainer/HBoxContainer/VBoxContainerR/DescriptionInput
@onready var board_event_name = $Popups/BackgroundPanel/Padding/MainLayout/HBoxContainerT/DescriptionInputPanel/MarginContainer/HBoxContainer/VBoxContainerR/NameInput
@onready var file_dialog: FileDialog = $FileDialog



var board_event_manager: BoardEventManager
var causes_ref: Array = []  # Store reference to `causes` array
var current_cause: Cause = null  # Stores the active cause

#endregion


func _ready():
	_setup_sound_fx_browser()
	_populate_cause_list_container()
	_populate_effect_list_container()
	
	sound_fx_container.item_selected.connect(_on_sound_fx_item_selected)
	sound_fx_preview_button.pressed.connect(_on_sound_fx_preview_button_pressed)
	sound_fx_preview_button.disabled = true  # Disable by default
	sound_fx_browse_button.pressed.connect(func():
		file_dialog.popup_centered()
	)
	
	


#region Set Up

func _populate_cause_list_container():
	# Clear previous items
	cause_list_container.clear()

	# Add unselectable header: "Local Causes"
	cause_list_container.add_item("Local Causes")
	var idx = cause_list_container.get_item_count() - 1
	cause_list_container.set_item_disabled(idx, true)

	# Add LocalCause items
	for cause_key in Cause.LocalCause.keys():
		cause_list_container.add_item("  " + cause_key)
		idx = cause_list_container.get_item_count() - 1
		cause_list_container.set_item_metadata(idx, {
			"type": "Local",
			"value": Cause.LocalCause[cause_key]
		})

	# Add unselectable header: "Global Causes"
	cause_list_container.add_item("Global Causes")
	idx = cause_list_container.get_item_count() - 1
	cause_list_container.set_item_disabled(idx, true)

	# Add GlobalCause items
	for cause_key in Cause.GlobalCause.keys():
		cause_list_container.add_item("  " + cause_key)
		idx = cause_list_container.get_item_count() - 1
		cause_list_container.set_item_metadata(idx, {
			"type": "Global",
			"value": Cause.GlobalCause[cause_key]
		})


func _populate_effect_list_container():
	# Clear previous items
	effect_list_container.clear()

	# Add unselectable header: Local Effects
	effect_list_container.add_item("Local Effects")
	var idx = effect_list_container.get_item_count() - 1
	effect_list_container.set_item_disabled(idx, true)

	# Add local effects
	for effect_value in Effect.LocalEffects:
		var effect_key = Effect.EffectType.find_key(effect_value)
		effect_list_container.add_item("  " + effect_key)
		idx = effect_list_container.get_item_count() - 1
		effect_list_container.set_item_metadata(idx, {
			"type": "Local",
			"value": effect_value
		})

	# Add unselectable header: Global Effects
	effect_list_container.add_item("Global Effects")
	idx = effect_list_container.get_item_count() - 1
	effect_list_container.set_item_disabled(idx, true)

	# Add global effects
	for effect_value in Effect.GlobalEffects:
		var effect_key = Effect.EffectType.find_key(effect_value)
		effect_list_container.add_item("  " + effect_key)
		idx = effect_list_container.get_item_count() - 1
		effect_list_container.set_item_metadata(idx, {
			"type": "Global",
			"value": effect_value
		})


func _setup_sound_fx_browser():
	var global_sfx_path := ProjectSettings.globalize_path(SOUND_EFFECTS_DIR)
	print("Global SFX Path: ", global_sfx_path)

	# Check if the directory exists, and create it if needed
	if not DirAccess.dir_exists_absolute(global_sfx_path):
		var err := DirAccess.make_dir_recursive_absolute(global_sfx_path)
		if err != OK:
			push_error("Failed to create sound_effects directory at: " + global_sfx_path)
			return
		else:
			print("Created sound_effects folder")

	# Set the folder path display
	sound_fx_folder_browse_line.text = _abbreviate_path(global_sfx_path)
	sound_fx_folder_browse_line.tooltip_text = global_sfx_path
	sound_fx_folder_browse_line.editable = false
	sound_fx_folder_browse_line.focus_mode = Control.FOCUS_NONE
	print("LineEdit display set to: ", sound_fx_folder_browse_line.text)

	# Load sounds from the default folder
	_on_sound_fx_directory_selected(global_sfx_path)

	# Setup the FileDialog to use internal user storage
	file_dialog.access = FileDialog.ACCESS_USERDATA
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	file_dialog.current_dir = global_sfx_path

	sound_fx_browse_button.pressed.connect(func():
		file_dialog.popup_centered()
	)

	file_dialog.dir_selected.connect(_on_sound_fx_directory_selected)




# abbreviates the folder path for easier display
func _abbreviate_path(full_path: String, folder_depth: int = 2) -> String:
	var parts = full_path.split("/")
	print("Path parts:", parts)
	if parts.size() <= folder_depth:
		return full_path
	var abbreviated = "..." + "/" + "/".join(parts.slice(parts.size() - folder_depth, parts.size()))
	print("Abbreviated to:", abbreviated)
	return abbreviated



#endregion








#region Event Handlers

func _on_sound_fx_directory_selected(dir_path: String):
	# Update the LineEdit with the selected path
	sound_fx_folder_browse_line.text = dir_path

	# Clear previous items
	sound_fx_container.clear()

	# Open and scan the selected directory
	var dir = DirAccess.open(dir_path)
	if dir == null:
		push_error("Could not open directory: " + dir_path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var ext = file_name.get_extension().to_lower()
			if ext in ["wav", "mp3", "ogg"]:
				sound_fx_container.add_item(file_name)
				sound_fx_container.set_item_metadata(
					sound_fx_container.get_item_count() - 1,
					dir_path.path_join(file_name)
				)
		file_name = dir.get_next()
	dir.list_dir_end()

	# Disable preview button until user selects an item
	sound_fx_preview_button.disabled = true
	sound_fx_preview_button.text = "Preview"


func _on_sound_fx_item_selected(index: int):
	# Enable the preview button and reset its text
	sound_fx_preview_button.disabled = false
	sound_fx_preview_button.text = "Preview"

	# Optional: preload the stream (not necessary unless you want extra features)
	var sound_path = sound_fx_container.get_item_metadata(index)
	var stream = load(sound_path)
	if stream is AudioStream:
		sound_fx_player.stream = stream
	else:
		push_warning("Selected file is not a valid audio stream: " + sound_path)
		sound_fx_preview_button.disabled = true


func _on_sound_fx_preview_button_pressed():
	var selected = sound_fx_container.get_selected_items()
	if selected.is_empty():
		push_warning("No sound effect selected.")
		return

	var index = selected[0]
	var sound_path = sound_fx_container.get_item_metadata(index)

	if not FileAccess.file_exists(sound_path):
		push_error("Sound file does not exist: " + sound_path)
		return

	# If already playing, stop it (toggle behavior)
	if sound_fx_player.playing:
		sound_fx_player.stop()
		sound_fx_preview_button.text = "Preview"
	else:
		var stream = load(sound_path)
		if stream is AudioStream:
			sound_fx_player.stream = stream
			sound_fx_player.play()
			sound_fx_preview_button.text = "Stop"
		else:
			push_warning("Invalid sound file format.")


func _on_cancel_button_pressed():
	print("🚫 Cancel Button Pressed. Closing without saving.")
	emit_signal("board_event_editor_close_requested")
	self.queue_free()



#func _show_error_popup(message: String):
	#var popup = AcceptDialog.new()
	#popup.dialog_text = message
	#add_child(popup)
	#popup.popup_centered()


#func _on_add_effect_button_pressed():
	#print("➕ Adding New Effect...")
#
	## Create a new Effect instance
	#var effect = Effect.new()
	#effect.effect_type = Effect.EffectType.SPAWN_REINFORCEMENTS  ## Default effect type
#
	## Create UI elements for the effect
	#var effect_ui = _create_effect_ui(effect)
	#print("_add_effect_ effect_ui",effect_ui)
	## Add UI to the Effect List
	#effect_list_container.add_child(effect_ui)
	#print("AA effect_list_container children", effect_list_container.get_children())
	#effect_ui.add_to_group("effect_ui")
#
	## Store effect in current cause
	#current_cause.effects.append(effect)
	#print("current_cause.effects", current_cause.effects)
	#print("✅ Effect Added to List:", effect.effect_type)


#endregion

# _on_close_button_pressed -> Not hooked up to anything

#func _on_close_button_pressed():
	#print("❌ Close button pressed. Closing without saving.")
	#emit_signal("board_event_editor_close_requested")
	#queue_free()
