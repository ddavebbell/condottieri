extends Control

		## Map Editor Screen Info ##
@onready var current_filename: String = ""  # Tracks the current map file name
@onready var first_selection_screen = get_tree().get_root().find_child("FirstSelectionScreen", true, false)


		## Error Pop Up VARIABLES ##
@onready var error_popup = $ErrorPopup
@onready var error_message = $ErrorPopup/MarginContainer/VBoxContainer/ErrorMessage
@onready var error_ok_button = $ErrorPopup/MarginContainer/VBoxContainer/ErrorPopupOkButton


		## Map Editor Pop Up VARIABLES ##
@onready var load_save_map_popup = $LoadSaveMapPopUp
@onready var confirmation_label = $LoadSaveMapPopUp/MarginContainer/VBoxContainer/ConfirmationMessage
@onready var title_label = $LoadSaveMapPopUp/MarginContainer/VBoxContainer/PopUpTitle
@onready var thumbnail_view = $LoadSaveMapPopUp/MarginContainer/VBoxContainer/ThumbnailView
@onready var map_list = $LoadSaveMapPopUp/MarginContainer/VBoxContainer/ScrollContainer/MapList
@onready var map_name_input = $LoadSaveMapPopUp/MarginContainer/VBoxContainer/MapNameInput
@onready var load_button = $LoadSaveMapPopUp/MarginContainer/VBoxContainer/HBoxContainer/LoadButton
@onready var save_button = $LoadSaveMapPopUp/MarginContainer/VBoxContainer/HBoxContainer/SaveButton
@onready var save_as_button = $LoadSaveMapPopUp/MarginContainer/VBoxContainer/HBoxContainer/SaveAsButton


var grid_container = null # No @onready because it needs to be set manually
var save_as_mode = false  # Track if we are saving as a new file
var popup_mode = "load"  # "load" or "save"
var selected_map_name: String = ""


func _ready():
	confirmation_label.hide()  # ✅ Ensure it's hidden initially
	
	thumbnail_view.visible = true
	thumbnail_view.custom_minimum_size = Vector2(256, 256)  # Ensure proper size
	thumbnail_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED  # Maintain aspect ratio

	
	# ✅ Manually connect the error OK button to the function
	if error_ok_button:
		error_ok_button.connect("pressed", _on_error_popup_ok_button_pressed)
	else:
		print("❌ ERROR: error_ok_button not found!")

func populate_saveload_map_list():
	print("🔄 Attempting to populate Save/Load map list...")

	if not map_list:
		print("❌ ERROR: map_list_panel not found in LoadSaveMapPopUp!")
		return

	# ✅ Clear existing map list items
	for child in map_list.get_children():
		child.queue_free()

	# ✅ Check if the maps directory exists
	var dir_path = "user://maps/"
	var dir = DirAccess.open(dir_path)

	if dir == null or not DirAccess.dir_exists_absolute(dir_path):
		print("❌ No maps directory found for Save/Load!")
		return  # Exit early

	# ✅ Read all `.json` files in `user://maps/`
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var maps_found = false

	while file_name != "":
		if file_name.ends_with(".json"):
			maps_found = true
			var map_name = file_name.trim_suffix(".json")

			# ✅ Create a button for each map
			var button = Button.new()
			button.text = map_name
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			button.custom_minimum_size = Vector2(0, 35)

			# ✅ Ensure `_on_saveload_map_selected()` is called when clicking a button
			button.connect("pressed", Callable(self, "_on_saveload_map_selected").bind(map_name, button))
			map_list.add_child(button)

			print("📂 Added map to list:", map_name)

		file_name = dir.get_next()

	dir.list_dir_end()

	# ✅ If no maps exist, show placeholder text
	if not maps_found:
		var no_maps_label = Label.new()
		no_maps_label.text = "No saved maps available"
		no_maps_label.add_theme_color_override("font_color", Color(1, 0, 0))  
		map_list.add_child(no_maps_label)
		print("⚠️ No saved maps found in Save/Load.")

	print("✅ populate_saveload_map_list() completed.")



