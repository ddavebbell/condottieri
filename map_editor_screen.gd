extends Control 

var map_data = {}  # Store loaded map data
var selected_trigger = null  # Stores the currently selected trigger for editing
var triggers: Array = []  # ✅ Store created triggers in memory

@onready var first_selection_screen = null

## Confirmation Popup
@onready var confirmation_label = $MapEditorPopUp/ConfirmationPopUp/MarginContainer/VBoxContainer/ConfirmationMessage
@onready var confirmation_popup = $MapEditorPopUp/ConfirmationPopUp

@onready var current_filename: String = ""  # Tracks the current map file name

## Pop Up Components Referenced  ##
@onready var load_save_map_popup_scene = $MapEditorPopUp  # Reference to the popup scene
@onready var load_save_map_popup_menu = $MapEditorPopUp/LoadSaveMapPopUp
@onready var load_save_map_popup_title = $MapEditorPopUp/LoadSaveMapPopUp/MarginContainer/VBoxContainer/PopUpTitle
	
## Menu Stuff ##
@onready var map_name_input = $MapEditorPopUp/LoadSaveMapPopUp/MarginContainer/VBoxContainer/MapNameInput
@onready var map_menu_panel = $MapMenuPanel  # Reference the panel
@onready var toggle_menu_button = $ToggleMapMenuButton  # Reference the button
@onready var grid_container = $HSplitContainer/MarginContainer/MainMapDisplay/GridContainer  # Reference to GridContainer

## Trigger Variables ##
@onready var trigger_menu = $HSplitContainer/SideMenu/TerrainMenuWrapper/MenuWrapper/TriggerMenu
@onready var trigger_list = $HSplitContainer/SideMenu/TerrainMenuWrapper/MenuWrapper/TriggerMenu/MarginContainer/ScrollContainer/TriggerList
@onready var create_trigger_button = $HSplitContainer/SideMenu/TerrainMenuWrapper/MenuWrapper/TriggerMenu/MarginContainer/HBoxContainer/CreateTriggerButton

@onready var trigger_manager_scene = preload("res://scenes/TriggerManager.tscn")  # ✅ Load the SCENE, not the script
var trigger_manager = null  # ✅ Will store the actual instance


func _ready():
	add_to_group("MapEditor")  # ✅ Ensures MapEditor is in the correct group
	print("🚀 MapEditor added to group 'MapEditor'!")  # ✅ Debug message
	
	first_selection_screen = get_tree().get_root().get_node_or_null("FirstSelectionScreen")
	
	for child in get_children():
		print("- ", child.name)
		
	if grid_container:
		print("✅ GridContainer found:", grid_container)
	else:
		print("❌ ERROR: GridContainer NOT FOUND in MapEditor!")
	
	
	if has_signal("triggers_loaded"):
		print("✅ `triggers_loaded` signal exists. Calling it manually...")
		_on_triggers_loaded([])
	else:
		print("❌ ERROR: `triggers_loaded` signal is missing!")
	# ✅ Check if GridContainer Exists
	if has_node("GridContainer"):
		print("✅ GridContainer FOUND inside MapEditor:", get_node("GridContainer"))
	else:
		print("❌ ERROR: GridContainer NOT FOUND inside MapEditor!")

	
	if not first_selection_screen:
		print("❌ ERROR: Could not find FirstSelectionScreen in scene tree!")
	else:
		print("✅ FirstSelectionScreen Found:", first_selection_screen)
	
	var ui_layers = get_tree().get_nodes_in_group("UI")
	if ui_layers.size() == 0:
		print("❌ ERROR: UI Layer missing! Creating one now...")
		var ui_layer = Control.new()
		ui_layer.name = "UI"
		get_tree().get_root().add_child(ui_layer)
		ui_layer.add_to_group("UI")
		print("✅ UI Layer created in MapEditor")
	
	## load map and triggers
	if grid_container.has_signal("map_loaded"):
		grid_container.connect("map_loaded", Callable(self, "_on_map_loaded"))
		
	if grid_container:
		grid_container.connect("triggers_loaded", Callable(self, "_on_triggers_loaded"))
		print("✅ Connected `triggers_loaded` signal from GridContainer.")
	
	await get_tree().process_frame  # Wait to ensure nodes are loaded

	if load_save_map_popup_scene and grid_container:
		load_save_map_popup_scene.set_grid_container(grid_container)  # ✅ Pass grid_container reference
	else:
		print("❌ ERROR: Could not find MapEditorPopUp or grid container")
	
	print("current filename is..... ",current_filename)
	
	load_save_map_popup_scene.visible = false  # Ensure the pop-up is hidden initially
	map_menu_panel.visible = false  # Hide the menu by default
	map_menu_panel.position = Vector2(7, 900)  # Move below the screen


		##     ##       ##     ##
		## Trigger Logic stuff ##
		##     ##       ##     ##


