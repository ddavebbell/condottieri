extends Control

@onready var cause_dropdown = $Popups/BackgroundPanel/Padding/MainLayout/ScrollContainer/ContentVBox/TriggerSettings/CauseDropdown
@onready var area_type_dropdown = $Popups/BackgroundPanel/Padding/MainLayout/ScrollContainer/ContentVBox/AreaSelection/AreaTypeDropdown
@onready var tile_selector = $Popups/BackgroundPanel/Padding/MainLayout/ScrollContainer/ContentVBox/AreaSelection/TileSelectionCustomNode
@onready var effect_list_container = $Popups/BackgroundPanel/Padding/MainLayout/ScrollContainer/ContentVBox/EffectSelection/ScrollContainer/EffectListContainer
@onready var add_effect_button = $Popups/BackgroundPanel/Padding/MainLayout/ScrollContainer/ContentVBox/EffectSelection/AddEffectButton
@onready var sound_effect_dropdown = $Popups/BackgroundPanel/Padding/MainLayout/ScrollContainer/ContentVBox/SoundEffect/SoundEffectDropdown
@onready var save_button = $Popups/BackgroundPanel/Padding/MainLayout/ScrollContainer/ContentVBox/Buttons/SaveTriggerButton

@onready var trigger_list = $Popups/BackgroundPanel/Padding/MainLayout/ScrollContainer/ContentVBox/TriggerSettings/CauseDropdown


var trigger_editor_open = false  # ✅ Track when TriggerEditor is open
var current_trigger: Trigger = null

signal trigger_saved(trigger)

func _process(delta):
	if not self.is_inside_tree():
		print("❌ ERROR: TriggerEditorPanel was REMOVED from the scene tree!")
	elif not self.visible:
		print("❌ WARNING: TriggerEditorPanel is INVISIBLE!")
		
	if trigger_editor_open:
		mouse_filter = Control.MOUSE_FILTER_IGNORE  # ✅ Disable clicks in MapEditor
	else:
		mouse_filter = Control.MOUSE_FILTER_STOP  # ✅ Allow clicks when TriggerEditor is closed

func _on_close_trigger_editor():
	# ✅ When closing, re-enable `MapEditor` input
	var map_editor = get_tree().get_root().find_node("MapEditor", true, false)
	if map_editor:
		map_editor.trigger_editor_open = false

func _ready():
	if effect_list_container:
		print("✅ Effect List Container Found:", effect_list_container.name)
	else:
		print("❌ ERROR: Effect List Container NOT Found! Check Node Path.")
	

	var hbox_container = effect_list_container.get_node("HBoxContainer")
	var left_column = effect_list_container.get_node("HBoxContainer/LeftColumn")
	var right_column = effect_list_container.get_node("HBoxContainer/RightColumn")

	effect_list_container.custom_minimum_size = Vector2(0, 0)  # ✅ Prevent forced empty space


	
	
	print("🧐 TriggerEditorPanel's parent is:", get_parent().name)
	
	check_map_editor()
	await get_tree().process_frame  # ✅ Wait for 1 frame before populating
	
	print("🎨 Adjusting Trigger Editor Panel...")
	_setup_panel_position()  # ✅ Separate function for size & position
	_populate_dropdowns()  # ✅ Separate function for dropdowns
	_connect_signals()  # ✅ Separate function for connecting buttons
	
	# ✅ Force dropdown sizes
	cause_dropdown.custom_minimum_size = Vector2(200, 30)
	area_type_dropdown.custom_minimum_size = Vector2(200, 30)
	sound_effect_dropdown.custom_minimum_size = Vector2(200, 30)
	
	# ✅ Delay before searching for MapEditor
	await get_tree().process_frame  # ✅ Wait for 2 frames before searching

		
	 # ✅ Try searching for MapEditor again
	var map_editors = get_tree().get_nodes_in_group("MapEditor")
	if map_editors.size() > 0:
		var map_editor = map_editors[0]
		print("✅ Found MapEditor: " + map_editor.name)

		# ✅ DEBUG: Confirm if this actually hides MapEditor
		map_editor.visible = true
		await get_tree().process_frame  # ✅ Wait for a frame to apply visibility change
		print("🛑 MapEditor visibility set to:", map_editor.visible)
	else:
		print("❌ ERROR: MapEditor still not found after delay!")
		
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100
	visible = true   
	print("✅ TriggerEditorPanel is now VISIBLE & ON TOP")
	# ✅ Ensure this window always stays on top
	

