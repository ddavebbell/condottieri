extends Control 

var map_data = {}  # Store loaded map data
var selected_trigger = null  # Stores the currently selected trigger for editing
var triggers: Array = []  # ✅ Store created triggers in memory

@onready var first_selection_screen = null
@onready var current_filename: String = ""  # Tracks the current map file name

## Confirmation Popup
@onready var confirmation_label = $MapEditorPopUp/ConfirmationPopUp/MarginContainer/VBoxContainer/ConfirmationMessage
@onready var confirmation_popup = $MapEditorPopUp/ConfirmationPopUp


## Pop Up Components Referenced  ##
@onready var load_save_map_popup_scene = $MapEditorPopUp  # Reference to the popup scene
@onready var load_save_map_popup_menu = $MapEditorPopUp/LoadSaveMapPopUp
@onready var load_save_map_popup_title = $MapEditorPopUp/LoadSaveMapPopUp/MarginContainer/VBoxContainer/PopUpTitle
	
## Menu Stuff ##
@onready var map_menu_panel = $MapMenuPanel  # Reference the panel
@onready var toggle_menu_button = $ToggleMapMenuButton  # Reference the button
@onready var map_name_input = $MapEditorPopUp/LoadSaveMapPopUp/MarginContainer/VBoxContainer/MapNameInput
@onready var grid_container = $HSplitContainer/MarginContainer/MainMapDisplay/GridContainer  # Reference to GridContainer

## Trigger Variables ##
@onready var trigger_menu = $HSplitContainer/SideMenu/TerrainMenuWrapper/MenuWrapper/TriggerMenu
@onready var trigger_list = $HSplitContainer/SideMenu/TerrainMenuWrapper/MenuWrapper/TriggerMenu/MarginContainer/ScrollContainer/TriggerList
@onready var create_trigger_button = $HSplitContainer/SideMenu/TerrainMenuWrapper/MenuWrapper/TriggerMenu/MarginContainer/HBoxContainer/CreateTriggerButton

## trigger editor panel ##
@onready var trigger_editor_screen = preload("res://scenes/TriggerEditorPanel.tscn").instantiate()
@onready var cause_dropdown = trigger_editor_screen.get_node("Popups/BackgroundPanel/Padding/MainLayout/ContentVBox/TriggerSettings/VBoxContainer/CauseDropdown")
@onready var area_type_dropdown = trigger_editor_screen.get_node("Popups/BackgroundPanel/Padding/MainLayout/ContentVBox/AreaAndSound/AreaSelection/AreaTypeDropdown")
@onready var tile_selector = trigger_editor_screen.get_node("Popups/BackgroundPanel/Padding/MainLayout/ContentVBox/AreaAndSound/AreaSelection/TileSelectionCustomNode")
@onready var sound_effect_dropdown = trigger_editor_screen.get_node("Popups/BackgroundPanel/Padding/MainLayout/ContentVBox/AreaAndSound/SoundEffect/SoundEffectDropdown")
@onready var effect_list_container = trigger_editor_screen.get_node("Popups/BackgroundPanel/Padding/MainLayout/ContentVBox/EffectSelection/ScrollContainer/EffectListContainer")



@onready var trigger_manager_scene = preload("res://scenes/TriggerManager.tscn")  # ✅ Load the SCENE, not the script
var trigger_manager = null  # ✅ Will store the actual instance


func _ready():
	add_to_group("MapEditor")  
	print("🚀 MapEditor added to group 'MapEditor'!")

	first_selection_screen = get_tree().get_root().get_node_or_null("FirstSelectionScreen")

	print("📌 Child Nodes in MapEditor:")
	for child in get_children():
		print("- ", child.name)

	# Varification checks
	if grid_container:
		print("✅ GridContainer found:", grid_container)
	else:
		print("❌ ERROR: GridContainer NOT FOUND in MapEditor!")

	if first_selection_screen:
		print("✅ FirstSelectionScreen Found:", first_selection_screen)
	else:
		print("❌ ERROR: Could not find FirstSelectionScreen in scene tree!")
		
	await get_tree().process_frame  # ✅ Allow nodes to load before proceeding
	_ensure_ui_layer() 	# ✅ Ensure UI Layer exists
	_connect_signals() 	# ✅ Connect signals
	_setup_ui() # ✅ Ensure pop-ups and UI elements are set correctly

	if grid_container and grid_container.has_signal("triggers_loaded"):
		print("✅ `triggers_loaded` signal exists in grid_container. Calling it manually...")
		_on_triggers_loaded([])
	else:
		print("❌ ERROR: `triggers_loaded` signal is missing in grid_container!")

		print("📂 Current filename:", current_filename)


func _ensure_ui_layer(): # ensure UI layer exists
	if get_tree().get_nodes_in_group("UI").size() == 0:
		print("❌ ERROR: UI Layer missing! Creating one now...")
		var ui_layer = Control.new()
		ui_layer.name = "UI"
		get_tree().get_root().add_child(ui_layer)
		ui_layer.add_to_group("UI")
		print("✅ UI Layer created in MapEditor")

func _connect_signals():
	if grid_container:
		grid_container.connect("map_loaded", Callable(self, "_on_map_loaded"))
		grid_container.connect("triggers_loaded", Callable(self, "_on_triggers_loaded"))
		print("✅ Connected `triggers_loaded` and maploaded signal from GridContainer.")
	else:
		print("❌ ERROR: GridContainer is NULL, cannot connect signals!")