func _load_triggers(trigger_data: Array):
	print("🔄 Loading Triggers...")

	triggers.clear()

	for data in trigger_data:
		var new_trigger = Trigger.new()
		new_trigger.cause = data["cause"]
		new_trigger.trigger_area_type = data["trigger_area_type"]

		# ✅ Ensure trigger_tiles is an Array before assigning
		new_trigger.trigger_tiles = data.get("trigger_tiles", []) if data.get("trigger_tiles", []) is Array else []
		
		new_trigger.sound_effect = data.get("sound_effect", "")
		new_trigger.effects = _deserialize_effects(data.get("effects"))

		triggers.append(new_trigger)  ## ✅ Add to memory

	print("✅ All triggers loaded into memory:", triggers.size())


func _deserialize_effects(effect_data: Array) -> Array:
	var effects = []
	for data in effect_data:
		var effect = Effect.new()
		effect.effect_type = data["effect_type"]
		effect.effect_parameters = data["effect_parameters"]
		effects.append(effect)
	return effects

func _on_triggers_loaded(trigger_data: Array):
	print("📥 Receiving Triggers from GridContainer:", trigger_data.size())

	for trigger in trigger_data:
		_on_trigger_saved(trigger)  # ✅ Add to UI

	print("✅ All triggers added to the menu!")



func _on_create_trigger_pressed():
	print("🚀 BUTTON CLICKED: Create Trigger Pressed!")  # ✅ Debug message

	# ✅ Ensure only one Trigger Manager exists
	if not trigger_manager:
		print("🛠 Creating TriggerManager...")
		trigger_manager = trigger_manager_scene.instantiate()
		add_child(trigger_manager)
		print("✅ TriggerManager ADDED to Scene Tree:", trigger_manager)

	print("🚀 Opening Trigger Editor...")

	# ✅ Ensure only one Trigger Editor exists at a time
	var trigger_editor = preload("res://scenes/TriggerEditorPanel.tscn").instantiate()
	trigger_editor.connect("trigger_saved", Callable(self, "_on_trigger_saved"))
	add_child(trigger_editor)  # ✅ Add Trigger Editor to scene


func _on_trigger_added(button):
	# ✅ Ensure we got a Button
	if not button is Button:
		print("❌ ERROR: Expected a Button but got:", button)
		return

	# ✅ Retrieve the trigger from the button's metadata
	if not button.has_meta("trigger_data"):
		print("❌ ERROR: Button has NO trigger metadata!")
		return
	
	var trigger = button.get_meta("trigger_data")

	# 🔍 Debug: Ensure trigger is valid
	if trigger == null:
		print("❌ ERROR: Extracted Trigger is NULL!")
		return

	print("📥 Received New Trigger:", trigger.cause)

	# ✅ Store trigger in list
	triggers.append(trigger)

	# ✅ Ensure button is properly connected
	button.connect("pressed", Callable(self, "_on_edit_trigger_pressed").bind(button))

	# ✅ Add button to UI
	trigger_list.add_child(button)

	print("✅ Trigger Added to Menu:", trigger.cause)



func _on_edit_trigger_pressed(button: Button):
	# ✅ Ensure button is valid
	if button == null or not button is Button:
		print("❌ ERROR: Expected a Button, but got:", button)
		return

	print("🔍 Button Clicked:", button.text)

	# ✅ Check if button has trigger metadata
	if not button.has_meta("trigger_data"):
		print("❌ ERROR: Button has NO trigger metadata!")
		return
	
	# ✅ Retrieve the stored trigger
	selected_trigger = button.get_meta("trigger_data")

	# 🔍 DEBUG: Ensure selected trigger is valid
	if selected_trigger == null:
		print("❌ ERROR: Extracted Trigger is NULL!")
		return

	print("✅ Extracted Trigger:", selected_trigger, "| Cause:", selected_trigger.cause)

	# ✅ Open Trigger Editor with the selected trigger
	var trigger_editor = preload("res://scenes/TriggerEditorPanel.tscn").instantiate()
	add_child(trigger_editor)
	trigger_editor.setup_trigger(selected_trigger)
	trigger_editor.connect("trigger_saved", Callable(self, "_on_trigger_saved"))
	print("✅ Trigger Editor Opened for Editing")


