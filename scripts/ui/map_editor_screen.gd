extends Control 

class_name MapEditorScreen

signal trigger_edit_requested(trigger)


#region ONREADY VARIABLES
@onready var grid_container = $HSplitContainer/MarginContainer/MainMapDisplay/GridContainer 
#@onready var tile_selector = $SideMenu/TerrainMenuWrapper/MenuWrapper/TerrainMenu/MarginContainer/ScrollContainer/PanelContainer  # Adjust this if UI structure is different
@onready var map_menu_panel = $MapMenuPanel  # Reference the panel

@onready var ui_layer = $UI  # Make sure this is available
@onready var map_list_screen = null

# Pop Up Components Referenced  ##
@onready var load_save_map_popup = $MapEditorPopUp  # Reference to the popup scene
@onready var load_save_map_popup_menu = $MapEditorPopUp/LoadSaveMapPopUp
@onready var load_save_map_popup_title = $MapEditorPopUp/LoadSaveMapPopUp/MarginContainer/VBoxContainer/PopUpTitle
@onready var confirmation_popup = $MapEditorPopUp/ConfirmationPopUp
@onready var confirmation_label = $MapEditorPopUp/ConfirmationPopUp/MarginContainer/VBoxContainer/ConfirmationMessage

# Menu Stuff #
@onready var toggle_menu_button = $ToggleMapMenuButton  # Reference the button
@onready var map_name_input = $MapEditorPopUp/LoadSaveMapPopUp/MarginContainer/VBoxContainer/MapNameInput

### Trigger Variables ##
@onready var trigger_menu = $HSplitContainer/SideMenu/TerrainMenuWrapper/MenuWrapper/TriggerMenu
@onready var trigger_list = $HSplitContainer/SideMenu/TerrainMenuWrapper/MenuWrapper/TriggerMenu/MarginContainer/ScrollContainer/TriggerList
@onready var create_trigger_button = $HSplitContainer/SideMenu/TerrainMenuWrapper/MenuWrapper/TriggerMenu/MarginContainer/HBoxContainer/CreateTriggerButton

const MAPS_DIR := "user://maps/"
var trigger_editor: TriggerEditorPanel = null

#endregion

#region VARIABLES

var tween: Tween = null  
var trigger_manager = null  # Will store the actual instance
var triggers: Array = []  # Master trigger list
var current_filename: String = ""  # Tracks the current map file name
var map_data = {}  

#endregion VARIABLES


func _ready():
	_setup_ui()
	_verify_grid_container()

	# Trigger Manager setup
	#for child in get_children():
		#if child is TriggerManager:
			#trigger_manager = child
			#break
			#
	#if not trigger_manager:
		#print("🛠 Creating TriggerManager...")
		#trigger_manager = trigger_manager_scene.instantiate()
		#add_child(trigger_manager)
		#print("✅ TriggerManager ADDED to Scene Tree:", trigger_manager)
	
	#_debug_trigger_editor_state()
	#_print_scene_tree()
	#connect("trigger_edit_requested",Callable(self, "_on_edit_trigger_requested"))

	# if tile_selector:
	#     tile_selector.connect("tile_selected", _on_tile_selected)
	
	# await get_tree().process_frame
	# _check_triggers_signal()


#func setup_map_editor_context(map_editor: Node):
	#grid_manager = map_editor.find_child("GridManager", true, false)
	#if grid_manager:
		#print("✅ GridManager found.")
	#else:
		#print("❌ ERROR: GridManager not found!")

#region UI setup

func _setup_ui():
	load_save_map_popup_menu.visible = false
	map_menu_panel.visible = false

	# if load_save_map_popup_scene and grid_container:
	#     load_save_map_popup_scene.set_grid_container(grid_container)
	# else:
	#     print("❌ ERROR: Could not find MapEditorPopUp or grid container")
	
	# load_save_map_popup_scene.visible = false   

#
func _verify_grid_container():
	if grid_container:
		print("✅ GridContainer found:", grid_container)
	else:
		print("❌ ERROR: GridContainer NOT FOUND in MapEditor!")

