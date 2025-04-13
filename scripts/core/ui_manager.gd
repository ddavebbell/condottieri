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
			node.connect("open_map_info_screen", self._on_open_map_info_screen_requested)

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
			if node.is_connected("open_map_info_screen", self._on_open_map_info_screen_requested):
				node.disconnect("open_map_info_screen", self._on_open_map_info_screen_requested)

		_:
			print("No known signal disconnections for: %s" % ui_name)
#endregion


# combines deregistry, queue_free
func close_ui(ui_name: String) -> void:
	if not _ui_registry.has(ui_name):
		push_warning("Tried to close UI that isn’t registered: %s" % ui_name)
		return

	var node = _ui_registry[ui_name]

	if is_instance_valid(node):
		node.queue_free()

	deregister_ui(ui_name)

	print("🧹 Closed and deregistered UI: %s" % ui_name)


# MAP LIST SCREEN -> spawn from Map Editor Screen
func show_map_list_screen(is_open_context: bool = true):
	if _ui_registry.has("MapListScreen"):
		print("🟡 Map List Screen already exists -> If this runs, fix the flow.")
		return

	var main_scene = get_tree().root.get_node("MainScene")
	var map_list_screen = main_scene.spawn_popup(main_scene.map_list_screen_scene)

	map_list_screen.connect("map_list_closed", Callable(self, "_on_map_list_screen_closed"))
	map_list_screen.set_context(is_open_context)

	print("🟢 Map List Screen instantiated with context: %s" % ("Open" if is_open_context else "Save"))

	if not is_open_context:
		emit_signal("save_map_requested")


#region UI current_map refresh calls
func _on_map_list_screen_closed():
	print("📢 MapListScreen closed, refreshing editor screen if visible")
	if _ui_registry.has("MapEditorScreen"):
		var map_editor = _ui_registry["MapEditorScreen"]
		map_editor._refresh_current_map()


func _on_map_info_screen_closed():
	print("📢 MapInfoScreen closed, refreshing editor screen if visible")
	if _ui_registry.has("MapEditorScreen"):
		var map_editor = _ui_registry["MapEditorScreen"]
		map_editor._refresh_current_map()
#endregion


#region Factories

func get_main_scene() -> Node:
	var main_scene = get_tree().root.get_node_or_null("MainScene")
	if main_scene == null:
		main_scene = load("res://scenes/MainScene.tscn").instantiate()
		main_scene.name = "MainScene"
		get_tree().root.add_child(main_scene)
	return main_scene


# Open Map Info from Map Editor Screen
func _on_open_map_info_screen_requested() -> void:
	print("func _on_open_map_info_screen_requested")

	if _ui_registry.has("MapInfoScreen"):
		print("🟡 Map Info Screen already exists — showing existing.")
		return

	var main_scene = get_tree().root.get_node("MainScene")
	var map_info_screen = main_scene.spawn_popup(main_scene.map_info_screen_scene)

	map_info_screen.connect("map_info_closed", Callable(self, "_on_map_info_screen_closed"))


func open_map_editor_screen():
	var main_scene = get_tree().root.get_node("MainScene")
	main_scene.replace_screen(main_scene.map_editor_screen_scene)

	spawn_taskbar(main_scene)


func open_new_map_flow():
	print("🛠️ UIManager: open_new_map_flow")
	
	MapManager.create_new_map()

	var main_scene = get_main_scene()
	main_scene.replace_screen(main_scene.map_editor_screen_scene)
	spawn_taskbar(main_scene)


# this opens the map list without task bar
func open_open_map_flow_from_title_screen():
	print("🛠️ UIManager: opening open map flow from title screen")

	var main_scene = get_main_scene()
	var map_list_screen = main_scene.replace_screen(main_scene.map_list_screen_scene)
	map_list_screen.is_open_map_context(true)


func spawn_taskbar(main_scene: Node):
	var top_panel = main_scene.get_node("PanelContainerTop")
	var task_bar = load("res://scenes/TaskBar.tscn").instantiate()
	top_panel.add_child(task_bar)

#endregion


#region Taskbar Spawning Context

## Spawn Map list screen in Open Map Context
#func open_open_map_flow():
	#print("🛠️ UIManager: opening open map flow")
	#
	#var main_scene = load("res://scenes/MainScene.tscn").instantiate()
	#get_tree().root.add_child(main_scene)
	#
	#spawn_taskbar(main_scene)
	#
	#var map_list_screen = load("res://scenes/MapListScreen.tscn").instantiate()
	#main_scene.get_node("PanelContainerBottom").add_child(map_list_screen)
	#map_list_screen.is_open_map_context(true)