func _open_trigger_editor(trigger: Trigger = null):
	var trigger_editor = preload("res://scenes/TriggerEditorPanel.tscn").instantiate()
	
	add_child(trigger_editor)

	if trigger:
		trigger_editor.setup_trigger(trigger)  # ✅ Ensure trigger is passed
		trigger_editor._populate_existing_trigger(trigger)  # ✅ Force repopulation
	
	trigger_editor.connect("trigger_saved", Callable(self, "_on_trigger_saved"))
	print("✅ Trigger Editor Opened for:", trigger.cause if trigger else "New Trigger")


func _toggle_trigger_menu():
	trigger_menu.visible = !trigger_menu.visible  # ✅ Show or hide trigger menu

func _on_trigger_saved(trigger):
	if not trigger:
		print("❌ ERROR: Trigger is NULL!")
		return
	
	if trigger not in triggers:
		triggers.append(trigger)  # ✅ Store trigger in memory
		print("✅ Trigger Stored in Memory:", trigger.cause)
	else:
		print("⚠️ Trigger Already Exists:", trigger.cause)
	
	# ✅ Gather effect names
	var effect_names = []
	for e in trigger.effects:
		effect_names.append(Effect.EffectType.keys()[e.effect_type])
	
	# ✅ Format effect summary properly for multiple lines
	var effect_summary = "\n".join(effect_names) if effect_names.size() > 0 else "No Effects"

	# ✅ Define trigger name and type
	var trigger_type_icon = "🌍 Global" if trigger.trigger_area_type == Trigger.AreaType.GLOBAL else "📍 Local"
	var trigger_name = trigger.cause if trigger.cause else "Unnamed Trigger"

	# ✅ Format button text for multiple lines
	var button_text = "Triggers: %s\n%s\n🔽 Effects:\n%s" % [trigger_name, trigger_type_icon, effect_summary]

	# ✅ Create a Button for the New Trigger
	var button = Button.new()
	button.text = button_text
	button.set_meta("trigger_data", trigger)

	# ✅ Enable text wrapping so it doesn’t get cut off
	button.autowrap_mode = TextServer.AUTOWRAP_WORD  # Allow word wrapping
	button.clip_text = false  # Prevent text from being clipped

	# ✅ Connect button to edit function
	button.connect("pressed", Callable(self, "_on_edit_trigger_pressed").bind(button))

	# ✅ Add the button to the trigger list UI
	trigger_list.add_child(button)

	print("✅ Trigger Added to Menu:", button.text)


func _on_select_trigger(button):
	selected_trigger = button.get_meta("trigger_data")  # Retrieve stored trigger data

func _on_map_loaded(map_name):
	print("📂 Map Editor Screen - Current filename set to:", current_filename)
	current_filename = map_name  # ✅ Update map filename


func _on_toggle_map_menu_button_pressed():
	var tween = create_tween()  # Create a new Tween dynamically
	
	if map_menu_panel.visible:
		tween.tween_property(map_menu_panel, "position", Vector2(7, 900), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)  # Slide down
		await tween.finished
		map_menu_panel.visible = false
		toggle_menu_button.text = "Open Menu"  # Change text to Open
	else:
		toggle_menu_button.text = "Close Menu"  # Change text to Close
		map_menu_panel.visible = true
		map_menu_panel.position = Vector2(7, 900)  # Ensure it starts at the bottom
		tween.tween_property(map_menu_panel, "position", Vector2(7, 674), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)  # Slide up
		
func _on_save_as_button_pressed() -> void:
	print("📝 Save As button pressed")
	load_save_map_popup_scene.open_as_save()
	open_save_as_popup("Save map as...")


func _on_save_map_button_pressed():
	print("💾 Save Map button pressed")

	var serialized_triggers = _serialize_triggers()
	
		# ✅ Get existing map data
	var map_data = {
		"triggers": serialized_triggers,
		# Add other existing data that gets saved
	}
	
	if triggers.is_empty():
		print("⚠️ WARNING: No triggers found, saving an empty map!")
	
	# ✅ If the map has NOT been saved before, open Save As pop-up
	if current_filename.is_empty():
		print("🔹 No filename found, opening Save As menu...")
		load_save_map_popup_scene.open_as_save()  # ✅ Open pop-up only if first save
	else:
		# ✅ If the map has a filename, just save it
		print("💾 Saving existing map:", current_filename)
		print("map data before saving.... ", map_data)
		grid_container.save_map(current_filename, map_data)  # ✅ Save directly
		show_confirmation_popup("✅ Map saved successfully!")  # ✅ Show confirmation message
		
	print("📡 Saving Map with Triggers:", serialized_triggers.size())


