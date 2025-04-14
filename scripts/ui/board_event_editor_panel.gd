extends Control

class_name BoardEventEditorScreen

const SOUND_EFFECTS_DIR := "user://sound_effects"

signal board_event_editor_close_requested

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


var board_event: BoardEvent = null
var board_events_array: Array = []  # Store reference to `board events` array
var is_editing: bool = false

# Do we even need these ?  You can probably grab selected from the ItemList
var current_cause: Cause = null  # Stores the active cause
var current_effect: Effect = null # Stores the active effect
var all_causes: Array[Cause] = []
var all_effects: Array[Effect] = []

#endregion


# ------------------------------------------------------------
# 📌 BoardEventEditorScreen Setup Guide
#
# Use these setup methods when opening the BoardEventEditorScreen:
#
# ✅ To create a new board event:
# var popup = main_scene.spawn_popup(main_scene.board_event_editor_screen_scene)
# popup.setup_for_new_event(current_board_events)
#
# ✅ To edit an existing board event:
# var popup = main_scene.spawn_popup(main_scene.board_event_editor_screen_scene)
# popup.setup_for_edit_event(selected_event, current_board_events)
#
# This will ensure the popup loads the correct data,
# sets the right mode (is_editing), and stores a reference
# to the current working array of board events.
# ------------------------------------------------------------


func _ready():
	# Sanity check
	print("🔍 cause_list_container type:", cause_list_container.get_class())
	cause_list_container.set("multiselect", true)
	effect_list_container.set("multiselect", true)  
	
	_setup_sound_fx_browser()
	_generate_all_causes_and_effects()
	_populate_cause_list_container()
	_populate_effect_list_container()
	_get_board_events_from_board_event_manager()
	_preselect_default_ui()
	
	sound_fx_container.item_selected.connect(_on_sound_fx_item_selected)
	sound_fx_preview_button.pressed.connect(_on_sound_fx_preview_button_pressed)
	sound_fx_preview_button.disabled = true  # Disable by default
	sound_fx_browse_button.pressed.connect(func():
		file_dialog.popup_centered()
	)
	connect("board_event_editor_close_requested", Callable(BoardEventManager, "_on_board_event_editor_close_requested"))
	
	UiManager.register_ui("BoardEventEditorScreen", self)


#region Set Up




func setup_for_new_event(board_events_array_ref: Array):
	print("🧱 setup_for_new_event() CALLED") 
	is_editing = false
	board_event = BoardEvent.new()
	board_events_array = board_events_array_ref
	_preselect_default_ui()


func setup_for_edit_event(event: BoardEvent, board_events_array_ref: Array):
	board_event = event
	board_events_array = board_events_array_ref

	# Must wait a frame so UI can finish populating
	await get_tree().process_frame

	_load_event_into_ui()


func _preselect_default_ui():
	# --- Cause List: Select first valid item ---
	for i in cause_list_container.item_count:
		var meta = cause_list_container.get_item_metadata(i)
		if meta != null:
			cause_list_container.select(i)
			break  # ✅ Select only the first valid item
	# (You can remove the break if you want to select more by default)

	# --- Effect List: Select first valid item ---
	for i in effect_list_container.item_count:
		var meta = effect_list_container.get_item_metadata(i)
		if meta != null:
			effect_list_container.select(i)
			break

	# --- Sound FX List: Select first valid item ---
	for i in sound_fx_container.item_count:
		var meta = sound_fx_container.get_item_metadata(i)
		if meta != null:
			sound_fx_container.select(i)
			break

	# --- Clear name and description ---
	board_event_name.text = ""
	board_event_description.text = ""
	sound_fx_folder_browse_line.text = ""


func set_board_event(event: BoardEvent):
	board_event = event
	_load_event_into_ui()