#endregion



#region Map Data Logic

#func set_map_data(data):
	#map_data = data
	#print("Main scene received map data:", map_data)
	#
	#if grid_container:
		#grid_container.load_map_data(map_data)

func _on_map_loaded(map_name): # current_filename = map_name
	current_filename = map_name
	print("📂 Map Editor Screen - Loaded map:", current_filename)


func update_triggers(updated_triggers: Array): # update_triggers
	print("🔄 Updating MapEditorScreen Triggers:", updated_triggers.size())

	triggers.clear()  # Clear existing triggers
	triggers.append_array(updated_triggers)  # Copy new triggers into the array

	print("✅ Triggers Updated in MapEditorScreen:", triggers.size())

#endregion


#region Open & Close, Trigger Editor UI


func open_trigger_editor(trigger: Trigger = null):
	if trigger_editor:
		trigger_editor.queue_free()
	
	var trigger_editor_scene = load("res://scenes/TriggerEditorPanel.tscn")
	trigger_editor = trigger_editor_scene.instantiate()
	self.add_child(trigger_editor)
	trigger_editor.visible = true
	trigger_editor.z_index = 50
	trigger_editor.initialize(trigger_manager)
	trigger_editor.call_deferred("grab_focus")
	#self.focus_mode = Control.FOCUS_NONE
	#if trigger:
		#trigger_editor.setup_trigger(trigger)
	
	
	#trigger_editor.focus_mode = Control.FOCUS_ALL
	#trigger_editor.mouse_default_cursor_shape = CURSOR_POINTING_HAND 
	#trigger_editor.connect("trigger_saved", Callable(self, "_on_trigger_saved"))
	#trigger_editor.connect("editor_closed", Callable(self, "_on_trigger_editor_closed"))


#func _setup_trigger_editor_signals():
		#trigger_editor.connect("trigger_saved", Callable(self, "_on_trigger_saved"))
		#trigger_editor.connect("editor_closed", Callable(self, "_on_trigger_editor_closed"))
		#trigger_editor.connect("trigger_selected", Callable(self, "_on_edit_trigger_requested"))


func toggle_trigger_editor():
	trigger_editor.visible = !trigger_editor.visible


func _on_trigger_editor_closed():
	pass


func _on_triggers_loaded(trigger_data: Array):
	print("📥 Receiving Triggers from GridContainer:", trigger_data, trigger_data.size())
	
	# Ensure `triggers` list is reset before loading new triggers
	triggers.clear()
	print("🔄 `triggers` Cleared. Now Empty:", triggers)

	for trigger in trigger_data:
		print("🔎 Checking trigger type:", typeof(trigger))
		
		if trigger is Trigger:
			print("Valid Trigger found:", trigger)
			print("➕ Adding Trigger to Memory:", trigger.cause, "| Effects:", trigger.effects)
			triggers.append(trigger) # Load trigger into memory
			_update_or_add_trigger_button(trigger)  # Update UI

	print("All triggers added to the menu! Total:", triggers.size())
	print("Total buttons in Trigger List:", trigger_list.get_child_count())


#endregion


#region Trigger Button Pressed Logic

func _on_create_trigger_pressed():
	print("🚀 Create Trigger Button Pressed")
	if trigger_editor:
		toggle_trigger_editor()
	else:
		open_trigger_editor()

func _on_trigger_saved(button): # REDUNDANT? This is commented out
	pass
	##  Ensure we got a Button
	#if not button is Button:
		#print("❌ ERROR: Expected a Button but got:", button)
		#return
#
	##  Retrieve the trigger from the button's metadata
	#if not button.has_meta("trigger_data"):
		#print("❌ ERROR: Button has NO trigger metadata!")
		#return
	#
	#var trigger = button.get_meta("trigger_data")
#
	## 🔍 Debug: Ensure trigger is valid
	#if trigger == null:
		#print("❌ ERROR: Extracted Trigger is NULL!")
		#return
#
	#print("📥 Received New Trigger:", trigger.cause)
#
	##  Store trigger in list
	#triggers.append(trigger)
