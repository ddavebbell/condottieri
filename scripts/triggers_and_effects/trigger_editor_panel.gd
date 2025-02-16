extends Control

@onready var tile_selector: TileSelector = null
@onready var cause_dropdown = $Popups/BackgroundPanel/Padding/MainLayout/ContentVBox/TriggerSettings/VBoxContainer/CauseDropdown
@onready var area_type_dropdown = $Popups/BackgroundPanel/Padding/MainLayout/ContentVBox/AreaAndSound/AreaSelection/AreaTypeDropdown
@onready var effect_list_container = $Popups/BackgroundPanel/Padding/MainLayout/ContentVBox/EffectSelection/ScrollContainer/EffectListContainer
@onready var add_effect_button = $Popups/BackgroundPanel/Padding/MainLayout/ContentVBox/EffectSelection/AddEffectButton
@onready var sound_effect_dropdown = $Popups/BackgroundPanel/Padding/MainLayout/ContentVBox/AreaAndSound/SoundEffect/SoundEffectDropdown
@onready var save_button = $Popups/BackgroundPanel/Padding/MainLayout/ContentVBox/Buttons/SaveTriggerButton
@onready var add_trigger_button = $Popups/BackgroundPanel/Padding/MainLayout/ContentVBox/TriggerSettings/VBoxContainer/SelectTrigger
@onready var trigger_list_container = $Popups/BackgroundPanel/Padding/MainLayout/ContentVBox/TriggerSettings/TriggerListContainer

var triggers: Array = []  # ✅ Stores all added triggers
var current_trigger: Trigger = null  # ✅ Stores the active trigger

signal trigger_saved(trigger)
signal trigger_added(trigger)

func _ready():
	await get_tree().process_frame  # ✅ Wait to ensure all nodes are loaded
	tile_selector = get_node_or_null("Popups/BackgroundPanel/Padding/MainLayout/ContentVBox/AreaAndSound/AreaSelection/TileSelectionCustomNode") as TileSelector
	
	print("🔎 Searching for TileSelector in Scene Tree...")
	for node in get_tree().get_root().get_children():
		print("📌 Node in tree:", node.name)
	
	if not tile_selector:
		print("❌ ERROR: `tile_selector` is NULL at startup!")
	elif not tile_selector.has_method("get_selected_tiles"):
		print("❌ ERROR: `tile_selector` exists but does NOT have `get_selected_tiles()`! Type:", tile_selector.get_class())
	else:
		print("✅ TileSelector Found:", tile_selector.name, "| Type:", tile_selector.get_class())
	
	print("🎛️ Initializing Trigger Editor Panel...")
	_setup_panel_position()
	_populate_dropdowns()
	_connect_signals()
	_populate_trigger_list()
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100
	visible = true

# ✅ Ensures the panel is correctly positioned
func _setup_panel_position():
	if get_parent():
		self.set_size(Vector2(1400, 750))  
		var screen_size = get_viewport().get_visible_rect().size

		self.set_position((screen_size - self.size) / 2)  
		print("✅ Trigger Editor Positioned at:", self.position)
	else:
		print("❌ ERROR: TriggerEditorPanel has no parent UI!")

# ✅ Populates the dropdowns
func _populate_dropdowns():
	print("🎛️ Populating Dropdowns...")
	
	if not cause_dropdown or not area_type_dropdown or not sound_effect_dropdown:
		print("❌ ERROR: One or more dropdown nodes are NULL!")
		return  
	
	cause_dropdown.add_item("Piece Captured")
	cause_dropdown.add_item("Piece Enters Tile")
	cause_dropdown.add_item("Turn Count Reached")

	area_type_dropdown.add_item("Local")
	area_type_dropdown.add_item("Global")

	sound_effect_dropdown.add_item("None")
	sound_effect_dropdown.add_item("Victory Fanfare")
	sound_effect_dropdown.add_item("Trap Activated")

	print("📌 Cause Dropdown Items:", cause_dropdown.get_item_count())
	print("📌 Area Type Dropdown Items:", area_type_dropdown.get_item_count())
	print("📌 Sound Effect Dropdown Items:", sound_effect_dropdown.get_item_count())

	cause_dropdown.selected = 0
	area_type_dropdown.selected = 0
	sound_effect_dropdown.selected = 0

	print("✅ Dropdowns Loaded!")

# ✅ Connects UI signals
func _connect_signals():
	add_trigger_button.connect("pressed", Callable(self, "_on_add_trigger_pressed"))
	save_button.connect("pressed", Callable(self, "_save_trigger"))
	cause_dropdown.connect("item_selected", Callable(self, "_on_cause_dropdown_item_selected"))
	print("✅ Signals Connected!")

# ✅ Adds a trigger to the UI list
func _on_add_trigger_pressed():
	print("➕ Adding New Trigger...")
	var selected_cause = cause_dropdown.get_item_text(cause_dropdown.selected)

	var new_trigger = Trigger.new()
	new_trigger.cause = selected_cause

	var trigger_ui = _create_trigger_ui(new_trigger)
	trigger_list_container.add_child(trigger_ui)

	emit_signal("trigger_added", new_trigger)
	triggers.append(new_trigger)
	print("✅ Trigger Added:", selected_cause, " Total Triggers:", triggers.size())

