extends TextureRect

func _get_drag_data(_pos):
	var data = {}
	data["texture"] = texture  # Pass the tile texture for dropping
	set_drag_preview(make_drag_preview())
	return data

func make_drag_preview():
	var preview = TextureRect.new()
	preview.texture = texture
	preview.expand = true
	preview.size = Vector2(48, 48)
	return preview