#
	##  Ensure button is properly connected
	#button.connect("pressed", Callable(self, "_on_edit_trigger_pressed").bind(button))
#
	## Add button to UI
	#trigger_list.add_child(button)
	#print("✅ Trigger Added to Menu:", trigger.cause)

#func _on_trigger_saved(trigger: Trigger): # REDUNDANT? This is commented out
	#print("✅ Trigger Saved:", trigger.cause)
#
	## Check if trigger exists in MapEditor triggers
	#var found = false
	#for i in range(triggers.size()):
		#if triggers[i] == trigger:
			#print("🔄 Updating Existing Trigger in MapEditorScreen:", trigger.cause)
			#triggers[i] = trigger  # ✅ Update existing trigger
			#found = true
			#break
#
	#if not found:
		#print("➕ Adding New Trigger to MapEditorScreen:", trigger.cause)
		#triggers.append(trigger)  # ✅ Add new trigger
#
	#print("📌 Triggers in MapEditorScreen AFTER Save:", triggers)
#
	## Ensure trigger is also added to the UI
	#_update_or_add_trigger_button(trigger)

func _update_or_add_trigger_button(trigger):
	# Check if a button for this trigger already exists
	for button in trigger_list.get_children():
		if button.has_meta("trigger_data") and button.get_meta("trigger_data") == trigger:
			button.text = trigger_manager._format_trigger_button_text(trigger)
			print("✅ Updated Existing Trigger UI:", trigger.cause)
			return  # ✅ Stop here, no need to create a new button

	# If no existing button was found, create a new one
	var button = Button.new()
	button.set_meta("trigger_data", trigger)
	
	button.text = trigger_manager._format_trigger_button_text(trigger)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD 
	button.clip_text = false 
	button.connect("pressed", Callable(self, "_on_edit_trigger_pressed").bind(button))

	trigger_list.add_child(button)
	print("✅ New Trigger Button Added:", button.text)
	return button

#endregion



#region MAP SAVING/LOADING Pop Up Functions

func open_save_as_popup_first_time(title_text: String):
	if load_save_map_popup:
			load_save_map_popup.set_popup_title(title_text)
			load_save_map_popup_menu.popup_centered()


func open_save_as_popup(title_text: String):
	if load_save_map_popup_menu and map_name_input:
		map_name_input.text = current_filename if current_filename != "" else ""

		# Set the correct title for the pop-up
		load_save_map_popup.set_popup_title(title_text)

		# Open the Save As pop-up
		load_save_map_popup_menu.popup_centered()
		print("📝 Opening Save As pop-up:", title_text)
	else:
		print("❌ ERROR: load_save_map_popup_scene or map_name_input is not set!")


func open_load_map_popup(title_text: String):
	load_save_map_popup.user_selected_map = false  # ✅ Reset selection status
	
	if load_save_map_popup_menu and load_save_map_popup_title:
		load_save_map_popup.set_popup_title(title_text)
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

#endregion


#region Button Pressed Logic -> Trigger & Map


#region Map Button Pressed Functions

func _on_save_map_button_pressed():
	if current_filename.is_empty():
		open_save_as_popup_first_time("Save Map As...")
	else:
		grid_container.save_map(current_filename)

func _on_toggle_map_menu_button_pressed():
	tween = create_tween()
	
	if map_menu_panel:
		print("map_menu_panel loaded successfully")
	else:
		print("map_menu_panel not loaded")
	
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
		await tween.finished

func _on_save_as_button_pressed() -> void:
	print("📝 Save As button pressed")
	load_save_map_popup.open_as_save()
	open_save_as_popup("Save map as...")