func open_as_load():
	popup_mode = "load"
	title_label.text = "Load Map"
	map_name_input.hide()  

	# ✅ Print button node paths
	print("🔎 Debugging Buttons in LoadSaveMapPopUp")
	print("👉 save_button path:", save_button)
	print("👉 save_as_button path:", save_as_button)
	print("👉 load_button path:", load_button)

	if not save_button or not save_as_button or not load_button:
		print("❌ ERROR: One or more buttons were NOT found in LoadSaveMapPopUp!")
		return

	# ✅ Ensure proper button visibility
	save_button.visible = false
	save_as_button.visible = false
	load_button.visible = true  # Only Load should be visible
	print("✅ Button visibility updated for Load Map mode.")

	populate_saveload_map_list()  # ✅ Populate the list

	var map_list_panel = $LoadSaveMapPopUp/MarginContainer/VBoxContainer/ScrollContainer/MapList
	if map_list_panel:
		map_list_panel.visible = true  
		print("✅ Forced map_list_panel to be visible!")

	load_save_map_popup.show()


func open_as_save():
	popup_mode = "save"
	title_label.text = "Save map as..."
	map_name_input.show()

	# ✅ Print button node paths
	print("🔎 Debugging Buttons in LoadSaveMapPopUp")
	print("👉 save_button path:", save_button)
	print("👉 save_as_button path:", save_as_button)
	print("👉 load_button path:", load_button)

	if not save_button or not save_as_button or not load_button:
		print("❌ ERROR: One or more buttons were NOT found in LoadSaveMapPopUp!")
		return

	# ✅ Ensure proper button visibility
	save_button.visible = true
	save_as_button.visible = true
	load_button.visible = false  # Hide Load button
	print("✅ Button visibility updated for Save Map mode.")

	populate_saveload_map_list()  # ✅ Populate the list

	var map_list_panel = $LoadSaveMapPopUp/MarginContainer/VBoxContainer/ScrollContainer/MapList
	if map_list_panel:
		map_list_panel.visible = true  
		print("✅ Forced map_list_panel to be visible!")

	load_save_map_popup.show()


func _on_saveload_map_selected(map_name: String, button: Button):
	print("✅ Selected map from Save/Load list:", map_name)

	# ✅ Highlight the selected button visually
	for child in button.get_parent().get_children():
		if child is Button:
			child.modulate = Color(1, 1, 1, 1)  # Reset all buttons to default color
	button.modulate = Color(0.6, 1, 0.6, 1)  # ✅ Highlight the selected button

	selected_map_name = map_name
	print("✅ Selected map:", selected_map_name)

	# ✅ Load and Display Thumbnail
	var thumbnail_path = "user://thumbnails/" + map_name + ".png"
	print("🔍 Checking thumbnail path:", thumbnail_path)

	if FileAccess.file_exists(thumbnail_path):
		print("🟢 Thumbnail file found:", thumbnail_path)

		var image = Image.new()
		var load_result = image.load(thumbnail_path)

		if load_result == OK:
			var texture = ImageTexture.create_from_image(image)
			thumbnail_view.texture = texture  # ✅ Set thumbnail in UI
			thumbnail_view.visible = true  # ✅ Ensure it's visible
			thumbnail_view.custom_minimum_size = Vector2(200, 200)  # ✅ Force size for debugging

			print("🖼️ Thumbnail displayed for:", selected_map_name)
		else:
			print("❌ ERROR: Failed to load image from:", thumbnail_path)
			thumbnail_view.texture = null  # ✅ Remove texture if error
	else:
		print("⚠️ No thumbnail found for", selected_map_name)
		thumbnail_view.texture = null  # ✅ Remove texture if missing
		thumbnail_view.visible = false  # ✅ Hide if no thumbnail found