func _setup_ui():
	if load_save_map_popup_scene and grid_container:
		load_save_map_popup_scene.set_grid_container(grid_container)
	else:
		print("❌ ERROR: Could not find MapEditorPopUp or grid container")

	load_save_map_popup_scene.visible = false  
	map_menu_panel.visible = false  
	map_menu_panel.position = Vector2(7, 900)  



		##     ##       ##     ##
		## Trigger Logic stuff ##
		##     ##       ##     ##


func _on_triggers_loaded(trigger_data: Array):
	print("📥 Receiving Triggers from GridContainer:", trigger_data.size())

	triggers.clear()  # ✅ Clear existing triggers before loading new ones

	for trigger in trigger_data:
		triggers.append(trigger)  # ✅ Load triggers into memory
		_update_or_add_trigger_button(trigger)  # ✅ Update UI without saving
		
	print("✅ All triggers added to the menu! Total:", triggers.size())
# 🔍 Debug - Check if buttons were added
	print("📌 Total buttons in Trigger List:", trigger_list.get_child_count())



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
	if button == null or not button is Button:
		print("❌ ERROR: Expected a Button, but got:", button)
		return

	print("🔍 Button Clicked:", button.text)

	if not button.has_meta("trigger_data"):
		print("❌ ERROR: Button has NO trigger metadata!")
		return
	selected_trigger = button.get_meta("trigger_data")

	if selected_trigger == null:
		print("❌ ERROR: Extracted Trigger is NULL!")
		return

	print("✅ Extracted Trigger:", selected_trigger, "| Cause:", selected_trigger.cause)

	var trigger_editor = preload("res://scenes/TriggerEditorPanel.tscn").instantiate()
	add_child(trigger_editor)
	trigger_editor.setup_trigger(selected_trigger)
	trigger_editor.connect("trigger_saved", Callable(self, "_on_trigger_saved"))


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


func _on_trigger_saved(trigger: Trigger):
	print("✅ Trigger Saved:", trigger.cause)
	_update_or_add_trigger_button(trigger)


func _update_or_add_trigger_button(trigger):
	## ✅ Check if a button for this trigger already exists
	for button in trigger_list.get_children():
		if button.has_meta("trigger_data") and button.get_meta("trigger_data") == trigger:
			button.text = _format_trigger_button_text(trigger)
			print("✅ Updated Existing Trigger UI:", trigger.cause)
			return  # ✅ Stop here, no need to create a new button

	## ✅ If no existing button was found, create a new one
	var button = Button.new()
	button.set_meta("trigger_data", trigger)
	
	## DEBUG
	var trigger_resource = button.get_meta("trigger_data")
	if trigger_resource:
		print("trigger button properties: ")
		for prop in trigger_resource.get_property_list():
			var prop_name = prop["name"]
			print("%s: %s" % [prop_name, trigger_resource.get(prop_name)])
		
		# If you specifically want to see effect data (assuming it's inside an array of effects)
		if trigger_resource.effects.size() > 0:
			for effect in trigger_resource.effects:
				print("Effect type: ", effect.effect_type)
				print("Effect parameters: ", effect.effect_parameters)
	else:
		print("No trigger data found on the button.")
	## DEBUG
	
	button.text = _format_trigger_button_text(trigger)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD 
	button.clip_text = false 
	button.connect("pressed", Callable(self, "_on_edit_trigger_pressed").bind(button))

	trigger_list.add_child(button)
	print("✅ New Trigger Button Added:", button.text)
	return button



func _format_trigger_button_text(trigger) -> String:
	print("_format_trigger_button_text function. trigger = ", trigger)
	if not trigger:
		return "❌ ERROR: Missing Trigger Data"
	
	# ✅ Extract effect names using a proper for-loop
	var effect_names = []
	for e in trigger.effects:
		if "effect_type" in e:
			effect_names.append(Effect.EffectType.keys()[e.effect_type])

	# ✅ Fallback for no effects
	var effect_summary = "\n".join(effect_names) if effect_names else "No Effects"


	# ✅ Fallback if no effects are found
	if effect_names.is_empty():
		effect_names.append("No Effects")

	var trigger_type_icon = "🌍 Global" if trigger.trigger_area_type == Trigger.AreaType.GLOBAL else "📍 Local"

	var trigger_name = trigger.cause if trigger.cause else "Unnamed Trigger"
	var trigger_return = "Triggers: %s\n%s\n🔽 Effects:\n%s" % [trigger_name, trigger_type_icon, "\n".join(effect_names)]
	
	return trigger_return


func _on_select_trigger(button):
	selected_trigger = button.get_meta("trigger_data")  # Retrieve stored trigger data

func _on_map_loaded(map_name):
	current_filename = map_name  # ✅ Update map filename
	print("📂 Map Editor Screen - Current filename set to:", current_filename)


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

	load_save_map_popup_scene.selected_map_name = ""  # Reset selection before opening
	load_save_map_popup_scene.selected_map_button = null  
	load_save_map_popup_scene.open_as_load()
	open_load_map_popup("Load Map")

	await get_tree().process_frame 

	var selected_map_name = load_save_map_popup_scene.get_user_selected_map() # ✅ Retrieve user-selected map from pop-up AFTER user interaction
	if selected_map_name.is_empty():
		print("⚠️ No map selected! Waiting for user selection.")
		return  # ✅ Stop execution if no map is selected
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
	var main_screen_scene = load("res://scenes/FirstSelectionScreen.tscn").instantiate()
	
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