func _serialize_triggers() -> Array:
	var serialized_triggers = []

	for trigger in triggers:
		var trigger_data = {
			"cause": trigger.cause,
			"trigger_area_type": trigger.trigger_area_type,
			"trigger_tiles": trigger.trigger_tiles,
			"sound_effect": trigger.sound_effect,
			"effects": []
		}

		# ✅ Serialize Effects
		for effect in trigger.effects:
			trigger_data["effects"].append({
				"effect_type": effect.effect_type,
				"effect_parameters": effect.effect_parameters
			})

		serialized_triggers.append(trigger_data)

	print("✅ Serialized Triggers for Save:", serialized_triggers)  # <-- Debug
	return serialized_triggers



func open_save_as_popup(title_text: String):
	if load_save_map_popup_menu and map_name_input:
		map_name_input.text = current_filename if current_filename != "" else ""

		# ✅ Set the correct title for the pop-up
		load_save_map_popup_scene.set_popup_title(title_text)

		# ✅ Open the Save As pop-up
		load_save_map_popup_menu.popup_centered()
		print("📝 Opening Save As pop-up:", title_text)
	else:
		print("❌ ERROR: load_save_map_popup_scene or map_name_input is not set!")


func set_map_data(data):
	map_data = data
	print("Main scene received map data:", map_data)
	
	if grid_container:
		grid_container.load_map_data(map_data)
		
func _on_load_map_button_pressed() -> void:
	print("📂 Load Map button pressed")

	# ✅ Ensure no previous map is auto-selected
	load_save_map_popup_scene.selected_map_name = ""  # Reset selection before opening
	load_save_map_popup_scene.selected_map_button = null  
	
	load_save_map_popup_scene.open_as_load()
	open_load_map_popup("Load Map")

	
	await get_tree().process_frame # ✅ Wait for the user to interact

	# ✅ Retrieve user-selected map from the pop-up AFTER user interaction
	var selected_map_name = load_save_map_popup_scene.get_user_selected_map()
	
	if selected_map_name.is_empty():
		print("⚠️ No map selected! Waiting for user selection.")
		return  # ✅ Stop execution if no map is selected

	# ✅ Load the selected map
	print("✅ Selected map:", selected_map_name)

	if grid_container:
		grid_container.load_map(selected_map_name)
		print("✅ Map loaded successfully:", selected_map_name)

		# ✅ Show confirmation popup after loading
		show_confirmation_popup("📂 Loaded map: " + selected_map_name)

		# ✅ Close the Save/Load Map popup after loading
		await get_tree().process_frame  # ✅ Ensure UI updates before closing
		load_save_map_popup_menu.hide()
		print("🛑 LoadSaveMapPopUp menu hidden after loading!")
	else:
		print("❌ ERROR: grid_container is not set in MapEditorPopUp!")
		load_save_map_popup_scene.display_error("Please select a map before loading.")

func _on_back_to_main_pressed() -> void:
	print("🔙 Returning to Main Screen...")
	
	# Load the main screen scene
	var main_screen_scene = load("res://scenes/FirstSelectionScreen.tscn").instantiate()
	
	# Switch to the main screen
	get_tree().root.add_child(main_screen_scene)
	get_tree().current_scene.queue_free()  # Remove current scene
	get_tree().current_scene = main_screen_scene  # Set new scene


func open_load_map_popup(title_text: String):
	load_save_map_popup_scene.user_selected_map = false  # ✅ Reset selection status
	if load_save_map_popup_menu and load_save_map_popup_title:
		load_save_map_popup_scene.set_popup_title(title_text)
		load_save_map_popup_menu.popup_centered()
		print("📂 Opening Load Map pop-up:", title_text)
	else:
		print("❌ ERROR: load_save_map_popup_scene is not set!")

func show_confirmation_popup(message: String):
	if confirmation_popup and confirmation_label:
		print("✅ Confirmation label found:", confirmation_label.name)
		confirmation_label.text = message
		confirmation_label.show()  # ✅ Make sure it's visible

		# ✅ Ensure the popup is on top
		confirmation_popup.popup_centered()  # Show the popup
		print("✅ Confirmation popup displayed on top:", message)
	else:
		print("❌ ERROR: ConfirmationPopup UI is missing!")
