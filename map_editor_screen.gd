extends Control  # Attach this to the root node of map_editor_screen.tscn

var map_data = {}  # Store loaded map data

var current_filename: String = ""  # Tracks the current map file name
var save_as_mode = false  # Track if we are saving as a new file

@onready var map_menu_panel = $MapMenuPanel  # Reference the panel
@onready var toggle_menu_button = $ToggleMapMenuButton  # Reference the button

@onready var error_popup = $ErrorPopup
@onready var error_message = $ErrorPopup/MarginContainer/VBoxContainer/ErrorMessage

@onready var save_map_popup = $SaveMapPopup
@onready var save_map_button = $MapMenuPanel/Panel/VBoxContainer/SaveMapButton  # Reference the button
@onready var grid_container = $HSplitContainer/MarginContainer/MainMapDisplay/GridContainer  # Reference to GridContainer
@onready var map_name_input = $SaveMapPopup/MarginContainer/VBoxContainer/MapNameInput
@onready var save_map_confirm_button = $SaveMapPopup/MarginContainer/VBoxContainer/HBoxContainer/SaveMapConfirmButton
@onready var save_as_button = $SaveMapPopup/MarginContainer/VBoxContainer/HBoxContainer/SaveAsMapConfirmButton  # Add reference

func _ready():
	map_menu_panel.visible = false  # Hide the menu by default
	map_menu_panel.position = Vector2(7, 900)  # Move below the screen
	
	save_map_popup.visible = false
	save_map_confirm_button.connect("pressed", Callable(self, "_on_confirm_save_map"))
	save_as_button.connect("pressed", Callable(self, "_on_save_as_button_pressed"))  # New Save As connection

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
		
		
		


func set_map_data(data):
	map_data = data
	print("Main scene received map data:", map_data)
	
	if grid_container:
		grid_container.load_map_data(map_data)

func _on_save_map_button_pressed():
	if current_filename.is_empty():
		print("🔹 No filename found, opening Save As menu...")
		open_save_as_popup()
	else:
		print("💾 Saving existing map:", current_filename)
		grid_container.save_map(current_filename)
		

func open_save_as_popup():
	map_name_input.text = current_filename if current_filename != "" else ""
	save_map_popup.popup_centered()

func _save_map(map_name: String):
	if map_name.is_empty():
		print("Map name cannot be empty!")
		return
	
	current_filename = map_name  # Update the last saved filename
	grid_container.save_map(map_name)
	print("Map saved:", map_name)
	


func _on_save_map_popup_close_requested() -> void:
	save_map_popup.hide()


func _on_back_to_main_pressed() -> void:
	print("🔙 Returning to Main Screen...")
	
	# Load the main screen scene
	var main_screen_scene = load("res://first_selection_screen.tscn").instantiate()
	
	# Switch to the main screen
	get_tree().root.add_child(main_screen_scene)
	get_tree().current_scene.queue_free()  # Remove current scene
	get_tree().current_scene = main_screen_scene  # Set new scene


func _on_save_as_map_button_pressed() -> void:
	print("📝 Save As button pressed")
	save_as_mode = true  # Indicate that we're in "Save As" mode
	open_save_as_popup()  # ✅ Open pop-up
	


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
		
		# ✅ Write the duplicated data to a new file
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
		
	save_map_popup.hide()  # ✅ Close the pop-up



func display_error(message: String):
	if error_popup and error_message:
		error_message.text = message
		error_popup.visible = false  # Ensure it starts hidden
		error_popup.popup_centered()  # Show the popup
	else:
		print("❌ Error Popup UI is missing!")

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


func _on_error_popup_ok_button_pressed() -> void:
	error_popup.hide()