func set_popup_title(title_text: String):
	if title_label:
		title_label.text = title_text

func show_confirmation_popup(message: String):
	print("🔎 Attempting to show confirmation message:", message)

	# Ensure all UI components exist
	if not load_save_map_popup:
		print("❌ ERROR: load_save_map_popup_menu is not set!")
		return

	if not confirmation_label:
		print("❌ ERROR: load_save_map_confirmation_message is not set!")
		return

	# ✅ Set the message text
	confirmation_label.text = message
	print("✅ Confirmation message text set:", message)

	# ✅ Ensure it's visible
	confirmation_label.show()
	print("🟢 Confirmation message is now visible.")

	# ✅ Keep it visible for 2 seconds, then hide it
	await get_tree().create_timer(1.0).timeout
	confirmation_label.hide()
	print("🛑 Confirmation message hidden after delay.")



func set_grid_container(grid_ref):
	grid_container = grid_ref
	print("✅ grid_container reference set in pop-up:", grid_container)
	
	
				## ## ## ## ## ## ## ## ##
				## Button Pressed Logic ##
				## ## ## ## ## ## ## ## ##


func _on_load_button_pressed() -> void:
	if selected_map_name.is_empty():
		print("❌ ERROR: No map selected!")
		display_error("Please select a map before loading.")
		return  # ✅ Stop if no map is selected

	if grid_container:
		grid_container.load_map(selected_map_name)  # ✅ Load selected map
		print("📂 Loaded map:", selected_map_name)

		# ✅ Show confirmation message after loading
		show_confirmation_popup("📂 Loaded map: " + selected_map_name)

		# ✅ Close the Save/Load Map popup
		await get_tree().process_frame  # ✅ Ensure UI updates before closing
		if load_save_map_popup:
			load_save_map_popup.hide()
			print("🛑 LoadSaveMapPopUp menu hidden after loading!")


	else:
		print("❌ ERROR: grid_container is not set in MapEditorPopUp!")  





func _on_save_button_pressed() -> void:
	if grid_container:
		var map_name = map_name_input.text.strip_edges()
		if map_name == "":
			print("❌ ERROR: Map name cannot be empty!")
			display_error("Map name cannot be empty!")
			return  # ✅ Prevents saving if the name is empty
		
		grid_container.save_map(map_name)  # ✅ Calls grid_container function

		# ✅ Show confirmation
		show_confirmation_popup("Map saved successfully!")

		# ✅ Close pop-up after saving
		await get_tree().process_frame
		hide()
	else:
		print("❌ ERROR: grid_container is not set in MapEditorPopUp!")



		# fix this
func _on_save_as_button_pressed() -> void:
	if grid_container:
		var new_map_name = map_name_input.text.strip_edges()
		
		if new_map_name != "":
			if new_map_name != current_filename:
				grid_container.save_map(new_map_name)  # ✅ Save under a new name
				current_filename = new_map_name  # ✅ Update filename
				print("✅ Map saved as new file:", new_map_name)
				hide()
			else:
				print("❌ ERROR: 'Save As' must use a different name!")
				display_error("Please enter a new name for 'Save As'!")
		else:
			print("❌ ERROR: Map name cannot be empty!")
			display_error("Map name cannot be empty!")
	else:
		print("❌ ERROR: grid_container is not set in MapEditorPopUp!")


	## Open Save Menu Functionality ##


