extends Control

class_name BoardEventEditorScreen


signal editor_closed_requested


#region variables
#@onready var tile_selector = get_node_or_null("Popups/BackgroundPanel/Padding/MainLayout/ContentVBox/AreaAndSound/AreaSelection/TileSelectionCustomNode")

@onready var cause_dropdown = $Popups/BackgroundPanel/Padding/MainLayout/ContentVBox/TriggerSettings/VBoxContainer/CauseDropdown
@onready var area_type_dropdown = $Popups/BackgroundPanel/Padding/MainLayout/ContentVBox/AreaAndSound/AreaSelection/AreaTypeDropdown
@onready var effect_list_container = $Popups/BackgroundPanel/Padding/MainLayout/ContentVBox/EffectSelection/ScrollContainer/EffectListContainer
@onready var add_effect_button = $Popups/BackgroundPanel/Padding/MainLayout/ContentVBox/EffectSelection/AddEffectButton
@onready var sound_effect_dropdown = $Popups/BackgroundPanel/Padding/MainLayout/ContentVBox/AreaAndSound/SoundEffect/SoundEffectDropdown
@onready var save_button = $Popups/BackgroundPanel/Padding/MainLayout/ContentVBox/Buttons/SaveTriggerButton
@onready var add_trigger_button = $Popups/BackgroundPanel/Padding/MainLayout/ContentVBox/TriggerSettings/VBoxContainer/AddTrigger
@onready var trigger_list_container = $Popups/BackgroundPanel/Padding/MainLayout/ContentVBox/TriggerSettings/TriggerListContainer

# have to rename this to BoardEventsManager
var board_event_manager: BoardEventManager
var triggers_ref: Array = []  # Store reference to `triggers` array
var current_trigger: Trigger = null  # Stores the active trigger

# declared but not used yet WARNING 
signal trigger_saved(trigger)
signal trigger_added(trigger)

#endregion


func _ready():
	pass


#region Life Cycle

func initialize(p_board_event_manager: BoardEventManager):
	board_event_manager = p_board_event_manager
	_initialize_ui()  # 👈 Now run all logic here

func _initialize_ui():
	if not board_event_manager:
		print("❌ board_event_manager is still null!")
	else:
		print("✅ board_event_manager is available:", board_event_manager)
		
	if current_trigger == null:
		current_trigger = Trigger.new()
		print("✅ New trigger created for pop-up.")
		
	_populate_dropdowns()
	_populate_trigger_list()

#endregion



#region Factory

# Factory
func _create_trigger_ui(trigger: Trigger):
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL  

	var dropdown = OptionButton.new()
	dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL  

	# Add labels based on CauseType enum
	for cause_label in Trigger.GlobalCause.keys():
		dropdown.add_item(cause_label)

	# Add labels based on CauseType enum
	for cause_label in Trigger.LocalCause.keys():
		dropdown.add_item(cause_label)




	dropdown.connect("item_selected", Callable(self, "_update_trigger").bind(trigger))
	hbox.add_child(dropdown)

	var remove_button = Button.new()
	remove_button.text = "X"
	remove_button.connect("pressed", Callable(self, "_remove_trigger").bind(trigger, hbox))
	hbox.add_child(remove_button)

	return hbox
# Factory
func _create_effect_ui(effect: Effect):
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL  

	var dropdown = OptionButton.new()
	dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL  

	# Populate dropdown with all effect types
	for effect_key in Effect.EffectType.keys():
		dropdown.add_item(_humanize_enum_name(effect_key))

	dropdown.selected = effect.effect_type

	# Fix: Ensure function is valid before connecting
	if has_method("_update_effect"):
		dropdown.connect("item_selected", Callable(self, "_update_effect").bind(effect))
	else:
		print("❌ ERROR: `_update_effect` function not found!")
	
	hbox.add_child(dropdown)
	
	var remove_button = Button.new()
	remove_button.text = "X"

	# Fix: Ensure function is valid before connecting
	if has_method("_remove_effect"):
		remove_button.connect("pressed", Callable(self, "_remove_effect").bind(effect, hbox))
	else:
		print("❌ ERROR: `_remove_effect` function not found!")

	hbox.add_child(remove_button)

	return hbox

# Utility
func _humanize_enum_name(enum_name: String) -> String:
	var words = enum_name.split("_")
	for i in range(words.size()):
		words[i] = words[i].capitalize()
	var cleaned_name = " ".join(words)  # Use String.join()
	return cleaned_name

#endregion


#region Setters