# ✅ Creates UI entry for a trigger
func _create_trigger_ui(trigger: Trigger):
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL  

	var dropdown = OptionButton.new()
	dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL  
	dropdown.add_item("Piece Captured")
	dropdown.add_item("Piece Enters Tile")
	dropdown.add_item("Turn Count Reached")

	# ✅ FIX: Get index correctly
	var cause_index = -1
	for i in range(dropdown.get_item_count()):
		if dropdown.get_item_text(i) == trigger.cause:
			cause_index = i
			break

	if cause_index != -1:
		dropdown.selected = cause_index  # ✅ Now correctly assigns index
	else:
		print("❌ ERROR: Cause not found in dropdown:", trigger.cause)

	dropdown.connect("item_selected", Callable(self, "_update_trigger").bind(trigger))
	hbox.add_child(dropdown)

	var remove_button = Button.new()
	remove_button.text = "X"
	remove_button.connect("pressed", Callable(self, "_remove_trigger").bind(trigger, hbox))
	hbox.add_child(remove_button)

	return hbox


# Inside TriggerEditorPanel.gd (Trigger Editor)
func _save_trigger():
	print("💾 Saving Trigger...")

	# ✅ Ensure a cause is selected
	var selected_index = cause_dropdown.selected
	if selected_index < 0:
		_show_error_popup("❌ ERROR: Please select a trigger cause before saving.")
		return

	# ✅ Ensure a trigger exists
	if not current_trigger:
		print("❌ ERROR: No trigger to save!")
		_show_error_popup("❌ ERROR: Cannot save an empty trigger.")
		return

	# ✅ Ensure at least one effect exists before saving
	if not current_trigger.effects or current_trigger.effects.size() == 0:
		print("❌ ERROR: At least one effect is required!")
		_show_error_popup("❌ ERROR: You must add at least one effect before saving.")
		return

	# ✅ Assign cause
	current_trigger.cause = cause_dropdown.get_item_text(selected_index)

	# ✅ Emit `trigger_saved` Signal
	emit_signal("trigger_saved", current_trigger)

	print("📡 Emitting `trigger_saved` SIGNAL for:", current_trigger.cause)
	queue_free()  # ✅ Close the trigger editor after saving


func _show_error_popup(message: String):
	var popup = AcceptDialog.new()
	popup.dialog_text = message
	add_child(popup)
	popup.popup_centered()


func setup_trigger(trigger: Trigger = null):
	if trigger:
		print("🔄 Loading Existing Trigger:", trigger.cause)
		current_trigger = trigger
		_populate_existing_trigger(trigger)
	else:
		print("➕ Creating a New Trigger")
		current_trigger = Trigger.new()

	# ✅ Ensure UI reflects current trigger
	_populate_trigger_list()



func _populate_existing_trigger(trigger: Trigger):
	if not trigger:
		print("❌ ERROR: No trigger passed to _populate_existing_trigger()!")
		return
	
	print("🔄 Populating Existing Trigger:", trigger.cause)

	# ✅ Find the correct index for the trigger cause
	var cause_index = -1
	for i in range(cause_dropdown.get_item_count()):
		if cause_dropdown.get_item_text(i) == trigger.cause:
			cause_index = i
			break

	# ✅ Only set the dropdown if the cause exists
	if cause_index != -1:
		cause_dropdown.selected = cause_index
	else:
		print("❌ ERROR: Cause not found in dropdown:", trigger.cause)

	
	if cause_index != -1:
		cause_dropdown.selected = cause_index
	else:
		print("❌ ERROR: Cause not found in dropdown:", trigger.cause)

	# ✅ Ensure area type is set
	area_type_dropdown.selected = 0 if trigger.trigger_area_type == Trigger.AreaType.LOCAL else 1

	# ✅ Ensure tile selection is applied
	if tile_selector and tile_selector.has_method("set_selected_tiles"):
		tile_selector.set_selected_tiles(trigger.trigger_tiles)
	else:
		print("❌ ERROR: TileSelector is missing or `set_selected_tiles()` is undefined!")

	# ✅ Ensure sound effect is set
	var sound_index = -1
	for i in range(sound_effect_dropdown.get_item_count()):
		if sound_effect_dropdown.get_item_text(i) == trigger.sound_effect:
			sound_index = i
			break

	if sound_index != -1:
		sound_effect_dropdown.selected = sound_index
	else:
		print("❌ ERROR: Sound effect not found in dropdown:", trigger.sound_effect)


	# ✅ Repopulate Effects List
	var left_column = effect_list_container.get_node("HBoxContainer/LeftColumn")
	var right_column = effect_list_container.get_node("HBoxContainer/RightColumn")

	# ✅ Clear previous UI
	for child in left_column.get_children():
		child.queue_free()
	for child in right_column.get_children():
		child.queue_free()

	# ✅ Add effects back to UI
	for i in range(trigger.effects.size()):
		var effect_ui = _create_effect_ui(trigger.effects[i])
		if i % 2 == 0:
			left_column.add_child(effect_ui)
		else:
			right_column.add_child(effect_ui)

	print("✅ Trigger Repopulated Successfully!")