func _load_event_into_ui():
	print("📥 Loading board event into UI:", board_event.name)

	# --- Clear previous selections ---
	cause_list_container.deselect_all()
	effect_list_container.deselect_all()

	# --- Assign name and description ---
	board_event_name.text = board_event.name
	board_event_description.text = board_event.description

	# === CAUSE SELECTION ===
	if board_event.cause != null:
		var target: Cause = board_event.cause
		print("🎯 Cause to match → Local: %s | Global: %s" % [target.local_cause, target.global_cause])

		for i in cause_list_container.item_count:
			var label = cause_list_container.get_item_text(i).strip_edges()
			var candidate: Cause = cause_list_container.get_item_metadata(i)

			if candidate == null or label == "Local Causes" or label == "Global Causes":
				continue

			if candidate.local_cause == target.local_cause or candidate.global_cause == target.global_cause:
				cause_list_container.select(i)
				print("✅ Selected cause index %d → %s" % [i, candidate])
				break

		print("🟦 Selected cause:", cause_list_container.get_selected_items())

	# === EFFECT SELECTION ===
	if board_event.effect != null:
		var target_effect: Effect = board_event.effect
		print("⚡ Effect to match → Type: %s" % str(target_effect.effect_type))

		for i in effect_list_container.item_count:
			var label = effect_list_container.get_item_text(i).strip_edges()
			var candidate: Effect = effect_list_container.get_item_metadata(i)

			if candidate == null or label == "Local Effects" or label == "Global Effects":
				continue

			if candidate.effect_type == target_effect.effect_type:
				effect_list_container.select(i)
				print("✅ Selected effect index %d → %s" % [i, candidate])
				break

		print("🟧 Selected effect:", effect_list_container.get_selected_items())

	# === SOUND FX FIELD (optional) ===
	if board_event.sound_effect != "":
		sound_fx_folder_browse_line.text = board_event.sound_effect








func _get_board_events_from_board_event_manager():
	board_events_array = BoardEventManager.get_board_events()


func _populate_cause_list_container():
	cause_list_container.clear()

	# --- Local Causes ---
	cause_list_container.add_item("Local Causes")
	var idx = cause_list_container.item_count - 1
	cause_list_container.set_item_disabled(idx, true)

	# Add the NONE option explicitly
	var none_local := Cause.new()
	none_local.local_cause = Cause.LocalCause.NONE
	none_local.global_cause = Cause.GlobalCause.NONE  # Just to be clean
	cause_list_container.add_item("  NONE")
	cause_list_container.set_item_metadata(cause_list_container.item_count - 1, none_local)

	for cause in all_causes:
		if cause.local_cause != Cause.LocalCause.NONE:
			var label = "  " + Cause.LocalCause.keys()[cause.local_cause]
			cause_list_container.add_item(label)
			cause_list_container.set_item_metadata(cause_list_container.item_count - 1, cause)

	# --- Global Causes ---
	cause_list_container.add_item("Global Causes")
	idx = cause_list_container.item_count - 1
	cause_list_container.set_item_disabled(idx, true)

	var none_global := Cause.new()
	none_global.global_cause = Cause.GlobalCause.NONE
	none_global.local_cause = Cause.LocalCause.NONE
	cause_list_container.add_item("  NONE")
	cause_list_container.set_item_metadata(cause_list_container.item_count - 1, none_global)

	for cause in all_causes:
		if cause.global_cause != Cause.GlobalCause.NONE:
			var label = "  " + Cause.GlobalCause.keys()[cause.global_cause]
			cause_list_container.add_item(label)
			cause_list_container.set_item_metadata(cause_list_container.item_count - 1, cause)