func _on_confirm_save_map():
	var new_map_name = map_name_input.text.strip_edges()
	
	# ✅ Prevent saving an empty map name
	if new_map_name.is_empty():
		print("❌ Map name cannot be empty!")
		display_error("Map name cannot be empty!")
		return  # ❌ Do NOT proceed further

	# ✅ If "Save As" mode is active, duplicate the map under a new name
	if save_as_mode:
		print("📂 Saving as a new map:", new_map_name)
		
		var new_file_path = "user://maps/" + new_map_name.to_lower() + ".json"
		
		# ✅ Ensure the original map is saved before duplicating
		if current_filename.is_empty():
			print("❌ No current map to duplicate!")
			display_error("No current map to duplicate!")
			return  # ❌ Do NOT proceed further
			
		grid_container.save_map(current_filename)  # ✅ Save current map

		# ✅ Check if the original map file exists
		var original_file_path = "user://maps/" + current_filename.to_lower() + ".json"
		if not FileAccess.file_exists(original_file_path):
			print("❌ Original map file does not exist:", original_file_path)
			display_error("Original map file does not exist.")
			return  # ❌ Do NOT proceed further

		var file = FileAccess.open(original_file_path, FileAccess.READ)
		if file == null:
			print("❌ Error: Could not open original map file for duplication")
			display_error("Error: Could not open original map file.")
			return  # ❌ Do NOT proceed further
			
		var original_map_data = file.get_as_text()
		file.close()

		# ✅ Write the duplicated data to a new file
		var new_file = FileAccess.open(new_file_path, FileAccess.WRITE)
		if new_file:
			new_file.store_string(original_map_data)
			new_file.close()
			print("✅ Map duplicated successfully:", new_map_name)
		else:
			print("❌ Error saving duplicated map:", new_map_name)
			display_error("Error saving duplicated map.")
			return  # ❌ Do NOT proceed further

		# ✅ Duplicate the thumbnail if it exists
		var original_thumbnail_path = "user://thumbnails/" + current_filename.to_lower() + ".png"
		var new_thumbnail_path = "user://thumbnails/" + new_map_name.to_lower() + ".png"
		
		if FileAccess.file_exists(original_thumbnail_path):
			var image = Image.new()
			if image.load(original_thumbnail_path) == OK:
				image.save_png(new_thumbnail_path)
				print("✅ Thumbnail duplicated for:", new_map_name)
			else:
				print("❌ Failed to duplicate thumbnail.")
				display_error("Failed to duplicate thumbnail.")

		# ✅ Update the current filename & reset save mode
		current_filename = new_map_name
		save_as_mode = false  

		# ✅ Notify the main menu to refresh the map list
		print("🔄 Notifying main menu to refresh map list.")
		get_tree().root.call_deferred("emit_signal", "map_list_updated")

	else:
		# ✅ Regular Save (Not Save As)
		print("💾 Saving map:", new_map_name)
		grid_container.save_map(new_map_name.to_lower())
		current_filename = new_map_name  # ✅ Update the current map name

	# ✅ Now that saving is complete, hide the pop-up
	load_save_map_popup.hide()  

	# ✅ Show confirmation message after successful save
	show_confirmation_popup("✅ Map saved successfully!")


func save_map(map_name):
	if grid_container:
		grid_container.save_map(map_name)  # ✅ Calls existing function in grid_container.gd
		print("✅ Map saved from pop-up:", map_name)
	else:
		print("❌ ERROR: grid_container is not set in MapEditorPopUp!")


func _on_save_menu_input_changed(new_name):
	if new_name.strip_edges() != "":
		$SaveButton.disabled = true  # Disable normal save
		$SaveAsButton.disabled = false  # Enable Save As
	else:
		$SaveButton.disabled = false  # Enable normal save if a saved map is selected
		$SaveAsButton.disabled = true  # Disable Save As


					## ## ## ## ## ##
					## Error Logic ##
					## ## ## ## ## ## 


func _on_error_popup_ok_button_pressed() -> void:
	print("🛑 ErrorPopup OK button pressed!")

	if error_popup:
		print("✅ Hiding ONLY ErrorPopup, NOT LoadSaveMapPopUp...")

		# ✅ Use .hide() instead of popup_hide()
		error_popup.hide()  

		# ✅ Ensure LoadSaveMapPopUp stays visible
		if load_save_map_popup:
			print("👀 Keeping LoadSaveMapPopUp open...")
			load_save_map_popup.visible = true  # ✅ Force it to remain open
			load_save_map_popup.show()  # ✅ Ensure visibility

	else:
		print("❌ ERROR: error_popup not found!")


