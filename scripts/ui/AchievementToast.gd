extends CanvasLayer

func _ready() -> void:
	layer = 70
	if AchievementSystem and AchievementSystem.has_signal("unlocked"):
		AchievementSystem.unlocked.connect(_on_unlock)

func _on_unlock(id: String, title: String) -> void:
	var l := Label.new()
	l.text = "إنجاز: " + title
	l.add_theme_color_override("font_color", Color(0.95, 0.8, 0.2))
	l.add_theme_font_size_override("font_size", 18)
	l.set_anchors_preset(Control.PRESET_CENTER_TOP)
	l.offset_top = 100
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(l)
	var t := get_tree().create_timer(3.0)
	t.timeout.connect(l.queue_free)