func _populate_effect_list_container():
	effect_list_container.clear()

	effect_list_container.add_item("Local Effects")
	var idx = effect_list_container.item_count - 1
	effect_list_container.set_item_disabled(idx, true)

	for effect in all_effects:
		if Effect.LocalEffects.has(effect.effect_type):
			var label = "  " + Effect.EffectType.keys()[effect.effect_type]
			effect_list_container.add_item(label)
			effect_list_container.set_item_metadata(effect_list_container.item_count - 1, effect)

	effect_list_container.add_item("Global Effects")
	idx = effect_list_container.item_count - 1
	effect_list_container.set_item_disabled(idx, true)

	for effect in all_effects:
		if Effect.GlobalEffects.has(effect.effect_type):
			var label = "  " + Effect.EffectType.keys()[effect.effect_type]
			effect_list_container.add_item(label)
			effect_list_container.set_item_metadata(effect_list_container.item_count - 1, effect)


func _generate_all_causes_and_effects():
	all_causes.clear()
	all_effects.clear()

	for cause_enum in Cause.LocalCause.values():
		var c = Cause.new()
		c.local_cause = cause_enum
		c.global_cause = Cause.GlobalCause.NONE  # ✅ Safe "null" replacement
		all_causes.append(c)

	for cause_enum in Cause.GlobalCause.values():
		var c = Cause.new()
		c.global_cause = cause_enum
		c.local_cause = Cause.LocalCause.NONE  # ✅ Safe "null" replacement
		all_causes.append(c)

	for effect_enum in Effect.EffectType.values():
		var e = Effect.new()
		e.effect_type = effect_enum
		all_effects.append(e)



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

# Sound effects
func _on_sound_fx_directory_selected(dir_path: String) -> void:
	sound_fx_container.clear()

	var dir = DirAccess.open(dir_path)
	if dir == null:
		push_warning("⚠️ Could not open directory: " + dir_path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	var count := 0

	while file_name != "":
		if not dir.current_is_dir():
			if file_name.ends_with(".wav") or file_name.ends_with(".ogg") or file_name.ends_with(".mp3"):
				sound_fx_container.add_item(file_name)
				sound_fx_container.set_item_metadata(sound_fx_container.item_count - 1, dir_path.path_join(file_name))
				count += 1
		file_name = dir.get_next()

	dir.list_dir_end()

	if count == 0:
		print("🟡 No sound files found in: ", dir_path)
	else:
		print("🎵 Loaded %d sound files from: %s" % [count, dir_path])


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


# Enabled for multiple selection in causes and effects
func _on_ok_button_pressed() -> void:
	print("✅ OK Button Pressed — saving board event.")

	if board_event == null:
		push_error("❌ board_event is null! Cannot save.")
		return

	# === SINGLE CAUSE ===
	var selected_cause_index = cause_list_container.get_selected_items().front()
	if selected_cause_index == null:
		print("⚠️ No cause selected — selecting first by default.")
		selected_cause_index = 0
		cause_list_container.select(0)

	board_event.cause = cause_list_container.get_item_metadata(selected_cause_index)
	print("🎯 Cause selected →", board_event.cause)

	# === SINGLE EFFECT ===
	var selected_effect_index = effect_list_container.get_selected_items().front()
	if selected_effect_index == null:
		print("⚠️ No effect selected — selecting first by default.")
		selected_effect_index = 0
		effect_list_container.select(0)

	board_event.effect = effect_list_container.get_item_metadata(selected_effect_index)
	print("⚡ Effect selected →", board_event.effect)

	# === OTHER FIELDS ===
	board_event.name = board_event_name.text
	board_event.description = board_event_description.text
	board_event.sound_effect = sound_fx_folder_browse_line.text

	# === SAVE ===
	if not is_editing:
		print("✨ Adding new board event to manager and list")
		BoardEventManager._add_board_event(board_event)
		board_events_array.append(board_event)
	else:
		print("🛠️ Editing existing board event — updated in place")

	# === CLOSE ===
	emit_signal("board_event_editor_close_requested")
	UiManager.close_ui("BoardEventEditorScreen")




func _on_cancel_button_pressed():
	print("🚫 Cancel Button Pressed. Closing without saving board_event.")
	
	UiManager.close_ui("BoardEventEditorScreen")


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