func display_error(message: String):
	if error_popup and error_message:
		error_message.text = message
		error_popup.visible = false  # Ensure it starts hidden
		error_popup.popup_centered()  # Show the popup
	else:
		print("❌ Error Popup UI is missing!")



			##    ##   ##    ##    ##    ##   ##
			## Saving / Loading Functionality ##
			##    ##   ##    ##    ##    ##   ##
			

func save_map_to_file(map_name: String):
	if map_name.is_empty():
		print("❌ Map name cannot be empty!")
		display_error("Map name cannot be empty!")
		return

	var save_path = "user://maps/" + map_name.to_lower() + ".json"
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var map_data = grid_container.get_map_data()  # Get map data from the editor
		file.store_string(JSON.stringify(map_data, "\t"))  # Save in JSON format
		file.close()
		print("✅ Map saved successfully:", save_path)
		current_filename = map_name  # Update current filename
	else:
		print("❌ Error saving map:", save_path)
		display_error("Error saving map.")


func load_map_from_file(map_name: String):
	if map_name.is_empty():
		print("❌ Map name cannot be empty!")
		display_error("Map name cannot be empty!")
		return

	var load_path = "user://maps/" + map_name.to_lower() + ".json"
	
	if not FileAccess.file_exists(load_path):
		print("❌ Error: Map file does not exist:", load_path)
		display_error("Map file does not exist.")
		return
	
	var file = FileAccess.open(load_path, FileAccess.READ)
	if file:
		var map_data = JSON.parse_string(file.get_as_text())  # Load JSON data
		file.close()
		
		if map_data:
			grid_container.load_map_data(map_data)  # Apply loaded data
			current_filename = map_name  # Update current map name
			print("✅ Map loaded successfully:", load_path)
		else:
			print("❌ Error: Failed to parse map data.")
			display_error("Failed to load map.")


func _duplicate_map(original_name: String, new_name: String):
	var original_file_path = "user://maps/" + original_name + ".json"
	var new_file_path = "user://maps/" + new_name + ".json"

	if not FileAccess.file_exists(original_file_path):
		print("❌ Error: Original map file does not exist:", original_file_path)
		return

	# ✅ Copy JSON file
	var file = FileAccess.open(original_file_path, FileAccess.READ)
	var map_data = file.get_as_text()
	file.close()

	var new_file = FileAccess.open(new_file_path, FileAccess.WRITE)
	new_file.store_string(map_data)
	new_file.close()

	print("✅ Map duplicated:", new_name)

	# ✅ Duplicate the thumbnail
	var original_thumbnail_path = "user://thumbnails/" + original_name + ".png"
	var new_thumbnail_path = "user://thumbnails/" + new_name + ".png"

	if FileAccess.file_exists(original_thumbnail_path):
		var image = Image.new()
		if image.load(original_thumbnail_path) == OK:
			image.save_png(new_thumbnail_path)
			print("✅ Thumbnail duplicated for:", new_name)
			
	print("✅ Map duplication complete.")
	

func _on_map_name_input_text_changed(new_text: String) -> void:
	if confirmation_label:
		confirmation_label.hide()  # Hide any previous confirmation messages
	if error_popup and error_message:
		error_message.hide()  # Hide error message when the user types


func _on_load_save_map_pop_up_close_requested() -> void:
	if load_save_map_popup and load_save_map_popup.visible:
		print("🛑 LoadSaveMapPopUp closed!")
		load_save_map_popup.hide()
	else:
		print("✅ LoadSaveMapPopUp was already hidden, ignoring...")
		

func _on_map_selected(map_name: String, button):
	selected_map_name = map_name  # ✅ Directly assign string
	print("✅ Selected map:", selected_map_name)
