extends Control

		## Map Editor Screen Info ##
@onready var current_filename: String = ""  # Tracks the current map file name

		## Error Pop Up VARIABLES ##
@onready var error_popup = $ErrorPopup
@onready var error_message = $ErrorPopup/MarginContainer/VBoxContainer/ErrorMessage
@onready var confirmation_label = $LoadSaveMapPopUp/MarginContainer/VBoxContainer/ConfirmationMessage


		## Map Editor Pop Up VARIABLES ##
@onready var title_label = $LoadSaveMapPopUp/MarginContainer/VBoxContainer/PopUpTitle
@onready var map_list = $LoadSaveMapPopUp/MarginContainer/VBoxContainer/MapList
@onready var map_name_input = $LoadSaveMapPopUp/MarginContainer/VBoxContainer/MapNameInput
@onready var load_button = $LoadSaveMapPopUp/MarginContainer/VBoxContainer/HBoxContainer/LoadButton
@onready var save_button = $LoadSaveMapPopUp/MarginContainer/VBoxContainer/HBoxContainer/SaveButton
@onready var save_as_button = $LoadSaveMapPopUp/MarginContainer/VBoxContainer/HBoxContainer/SaveAsButton
@onready var load_save_map_popup = $LoadSaveMapPopUp


## # # # NEED TO GET PROPER PANEL COORDINATES GLOBAL SEND THIS TO OTHER SCENE SCRIPT # # # # # # # 
var grid_container = null # No @onready because it needs to be set manually

var save_as_mode = false  # Track if we are saving as a new file
var popup_mode = "load"  # "load" or "save"

func _ready():
	confirmation_label.hide()  # ✅ Ensure it's hidden initially


func open_as_load():
	popup_mode = "load"
	title_label.text = "Load Map"
	
	map_name_input.hide()  # No need for input in load mode
	save_button.hide()
	save_as_button.hide()
	load_button.show()
	
	# ✅ Reference first_selection_screen and call populate_map_list()
	var first_screen = get_node("/root/Control/FirstSelectionScreen")  # Adjust path if needed
	if first_screen and first_screen.has_method("populate_map_list"):
		first_screen.populate_map_list()
	else:
		print("❌ ERROR: Could not find FirstSelectionScreen or populate_map_list()!")

	show()

func open_as_save():
	popup_mode = "save"
	title_label.text = "Save Map"
	map_name_input.show()
	save_button.show()
	save_as_button.show()
	load_button.hide()
	
	# ✅ Call populate_map_list() from first_selection_screen
	var first_screen = get_node("/root/Control/FirstSelectionScreen")  
	if first_screen and first_screen.has_method("populate_map_list"):
		first_screen.populate_map_list()
	else:
		print("❌ ERROR: Could not find FirstSelectionScreen or populate_map_list()!")
	
	show()


func set_popup_title(title_text: String):
	if title_label:
		title_label.text = title_text

func show_confirmation(message: String):
	if confirmation_label:
		confirmation_label.text = message
		confirmation_label.show()
		await get_tree().create_timer(2.0).timeout  # ✅ Show for 2 seconds
		confirmation_label.hide()
	else:
		print("❌ ERROR: ConfirmationMessage label is missing!")


func _on_map_name_input_changed(new_text: String):
	if confirmation_label:
		confirmation_label.hide()  # Hide any previous confirmation messages
	if error_popup and error_message:
		error_message.hide()  # Hide error message when the user types


func set_grid_container(grid_ref):
	grid_container = grid_ref
	print("✅ grid_container reference set in pop-up:", grid_container)
	
	
				## ## ## ## ## ## ## ## ##
				## Button Pressed Logic ##
				## ## ## ## ## ## ## ## ##



func _on_load_button_pressed() -> void:
	var selected = map_list.get_selected_items()
	if selected.size() > 0:
		var map_name = map_list.get_item_text(selected[0])  # ✅ Get selected map name
		
		if grid_container:
			grid_container.load_map(map_name)  # ✅ Directly load the map
			print("📂 Loaded map:", map_name)
			hide()
		else:
			print("❌ ERROR: grid_container is not set in MapEditorPopUp!")
	else:
		print("❌ ERROR: No map selected!")
		display_error("Please select a map to load.")
		
	hide()


func _on_save_button_pressed() -> void:
	if grid_container:
		var map_name = map_name_input.text.strip_edges()
		if map_name == "":
			print("❌ ERROR: Map name cannot be empty!")
			display_error("Map name cannot be empty!")
			return  # ✅ Prevents saving if the name is empty
		
		grid_container.save_map(map_name)  # ✅ Calls grid_container function

		# ✅ Show confirmation
		show_confirmation("Map saved successfully!")

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


func _on_save_map_popup_close_requested() -> void:
	load_save_map_popup.hide()



	## Open Save Menu Functionality ##


func _on_confirm_save_map():
	var new_map_name = map_name_input.text.strip_edges()
	   
	if new_map_name.is_empty():
		print("❌ Map name cannot be empty!")
		display_error("Map name cannot be empty!")
		return
		
	if save_as_mode:
		# ✅ "Save As" Mode - Duplicate the map under a new name
		print("📂 Saving as a new map:", new_map_name)
		
		var new_file_path = "user://maps/" + new_map_name.to_lower() + ".json"
		
		# ✅ Ensure the original map is saved before duplicating
		if current_filename.is_empty():
			print("❌ No current map to duplicate!")
			display_error("No current map to duplicate!")
			return
			
		grid_container.save_map(current_filename)  # Save the current map state
		
		# ✅ Load the existing map data
		var original_file_path = "user://maps/" + current_filename.to_lower() + ".json"
		if not FileAccess.file_exists(original_file_path):
			print("❌ Original map file does not exist:", original_file_path)
			display_error("Original map file does not exist.")
			return
		
		var file = FileAccess.open(original_file_path, FileAccess.READ)
		if file == null:
			print("❌ Error: Could not open original map file for duplication")
			display_error("Error: Could not open original map file.")
			return
			
			
		var original_map_data = file.get_as_text()
		file.close()
		
		# ✅ Wri te the duplicated data to a new file
		var new_file = FileAccess.open(new_file_path, FileAccess.WRITE)
		if new_file:
			new_file.store_string(original_map_data)
			new_file.close()
			print("✅ Map duplicated successfully:", new_map_name)
		else:
			print("❌ Error saving duplicated map:", new_map_name)
			display_error("Error saving duplicated map.")
			return
			
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
				
			# ✅ Update the currently opened map name
		current_filename = new_map_name
		save_as_mode = false  # ✅ Reset mode after saving
				
		# ✅ Notify main menu that a new map is available
		print("🔄 Notifying main menu to refresh map list.")
		get_tree().root.call_deferred("emit_signal", "map_list_updated")
		
	else:
		# ✅ Regular "Save" (Not Save As)
		print("💾 Saving map:", new_map_name)
		grid_container.save_map(new_map_name.to_lower())
		current_filename = new_map_name  # ✅ Update the current map name
		
	load_save_map_popup.hide()  # ✅ Close the pop-up


func save_map(map_name):
	if grid_container:
		grid_container.save_map(map_name)  # ✅ Calls existing function in grid_container.gd
		print("✅ Map saved from pop-up:", map_name)
	else:
		print("❌ ERROR: grid_container is not set in MapEditorPopUp!")

func load_map(map_name):
	print("load map function")
	pass

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
	error_popup.hide()

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
	pass # Replace with function body.


func _on_load_save_map_pop_up_popup_hide() -> void:
	print("🔴 LoadSaveMapPopUp closed")
	hide()  # ✅ Hide the pop-up when "X" is pressed
