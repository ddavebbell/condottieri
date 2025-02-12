extends Control

@onready var cause_dropdown = $Popups/BackgroundPanel/Padding/MainLayout/ScrollContainer/ContentVBox/TriggerSettings/CauseDropdown
@onready var area_type_dropdown = $Popups/BackgroundPanel/Padding/MainLayout/ScrollContainer/ContentVBox/AreaSelection/AreaTypeDropdown
@onready var tile_selector = $Popups/BackgroundPanel/Padding/MainLayout/ScrollContainer/ContentVBox/AreaSelection/TileSelectionCustomNode
@onready var effect_list_container = $Popups/BackgroundPanel/Padding/MainLayout/ScrollContainer/ContentVBox/EffectSelection/ScrollContainer/EffectListContainer
@onready var add_effect_button = $Popups/BackgroundPanel/Padding/MainLayout/ScrollContainer/ContentVBox/EffectSelection/AddEffectButton
@onready var sound_effect_dropdown = $Popups/BackgroundPanel/Padding/MainLayout/ScrollContainer/ContentVBox/SoundEffect/SoundEffectDropdown
@onready var save_button = $Popups/BackgroundPanel/Padding/MainLayout/ScrollContainer/ContentVBox/Buttons/SaveTriggerButton


var current_trigger: Trigger = null

signal trigger_saved(trigger)

func _ready():
	print("🎨 Adjusting Trigger Editor Panel...")

	# ✅ Ensure it has a parent (UI layer)
	if get_parent():
		# ✅ Set panel size (Adjust if needed)
		self.set_size(Vector2(1300, 725))  # Width x Height

		# ✅ Center the panel inside the UI
		var screen_size = get_parent().get_viewport_rect().size
		self.set_position((screen_size - self.size) / 2)

		print("✅ Trigger Editor Positioned at: ", self.position)
	else:
		print("❌ ERROR: TriggerEditorPanel has no parent UI!")
	
	cause_dropdown.add_item("Piece Captured")
	cause_dropdown.add_item("Piece Enters Tile")
	cause_dropdown.add_item("Turn Count Reached")

	area_type_dropdown.add_item("Local")
	area_type_dropdown.add_item("Global")

	sound_effect_dropdown.add_item("None")
	sound_effect_dropdown.add_item("Victory Fanfare")
	sound_effect_dropdown.add_item("Trap Activated")

	add_effect_button.connect("pressed", Callable(self, "_add_effect"))
	save_button.connect("pressed", Callable(self, "_save_trigger"))

func setup_trigger(trigger: Trigger = null):
	if trigger:
		current_trigger = trigger
		_populate_existing_trigger(trigger)
	else:
		current_trigger = Trigger.new()

func _populate_existing_trigger(trigger):
	cause_dropdown.selected = cause_dropdown.get_item_index(trigger.cause)
	area_type_dropdown.selected = 0 if trigger.trigger_area_type == Trigger.AreaType.LOCAL else 1
	tile_selector.set_selected_tiles(trigger.trigger_tiles)  # Assume this function exists
	sound_effect_dropdown.selected = sound_effect_dropdown.get_item_index(trigger.sound_effect)

	for effect in trigger.effects:
		_create_effect_ui(effect)

func _add_effect():
	var effect = Effect.new()
	effect.effect_type = Effect.EffectType.SPAWN_REINFORCEMENTS  # Default effect type

	var effect_ui = _create_effect_ui(effect)
	effect_list_container.add_child(effect_ui)

	current_trigger.effects.append(effect)

func _create_effect_ui(effect: Effect):
	var hbox = HBoxContainer.new()
	
	var dropdown = OptionButton.new()
	dropdown.add_item("Spawn Reinforcements")
	dropdown.add_item("Upgrade Piece")
	dropdown.add_item("Remove Piece")
	dropdown.add_item("Activate Trap")
	dropdown.selected = effect.effect_type

	dropdown.connect("item_selected", Callable(self, "_update_effect").bind(effect))
	hbox.add_child(dropdown)

	var remove_button = Button.new()
	remove_button.text = "X"
	remove_button.connect("pressed", Callable(self, "_remove_effect").bind(effect, hbox))
	hbox.add_child(remove_button)

	return hbox

func _update_effect(effect, selected_index):
	effect.effect_type = selected_index

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
	print("Close Button Pressed")
	return
