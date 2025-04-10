extends Node


var _ui_registry := {}


#region Register and Deregister

func register_ui(ui_name: String, node: Node):
	if _ui_registry.has(ui_name):
		push_warning("UI already registered with name: %s — overwriting." % ui_name)
	
	_ui_registry[ui_name] = node
	_connect_signals_for(ui_name, node)


func _connect_signals_for(ui_name: String, node: Node):
	match ui_name:
		"TaskBar":
			node.connect("new_map_requested", MapManager._on_new_map_requested)
			node.connect("open_map_requested", MapManager._on_open_map_requested)
			node.connect("save_map_requested", MapManager._on_save_map_requested)

		"MapEditorScreen":
			node.connect("spawn_map_info_screen", self._on_spawn_map_info_screen_requested)

		_:
			print("No known signal hookups for: %s" % ui_name)


func deregister_ui(ui_name: String):
	if not _ui_registry.has(ui_name):
		push_warning("Tried to deregister missing UI: %s" % ui_name)
		return

	var node = _ui_registry[ui_name]

	# Disconnect known signals
	_disconnect_signals_for(ui_name, node)

	# Remove from registry
	_ui_registry.erase(ui_name)


func _disconnect_signals_for(ui_name: String, node: Node):
	match ui_name:
		"TaskBar":
			if node.is_connected("new_map_requested", MapManager._on_new_map_requested):
				node.disconnect("new_map_requested", MapManager._on_new_map_requested)
			if node.is_connected("open_map_requested", MapManager._on_open_map_requested):
				node.disconnect("open_map_requested", MapManager._on_open_map_requested)
			if node.is_connected("save_map_requested", MapManager._on_save_map_requested):
				node.disconnect("save_map_requested", MapManager._on_save_map_requested)

		"MapEditorScreen":
			if node.is_connected("spawn_map_info_screen", self._on_spawn_map_info_screen_requested):
				node.disconnect("spawn_map_info_screen", self._on_spawn_map_info_screen_requested)

		_:
			print("No known signal disconnections for: %s" % ui_name)

#endregion



## MAP LIST SCREEN -> spawn from Map Editor Screen
func show_map_list_screen(is_open_context: bool = true):
	if _ui_registry.has("map_list_screen"):
		print("🟡 Map List Screen already exists -> If this runs you need to fix the problem.")
		# If visible already
		return

	var map_list_screen = load("res://scenes/MapListScreen.tscn").instantiate()
	map_list_screen.set_context(is_open_context) 
	
	var bottom_panel = get_node("PanelContainerBottom")
	bottom_panel.add_child(map_list_screen)

	print("🟢 Map List Screen instantiated with context: %s" % ("Open" if is_open_context else "Save"))

	# Optionally emit a signal to notify MapManager to save. Seems like needs fix tho.
	if not is_open_context:
		emit_signal("save_map_requested")


## MAP INFO SCREEN -> spawn from Map Editor Screen
func _on_spawn_map_info_screen_requested() -> void:
	print("_on_spawn_map_info_screen_requested")
	if _ui_registry.has("MapInfoScreen"):
		
		print("🟡 Map Info Screen already exists — showing existing.")
		return
	
	var map_info_screen = load("res://scenes/MapInfoScreen.tscn").instantiate()
	map_info_screen.connect("popup_closed", Callable(self, "_on_map_info_screen_closed"))

	var main_scene = get_tree().root.get_node("MainScene")
	main_scene.add_child(map_info_screen) 


func _on_map_info_screen_closed():
	print("📢 MapInfoScreen closed, refreshing editor screen if visible")
	if _ui_registry.has("MapEditorScreen"):
		var map_editor = _ui_registry["MapEditorScreen"]
		map_editor._refresh_current_map()



func open_main_scene_with_task_bar_and_no_bottom():
	# opens main scene with task bar and nothing else
	var main_scene = load("res://scenes/MainScene.tscn").instantiate()
	get_tree().root.add_child(main_scene)
	
	var task_bar = load("res://scenes/TaskBar.tscn").instantiate()
	main_scene.get_node("PanelContainerTop").add_child(task_bar)


func open_map_editor_screen_with_selected_map():
	var main_scene = get_tree().root.get_node("MainScene")
	main_scene.load_screen("res://scenes/MapEditorScreen.tscn")

	# opens map editor in main scene/task bar shell

	
	var task_bar = load("res://scenes/TaskBar.tscn").instantiate()
	main_scene.get_node("PanelContainerTop").add_child(task_bar)
	
	var map_editor = load("res://scenes/MapEditorScreen.tscn").instantiate()
	main_scene.get_node("PanelContainerBottom").add_child(map_editor)


func open_open_map_flow():
	print("🛠️ UIManager: opening open map flow")
	
	var main_scene = load("res://scenes/MainScene.tscn").instantiate()
	get_tree().root.add_child(main_scene)
	_ui_registry["main_scene"] = main_scene
	
	spawn_taskbar(main_scene)
	
	var map_list_screen = load("res://scenes/MapListScreen.tscn").instantiate()
	main_scene.get_node("PanelContainerBottom").add_child(map_list_screen)
	map_list_screen.is_open_map_context(true)


func open_open_map_flow_from_title_screen():
	print("🛠️ UIManager: opening open map flow")
	
	var main_scene = load("res://scenes/MainScene.tscn").instantiate()
	get_tree().root.add_child(main_scene)
	_ui_registry["main_scene"] = main_scene
	
	var map_list_screen = load("res://scenes/MapListScreen.tscn").instantiate()
	main_scene.get_node("PanelContainerBottom").add_child(map_list_screen)
	map_list_screen.is_open_map_context(true)


func open_new_map_flow():
	print("🛠️ UIManager: opening new map flow")
	
	var main_scene = load("res://scenes/MainScene.tscn").instantiate()
	get_tree().root.add_child(main_scene)
	_ui_registry["main_scene"] = main_scene
	
	spawn_taskbar(main_scene)
	
	var map_editor_screen = load("res://scenes/MapEditorScreen.tscn").instantiate()
	main_scene.get_node("PanelContainerBottom").add_child(map_editor_screen)


func spawn_taskbar(main_scene: Node):
	var top_panel = main_scene.get_node("PanelContainerTop")
	var task_bar = load("res://scenes/TaskBar.tscn").instantiate()
	top_panel.add_child(task_bar)