# SETTER: This should be in board event manager
func _save_trigger():
	print("💾 _save_trigger Saving Trigger...")
	
	# Varification
	if not current_trigger:
		print("❌ ERROR: No trigger to save!")
		_show_error_popup("❌ ERROR: Cannot save an empty trigger.")
		return
		
	# Ensure `triggers_ref` is valid
	if triggers_ref == null:
		print("❌ ERROR: `triggers_ref` is NULL! Cannot update triggers.")
		return
		
	print("📌 `triggers_ref` BEFORE Save:", triggers_ref)
		
	if cause_dropdown.selected < 0:
		_show_error_popup("❌ ERROR: Please select a trigger cause before saving.")
		return

	if effect_list_container.get_child_count() == 0:
		_show_error_popup("❌ ERROR: You must add at least one effect before saving.")
		return
		
	if current_trigger.effects.is_empty():
		print("current_trigger.effects.is_empty()")
		
	# Update trigger details
	current_trigger.cause = cause_dropdown.selected

	#current_trigger.trigger_tiles = tile_selector.get_selected_tiles() if tile_selector else []
	current_trigger.sound_effect = sound_effect_dropdown.get_item_text(sound_effect_dropdown.selected)
	
	# Check if trigger already exists, update or append
	var found = false
	for i in range(triggers_ref.size()):
		if triggers_ref[i] == current_trigger:
			print("🔄 Updating Existing Trigger:", Trigger.LocalCause.keys()[current_trigger.cause])
			triggers_ref[i] = current_trigger  # ✅ Update existing trigger
			found = true
			break

	if not found:
		print("➕ Adding New Trigger:", Trigger.LocalCause.keys()[current_trigger.cause])
		triggers_ref.append(current_trigger) # ✅ Add new trigger

	print("📌 `triggers_ref` After Save:", triggers_ref)
	
	# Send Triggers back to MapEditorScreen
	get_tree().get_nodes_in_group("MapEditorScreen")[0].update_triggers(triggers_ref)
	
	emit_signal("trigger_saved", current_trigger)
	emit_signal("editor_closed_requested")
	queue_free()  # Close trigger editor


func reset_trigger_data():
	current_trigger = Trigger.new()
	cause_dropdown.select(0)
	area_type_dropdown.select(0)
	sound_effect_dropdown.select(0)

	for child in effect_list_container.get_children():
		child.queue_free()


func _update_trigger(trigger_id: int, trigger): 	# NOT AN ACTUAL FUNCTION YET
	print("🔄 Updating trigger with ID:", trigger_id, "Trigger:", trigger)


func _update_effect(index, effect):
	print("🔄 Updating Effect with Index:", index)

	# ✅ Ensure index is valid
	if index < 0 or index >= Effect.EffectType.keys().size():
		print("❌ ERROR: Invalid index selected!")
		return

	# ✅ Set effect type based on selected index
	effect.effect_type = index  # Directly use the index
	print("✅ Effect updated to:", Effect.EffectType.keys()[index])
	return effect


func clear(is_fresh: bool = false): # resets board event editor menu UI
	current_trigger = Trigger.new()
	print("🧼 TriggerEditor cleared. New trigger created.")

	# Reset dropdowns only if they have items
	if cause_dropdown and cause_dropdown.item_count > 0:
		cause_dropdown.select(0)

	if area_type_dropdown and area_type_dropdown.item_count > 0:
		area_type_dropdown.select(0)

	if sound_effect_dropdown and sound_effect_dropdown.item_count > 0:
		sound_effect_dropdown.select(0)

	# Clear all effect UI elements
	if effect_list_container:
		for child in effect_list_container.get_children():
			child.queue_free()

# Setter: Helper function to pass on triggers_array her from other script triggers_array
func set_triggers_array(triggers_array: Array):
	triggers_ref = triggers_array
	print("✅ `triggers_ref` Received in TriggerEditorPanel:", triggers_ref)

#endregion


#region Utility

func _populate_dropdowns():
	print("🎛️ Populating Dropdowns...")

	if not cause_dropdown or not area_type_dropdown or not sound_effect_dropdown:
		print("❌ ERROR: One or more dropdown nodes are NULL!")
		return

	# Clear previous entries
	cause_dropdown.clear()
	area_type_dropdown.clear()
	sound_effect_dropdown.clear()

	# Populate using enums
	for i in Trigger.LocalCause.keys():
		cause_dropdown.add_item(_humanize_enum_name(i))


	# This is temporary -> will change 
	sound_effect_dropdown.add_item("None")
	sound_effect_dropdown.add_item("Victory Fanfare")
	sound_effect_dropdown.add_item("Trap Activated")
	# 
	
	cause_dropdown.selected = 0
	area_type_dropdown.selected = 0
	sound_effect_dropdown.selected = 0

	print("✅ Dropdowns Loaded!")

func _populate_trigger_list():
	print("🔄Populating Trigger List...")

	_populate_trigger_list_validations()

	for trigger in triggers_ref:
		if not (trigger is Trigger):
			continue
		
		var button = Button.new()
		button.text = board_event_manager._format_trigger_button_text(trigger)
		button.set_meta("trigger_data", trigger)
		trigger_list_container.add_child(button)
		button.connect("pressed", Callable(self, "_on_trigger_button_pressed").bind(trigger))

	print("Trigger List Populated!")

func _populate_trigger_list_validations():
	if not trigger_list_container:
		print("❌ ERROR: trigger_list_container is NULL!")
		return

	if not board_event_manager:
		print("❌ ERROR: board_event_manager is NULL!")
		return

	for child in trigger_list_container.get_children():
		child.queue_free()

	if not triggers_ref or triggers_ref.is_empty():
		print("⚠️ No triggers to display.")
		return