# ✅ Populates the trigger list when editor opens
func _populate_trigger_list():
	print("🔄 Populating Trigger List...")

	for child in trigger_list_container.get_children():
		child.queue_free()

	for trigger in triggers:
		var button = Button.new()
		button.text = trigger.cause
		button.set_meta("trigger_data", trigger)

		trigger_list_container.add_child(button)
		button.connect("pressed", Callable(self, "_on_edit_trigger_pressed").bind(trigger))

	print("✅ Trigger List Populated!")

func _add_effect():
	print("➕ Adding New Effect...")

	# ✅ Ensure `current_trigger` exists
	if current_trigger == null:
		print("❌ ERROR: current_trigger is NULL! Creating new trigger...")
		current_trigger = Trigger.new()

	# ✅ Create a new Effect instance
	var effect = Effect.new()
	effect.effect_type = Effect.EffectType.SPAWN_REINFORCEMENTS  # Default effect type

	# ✅ Create UI elements for the effect
	var effect_ui = _create_effect_ui(effect)
	
	# ✅ Add UI to the Effect List
	effect_list_container.add_child(effect_ui)

	# ✅ Store effect in current trigger
	current_trigger.effects.append(effect)
	print("✅ Effect Added to List:", effect.effect_type)


func _create_effect_ui(effect: Effect):
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL  

	var dropdown = OptionButton.new()
	dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL  

	# ✅ Populate dropdown with all effect types
	dropdown.add_item("Spawn Reinforcements")
	dropdown.add_item("Upgrade Piece")
	dropdown.add_item("Remove Piece")
	dropdown.add_item("Activate Trap")
	dropdown.add_item("Reveal Hidden Tiles")
	dropdown.add_item("Change Tile Type")
	dropdown.add_item("Add Time Bonus")
	dropdown.add_item("Reduce Time")
	dropdown.add_item("Increase Score")
	dropdown.add_item("Decrease Score")
	dropdown.add_item("AI Aggression")
	dropdown.add_item("Spawn Enemies")
	dropdown.add_item("End Level")

	dropdown.selected = effect.effect_type

	# ✅ Fix: Ensure function is valid before connecting
	if has_method("_update_effect"):
		dropdown.connect("item_selected", Callable(self, "_update_effect").bind(effect))
	else:
		print("❌ ERROR: `_update_effect` function not found!")

	hbox.add_child(dropdown)

	var remove_button = Button.new()
	remove_button.text = "X"

	# ✅ Fix: Ensure function is valid before connecting
	if has_method("_remove_effect"):
		remove_button.connect("pressed", Callable(self, "_remove_effect").bind(effect, hbox))
	else:
		print("❌ ERROR: `_remove_effect` function not found!")

	hbox.add_child(remove_button)

	return hbox


func _remove_effect(effect, hbox):
	if current_trigger:
		current_trigger.effects.erase(effect)
		print("🗑️ Effect Removed:", effect.effect_type)
	else:
		print("❌ ERROR: No current trigger available to remove effect from!")

	hbox.queue_free()  # ✅ Remove from UI


func _update_effect(effect: Effect, selected_index: int):
	print("🔄 Updating Effect:", effect, "to", selected_index)

	# ✅ Create a mapping from dropdown selection to `EffectType`
	var effect_types = [
		Effect.EffectType.SPAWN_REINFORCEMENTS,
		Effect.EffectType.UPGRADE_PIECE,
		Effect.EffectType.REMOVE_PIECE,
		Effect.EffectType.ACTIVATE_TRAP,
		Effect.EffectType.REVEAL_HIDDEN_TILES,
		Effect.EffectType.CHANGE_TILE_TYPE,
		Effect.EffectType.ADD_TIME_BONUS,
		Effect.EffectType.REDUCE_TIME,
		Effect.EffectType.INCREASE_SCORE,
		Effect.EffectType.DECREASE_SCORE,
		Effect.EffectType.AI_AGGRESSION,
		Effect.EffectType.SPAWN_ENEMIES,
		Effect.EffectType.END_LEVEL
	]

	if selected_index >= 0 and selected_index < effect_types.size():
		effect.effect_type = effect_types[selected_index]  # ✅ Assign enum value instead of int
		print("✅ Effect updated to:", effect.effect_type)
	else:
		print("❌ ERROR: Invalid Effect Type Selected:", selected_index)





func _on_close_button_pressed():
	print("❌ Closing Trigger Editor...")
	queue_free()

func _on_cancel_button_pressed():
	print("🚫 Cancel Button Pressed. Closing without saving.")
	queue_free()