func check_map_editor():
	var found = false
	while not found:
		var map_editors = get_tree().get_nodes_in_group("MapEditor")
		if map_editors.size() > 0:
			var map_editor = map_editors[0]
			print("✅ Found MapEditor: " + map_editor.name)
			map_editor.visible = false
			found = true  # ✅ Stop checking once found
		else:
			print("❌ Still waiting for MapEditor...")

		await get_tree().process_frame  # ✅ Wait and check again next frame


func _gui_input(event):
	if event is InputEventMouseButton:
		print("🖱 UI Mouse Click Detected on TriggerEditorPanel!")

# ✅ Function to set size and position
func _setup_panel_position():
	if get_parent():
		self.set_size(Vector2(1300, 725))  # ✅ Set panel size
		var screen_size = get_parent().get_viewport_rect().size
		self.set_position((screen_size - self.size) / 2)  # ✅ Center it
		print("✅ Trigger Editor Positioned at:", self.position)
	else:
		print("❌ ERROR: TriggerEditorPanel has no parent UI!")

# ✅ Function to populate dropdowns
func _populate_dropdowns():
	print("🎛️ Populating Dropdowns...")
	
	if not cause_dropdown or not area_type_dropdown or not sound_effect_dropdown:
		print("❌ ERROR: One or more dropdown nodes are NULL!")
		return  # 🚨 Prevents crash if they are missing
		
	# Cause Dropdown
	cause_dropdown.add_item("Piece Captured")
	cause_dropdown.add_item("Piece Enters Tile")
	cause_dropdown.add_item("Turn Count Reached")

	# Area Type Dropdown
	area_type_dropdown.add_item("Local")
	area_type_dropdown.add_item("Global")

	# Sound Effect Dropdown
	sound_effect_dropdown.add_item("None")
	sound_effect_dropdown.add_item("Victory Fanfare")
	sound_effect_dropdown.add_item("Trap Activated")
	
	print("📌 Cause Dropdown Items:", cause_dropdown.get_item_count())
	print("📌 Area Type Dropdown Items:", area_type_dropdown.get_item_count())
	print("📌 Sound Effect Dropdown Items:", sound_effect_dropdown.get_item_count())
	
 # ✅ Force selection of the first item (so it's definitely set)
	if cause_dropdown.get_item_count() > 0:
		cause_dropdown.selected = 0
	if area_type_dropdown.get_item_count() > 0:
		area_type_dropdown.selected = 0
	if sound_effect_dropdown.get_item_count() > 0:
		sound_effect_dropdown.selected = 0

	print("📌 Cause Dropdown Selected Item:", cause_dropdown.get_item_text(cause_dropdown.selected))
	print("📌 Area Type Dropdown Selected Item:", area_type_dropdown.get_item_text(area_type_dropdown.selected))
	print("📌 Sound Effect Dropdown Selected Item:", sound_effect_dropdown.get_item_text(sound_effect_dropdown.selected))


	print("✅ Dropdowns Loaded!")

# ✅ Function to connect UI signals
func _connect_signals():
	cause_dropdown.connect("item_selected", Callable(self, "_on_cause_dropdown_item_selected"))
	save_button.connect("pressed", Callable(self, "_save_trigger"))
	print("✅ Signals Connected!")

