extends Node


var _ui_registry := {}


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

		#"MapEditorPopup":
			#node.connect("tile_selected", self._on_tile_selected)

		_:
			print("No known signal hookups for: %s" % ui_name)


func show_map_list_screen(is_open_context: bool = true):
	if _ui_registry.has("map_list_screen"):
		print("🟡 Map List Screen already exists — showing existing.")
		return

	var map_list_screen = load("res://scenes/MapListScreen.tscn").instantiate()
	map_list_screen.set_context(is_open_context) 
	
	var bottom_panel = get_node("PanelContainerBottom")
	bottom_panel.add_child(map_list_screen)

	_ui_registry["map_list_screen"] = map_list_screen
	print("🟢 Map List Screen instantiated with context: %s" % ("Open" if is_open_context else "Save"))

	# Optionally emit a signal to notify others
	if not is_open_context:
		emit_signal("save_map_requested")


func open_map_editor_screen():
	var map_editor = load("res://scenes/MapEditorScreen.tscn").instantiate()
	get_tree().root.add_child(map_editor)
	# Optionally close the map list screen


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
