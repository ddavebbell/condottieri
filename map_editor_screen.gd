extends Control  # Attach this to the root node of map_editor_screen.tscn


var map_data = {}  # Store loaded map data

@onready var map_name_input = $MapEditorPopUp/LoadSaveMapPopUp/MarginContainer/VBoxContainer/MapNameInput


@onready var current_filename: String = ""  # Tracks the current map file name

## Pop Up Components Referenced  ##
@onready var load_save_map_popup_scene = $MapEditorPopUp  # Reference to the popup scene
@onready var load_save_map_popup_menu = $MapEditorPopUp/LoadSaveMapPopUp
@onready var load_save_map_popup_title = $MapEditorPopUp/LoadSaveMapPopUp/MarginContainer/VBoxContainer/PopUpTitle
@onready var load_save_map_confirmation_message = $MapEditorPopUp/LoadSaveMapPopUp/MarginContainer/VBoxContainer/ConfirmationMessage

@onready var map_menu_panel = $MapMenuPanel  # Reference the panel
@onready var toggle_menu_button = $ToggleMapMenuButton  # Reference the button
@onready var grid_container = $HSplitContainer/MarginContainer/MainMapDisplay/GridContainer  # Reference to GridContainer


func _ready():
	if grid_container:
		grid_container.connect("map_loaded", Callable(self, "_on_map_loaded"))
	
	var grid_container_ref = get_node("HSplitContainer/MarginContainer/MainMapDisplay/GridContainer")
	
	await get_tree().process_frame  # Wait to ensure nodes are loaded

	if load_save_map_popup_scene and grid_container_ref:
		load_save_map_popup_scene.set_grid_container(grid_container_ref)  # ✅ Pass grid_container reference
	else:
		print("❌ ERROR: Could not find MapEditorPopUp or grid container")
	
	print("current filename is..... ",current_filename)
	load_save_map_popup_scene.visible = false  # Ensure the pop-up is hidden initially
	map_menu_panel.visible = false  # Hide the menu by default
	map_menu_panel.position = Vector2(7, 900)  # Move below the screen
	

func _on_map_loaded(map_name):
	current_filename = map_name  # ✅ Update map filename
	print("📂 Map Editor Screen - Current filename set to:", current_filename)

func _on_toggle_map_menu_button_pressed():
	var tween = create_tween()  # Create a new Tween dynamically
	
	if map_menu_panel.visible:
		print("📂 Hiding Map Menu Panel")
		tween.tween_property(map_menu_panel, "position", Vector2(7, 900), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)  # Slide down
		await tween.finished
		map_menu_panel.visible = false
		toggle_menu_button.text = "Open Menu"  # Change text to Open
	else:
		print("📂 Showing Map Menu Panel")
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

	# ✅ If the map has NOT been saved before, open Save As pop-up
	if current_filename.is_empty():
		print("🔹 No filename found, opening Save As menu...")
		load_save_map_popup_scene.open_as_save()  # ✅ Open pop-up only if first save
	else:
		# ✅ If the map has a filename, just save it
		print("💾 Saving existing map:", current_filename)
		grid_container.save_map(current_filename)  # ✅ Save directly
		show_confirmation_popup("✅ Map saved successfully!")  # ✅ Show confirmation message



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

	# ✅ Open the pop-up for loading a map
	load_save_map_popup_scene.open_as_load()
	open_load_map_popup("Load Map")

	# ✅ Retrieve the selected map name
	var selected_button = get_selected_map_button()
	if selected_button:
		var selected_map_name = selected_button.text  # ✅ Get the name from the button text
		print("✅ Confirmation displayed for loaded map:", selected_map_name)

		# ✅ Load the selected map
		if grid_container:
			grid_container.load_map(selected_map_name)
			show_confirmation_popup("📂 Loaded map: " + selected_map_name)
	
			print("✅ Map loaded successfully:", selected_map_name)

			## ✅ Ensure the pop-up is fully closed
			#await get_tree().process_frame  # ✅ Wait for UI update
			#if load_save_map_popup_menu:
				#print(load_save_map_popup_menu)
				#load_save_map_popup_menu.hide()
				#print("🛑 LoadSaveMapPopUp menu hidden after loading!")
#
			#if load_save_map_popup_scene:
				#print(load_save_map_popup_scene)
				#load_save_map_popup_scene.hide()
				#print("🛑 LoadSaveMapPopUp scene hidden after loading!")

		else:
			print("❌ ERROR: grid_container is not set in MapEditorPopUp!")
	else:
		print("❌ ERROR: No map selected for loading!")


func get_selected_map_button():
	for child in load_save_map_popup_menu.get_node("MarginContainer/VBoxContainer/ScrollContainer/MapList").get_children():
		if child is Button and child.modulate == Color(0.6, 1, 0.6, 1):  # ✅ Check if the button is highlighted
			return child
	return null


func _on_back_to_main_pressed() -> void:
	print("🔙 Returning to Main Screen...")
	
	# Load the main screen scene
	var main_screen_scene = load("res://first_selection_screen.tscn").instantiate()
	
	# Switch to the main screen
	get_tree().root.add_child(main_screen_scene)
	get_tree().current_scene.queue_free()  # Remove current scene
	get_tree().current_scene = main_screen_scene  # Set new scene
	

func open_load_map_popup(title_text: String):
	if load_save_map_popup_menu and load_save_map_popup_title:
		load_save_map_popup_scene.set_popup_title(title_text)
		load_save_map_popup_menu.popup_centered()
		print("📂 Opening Load Map pop-up:", title_text)
	else:
		print("❌ ERROR: load_save_map_popup_scene is not set!")

func show_confirmation_popup(message: String):
	if load_save_map_popup_menu and load_save_map_confirmation_message:
		load_save_map_confirmation_message.text = message  # ✅ Set confirmation message text
		load_save_map_confirmation_message.show()  # ✅ Make it visible
		await get_tree().create_timer(2.0).timeout  # ✅ Keep visible for 2 seconds
		load_save_map_confirmation_message.hide()  # ✅ Hide after delay
		print("✅ Showing confirmation message:", message)
	else:
		print("❌ ERROR: load_save_map_popup_menu or load_save_map_confirmation_message is not set!")