#func _on_save_map_button_pressed():
	#print("💾 Save Map button pressed")
	#var serialized_triggers = _serialize_triggers()
	#print("📡 Saving Map with Triggers:", serialized_triggers.size())
	#
	## ✅ Get existing map data
	#var map_data = {
		#"triggers": serialized_triggers,
		## Add other existing data that gets saved
	#}
	#
	#print("📂 Map Data BEFORE Saving:", JSON.stringify(map_data, "\t"))
	#
	#if triggers.is_empty():
		#print("⚠️ WARNING: No triggers found, saving an empty map!")
	#
	## ✅ If the map has NOT been saved before, open Save As pop-up
	#if current_filename.is_empty():
		#print("🔹 No filename found, opening Save As menu...")
		#load_save_map_popup_scene.open_as_save()  # ✅ Open pop-up only if first save
	#else:
		## ✅ If the map has a filename, just save it
		#print("💾 Saving existing map:", current_filename)
		#grid_container.save_map(current_filename, map_data)  # ✅ Save directly
		#show_confirmation_popup("✅ Map saved successfully!")  # ✅ Show confirmation message
		#
	#print("📡 Saving Map with Triggers:", serialized_triggers.size())

func _on_load_map_button_pressed() -> void:
	print("📂 Load Map button pressed")
	# Reset selection and open the load popup
	load_save_map_popup.selected_map_name = ""
	load_save_map_popup.selected_map_button = null
	load_save_map_popup.open_as_load()
	open_load_map_popup("Load Map")

	await get_tree().process_frame

	# Retrieve the selected map name after the user selects it
	var selected_map_name = load_save_map_popup.get_user_selected_map()
	if selected_map_name.is_empty():
		print("⚠️ No map selected! Waiting for user selection.")
		return

	print("✅ Selected map:", selected_map_name)

	if grid_container:
		grid_container.load_map(selected_map_name)
		print("✅ Map loaded successfully:", selected_map_name)

		# Show confirmation popup after loading
		confirmation_label.text = "📂 Loaded map: " + selected_map_name
		confirmation_popup.popup_centered()

		# Close the Load/Save map popup after loading
		await get_tree().process_frame
		load_save_map_popup_menu.hide()
		print("🛑 LoadSaveMapPopUp menu hidden after loading!")
	else:
		print("❌ ERROR: grid_container is not set!")
		load_save_map_popup.display_error("Please select a map before loading.")

func _on_back_to_main_pressed() -> void: # can not test
	print("🔙 Returning to Main Screen...")
	var map_list_screen = load("res://scenes/MapListScreen.tscn").instantiate()
	
	get_tree().root.add_child(map_list_screen)
	get_tree().current_scene.queue_free()  # Remove current scene
	get_tree().current_scene = map_list_screen  # Set new scene


func _on_edit_trigger_pressed(button: Button):
	var selected_trigger = button.get_meta("trigger_data")
	emit_signal("trigger_edit_requested", selected_trigger)


#endregion
#endregion



# Handle tile selection from the TileSelector
#func _on_tile_selected(tile_type):
	#var tile_grid = get_node_or_null("GridContainer")
	#if tile_grid:
		#tile_grid.selected_tile_type = tile_type



#region Helper Functions

func _serialize_triggers() -> Array: # needs to be edited in
	print("📝 Serializing Triggers for Save. Current Count:", triggers.size())
	
	var serialized_triggers = []
	for trigger in triggers:
		var trigger_data = {
			"cause": trigger.cause,
			"trigger_area_type": trigger.trigger_area_type,
			"trigger_tiles": trigger.trigger_tiles,
			"sound_effect": trigger.sound_effect,
			"effects": []
		}
		print("AAA triggers", trigger)
	
		# ✅ Serialize Effects
		for effect in trigger.effects:
			print("🔹 Serializing Effect:", effect.effect_type)
			trigger_data["effects"].append({
				"effect_type": effect.effect_type,
				"effect_parameters": effect.effect_parameters
			})
			print("BBB triggers", trigger.effects)
			
		serialized_triggers.append(trigger_data)
		print("serialized_triggers", serialized_triggers)

	print("✅ 123 Serialized Triggers for Save:", serialized_triggers)
	return serialized_triggers


func print_scene_tree(node: Node, indent: int = 0) -> void:
	var indent_str = "  ".repeat(indent)  # Use .repeat() for indentation
	print(indent_str + node.name + " (" + node.get_class() + ")")  # Safe concatenation
	for child in node.get_children():
		print_scene_tree(child, indent + 1)

#endregion