# Logic
# Edit existing trigger or create new if no Trigger exists
func setup_trigger(trigger: Trigger = null):
	if trigger:
		print("🔄 Loading Existing Trigger:", trigger.cause)
		current_trigger = trigger
		_edit_existing_trigger(trigger)
	else:
		print("➕ Creating a New Trigger")
		current_trigger = Trigger.new()

	_populate_trigger_list() # Refresh -> Ensure UI reflects current trigger

#endregion


#region Event Handlers

# EventHandler
func _remove_trigger(trigger, hbox):
	print("🗑️ Removing Trigger:", trigger.cause)

	# ✅ Remove from memory
	for i in range(triggers_ref.size()):
		if triggers_ref[i] == trigger:
			triggers_ref.remove_at(i)
			break  # ✅ Stop loop after deleting

	# ✅ Remove from UI
	hbox.queue_free()  # ✅ Deletes the button container

	print("✅ Trigger Removed Successfully!")


func _remove_effect(effect, hbox):
	if current_trigger:
		current_trigger.effects.erase(effect)
		print("🗑️ Effect Removed:", effect.effect_type)
	else:
		print("❌ ERROR: No current trigger available to remove effect from!")

	hbox.queue_free()  # ✅ Remove from UI


func _edit_existing_trigger(trigger: Trigger):
	if not trigger:
		print("❌ ERROR: No trigger passed to _edit_existing_trigger()!")
		return

	print("🔄 Populating Existing Trigger:", trigger.cause)

	## ✅ Populate Cause Dropdown ##
	var cause_index = -1
	for i in range(cause_dropdown.get_item_count()):
		if cause_dropdown.get_item_text(i) == trigger.cause:
			cause_index = i
			break

	if cause_index != -1:
		cause_dropdown.selected = cause_index
	else:
		print("❌ ERROR: Cause not found in dropdown:", trigger.cause)


	##  Set Tile Selection #
	#if tile_selector and tile_selector.has_method("set_selected_tiles"):
		#tile_selector.set_selected_tiles(trigger.trigger_tiles)
	#else:
		#print("❌ ERROR: TileSelector is missing or `set_selected_tiles()` is undefined!")

	# Set Sound Effect #
	var sound_index = -1
	for i in range(sound_effect_dropdown.get_item_count()):
		if sound_effect_dropdown.get_item_text(i) == trigger.sound_effect:
			sound_index = i
			break

	if sound_index != -1:
		sound_effect_dropdown.selected = sound_index
	else:
		print("❌ ERROR: Sound effect not found in dropdown:", trigger.sound_effect)

	# Clear previous effects ##
	for child in effect_list_container.get_children():
		child.queue_free()  # ✅ Properly remove effect UI elements

	# Add Effects Back to UI ##
	for effect_data in trigger.effects:
		var effect_ui = _create_effect_ui(effect_data)
		effect_list_container.add_child(effect_ui)

	print("✅ Trigger Repopulated Successfully!")


func _show_error_popup(message: String):
	var popup = AcceptDialog.new()
	popup.dialog_text = message
	add_child(popup)
	popup.popup_centered()



## Button Pressed Section:

func _on_close_button_pressed():
	print("❌ Close button pressed. Closing without saving.")
	emit_signal("editor_closed_requested")
	queue_free()


func _on_cancel_button_pressed():
	print("🚫 Cancel Button Pressed. Closing without saving.")
	emit_signal("editor_closed_requested")
	queue_free()

# Adds a trigger to the UI list
func _on_add_trigger_pressed():
	print("➕ Adding New Trigger...")
	var selected_cause = cause_dropdown.get_item_text(cause_dropdown.selected)

	var new_trigger = Trigger.new()
	new_trigger.cause = selected_cause

	var trigger_ui = _create_trigger_ui(new_trigger)
	trigger_list_container.add_child(trigger_ui)

	emit_signal("trigger_added", new_trigger)
	triggers_ref.append(new_trigger)
	emit_signal("editor_closed_requested")
	print("✅ Trigger Added:", selected_cause, " Total Triggers:", triggers_ref.size())


func _on_trigger_button_pressed(trigger: Trigger) -> void:
	emit_signal("trigger_selected", trigger)


func _on_add_effect_button_pressed():
	print("➕ Adding New Effect...")

	# Create a new Effect instance
	var effect = Effect.new()
	effect.effect_type = Effect.EffectType.SPAWN_REINFORCEMENTS  ## Default effect type

	# Create UI elements for the effect
	var effect_ui = _create_effect_ui(effect)
	print("_add_effect_ effect_ui",effect_ui)
	# Add UI to the Effect List
	effect_list_container.add_child(effect_ui)
	print("AA effect_list_container children", effect_list_container.get_children())
	effect_ui.add_to_group("effect_ui")

	# Store effect in current trigger
	current_trigger.effects.append(effect)
	print("current_trigger.effects", current_trigger.effects)
	print("✅ Effect Added to List:", effect.effect_type)



#endregion
