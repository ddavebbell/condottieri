extends TextureRect

const GRID_SIZE = 48
const GRID_WIDTH = 14
const GRID_HEIGHT = 14

func _get_drag_data(at_position: Vector2) -> Dictionary:
	
	# Create drag preview
	var preview = TextureRect.new()
	preview.texture = texture
	preview.size = Vector2(48, 48)
	preview.scale = Vector2(0.525, 0.525)
	preview.modulate = Color(1, 1, 1, 0.75)
	set_drag_preview(preview)
	
	GlobalSignals.emit_signal("preview_position_updated", preview, at_position)
	return {"name": name, "texture": texture, "preview": preview}