func setup_trigger(trigger: Trigger = null):
	if trigger:
		current_trigger = trigger
		_populate_existing_trigger(trigger)
	else:
		current_trigger = Trigger.new()
		
	_populate_trigger_list()

func _populate_trigger_list():
	print("🔄 Populating Trigger List...")

	# ✅ Clear the list first (avoid duplicate entries)
	for child in trigger_list.get_children():
		child.queue_free()

	# ✅ Add each saved trigger back to the list
	for trigger in get_tree().get_nodes_in_group("Triggers"):
		var button = Button.new()
		button.text = trigger.cause
		button.set_meta("trigger_data", trigger)

		trigger_list.add_child(button)
		button.connect("pressed", Callable(self, "_on_edit_trigger_pressed").bind(trigger))

	print("✅ Trigger List Populated!")


func _on_cause_dropdown_item_selected(index):
	var selected_text = cause_dropdown.get_item_text(index)
	print("🎯 Selected Trigger Cause:", selected_text)


func _populate_existing_trigger(trigger):
	print("🔄 Populating Existing Trigger Effects...")
	# ✅ Get reference to Left and Right Columns
	var left_column = effect_list_container.get_node("HBoxContainer/LeftColumn")
	var right_column = effect_list_container.get_node("HBoxContainer/RightColumn")

	var hbox_container = effect_list_container.get_node("HBoxContainer")
	print("📏 ScrollContainer Height:", effect_list_container.get_parent().size.y)
	print("📏 HBoxContainer Height:", hbox_container.size.y)
	print("📏 LeftColumn Height:", left_column.size.y)
	print("📏 RightColumn Height:", right_column.size.y)
	print("✅ Effect List Populated with:", trigger.effects.size(), "effects.")
	
	# ✅ Clear old UI before adding new effects
	for child in left_column.get_children():
		child.queue_free()
	for child in right_column.get_children():
		child.queue_free()


	# ✅ Distribute effects evenly
	for i in range(trigger.effects.size()):
		var effect_ui = _create_effect_ui(trigger.effects[i])

		if i % 2 == 0:
			print("📌 Adding Effect to LEFT Column:", trigger.effects[i].effect_type)
			left_column.add_child(effect_ui)  # ✅ First, third, fifth → Left
		else:
			print("📌 Adding Effect to RIGHT Column:", trigger.effects[i].effect_type)
			right_column.add_child(effect_ui)  # ✅ Second, fourth, sixth → Right



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
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # ✅ Allow stretching
	hbox.custom_minimum_size = Vector2(250, 50)  # ✅ Adjust width to prevent squeezing

	var dropdown = OptionButton.new()
	dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # ✅ Expand to fill space

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
	dropdown.connect("item_selected", Callable(self, "_update_effect").bind(effect))
	hbox.add_child(dropdown)

	var remove_button = Button.new()
	remove_button.text = "X"
	remove_button.connect("pressed", Callable(self, "_remove_effect").bind(effect, hbox))
	hbox.add_child(remove_button)

	return hbox



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


func _remove_effect(effect, hbox):
	current_trigger.effects.erase(effect)
	hbox.queue_free()

func _save_trigger():
	current_trigger.cause = cause_dropdown.get_selected_text()
	current_trigger.trigger_area_type = Trigger.AreaType.LOCAL if area_type_dropdown.selected == 0 else Trigger.AreaType.GLOBAL
	current_trigger.trigger_tiles = tile_selector.get_selected_tiles()
	current_trigger.sound_effect = sound_effect_dropdown.get_selected_text()

	emit_signal("trigger_saved", current_trigger)
	queue_free()


func _on_close_button_pressed() -> void:
	print("❌ Closing Trigger Editor...")
	queue_free()  # ✅ Remove TriggerEditorPanel from the scene tree

func _on_cancel_button_pressed() -> void:
	print("🚫 Cancel Button Pressed. Closing without saving.")
	queue_free()  # ✅ Just close without saving
