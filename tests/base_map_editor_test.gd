extends Node

class_name BaseMapEditorTest

var map_editor_screen
var trigger_manager
var trigger_editor

func _setup_map_editor():
	var scene := preload("res://scenes/MapEditor.tscn")
	map_editor_screen = scene.instantiate()
	add_child(map_editor_screen)


func _setup_trigger_manager():
	var trigger_manager_scene = preload("res://scenes/TriggerManager.tscn")
	trigger_manager = trigger_manager_scene.instantiate()
	add_child(trigger_manager)


func _setup_trigger_editor():
	trigger_editor = preload("res://scenes/TriggerEditorPanel.tscn").instantiate()
	add_child(trigger_editor)
	await get_tree().process_frame


func _cleanup_node_and_children(node: Node):
	if is_instance_valid(node):
		for child in node.get_children():
			if is_instance_valid(child):
				child.queue_free()
		node.queue_free()


func _cleanup_ui_children():
	if not is_inside_tree():
		push_warning("⚠️ base_test is not inside the scene tree. Skipping UI cleanup.")
		return

	var ui_layer = get_tree().get_root().get_node_or_null("MapEditor/UI")
	if ui_layer:
		for child in ui_layer.get_children():
			if is_instance_valid(child):
				child.queue_free()


func _cleanup_common_nodes():
	# Clean up UI layer if it exists
	var ui_layer := get_tree().get_root().get_node_or_null("UI")
	if is_instance_valid(ui_layer):
		for child in ui_layer.get_children():
			if is_instance_valid(child):
				child.queue_free()
		ui_layer.queue_free()

	# Clean up unnamed orphaned nodes (e.g. @Node@####)
	for node in get_tree().get_root().get_children():
		if node.name.begins_with("@") and is_instance_valid(node):
			node.queue_free()




func wait_for_node(path: String, parent: Node, max_attempts: int = 5) -> Node:
	for i in max_attempts:
		if parent.has_node(path):
			return parent.get_node(path)
		await get_tree().process_frame
	return null
