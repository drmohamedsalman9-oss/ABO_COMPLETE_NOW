extends CanvasLayer
## مرآب من القائمة: عرض المخزّن · طلاء · إغلاق

signal closed

func _ready() -> void:
	layer = 55
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -160
	panel.offset_top = -180
	panel.offset_right = 160
	panel.offset_bottom = 180
	add_child(panel)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 12
	v.offset_top = 12
	v.offset_right = -12
	v.offset_bottom = -12
	panel.add_child(v)
	var title := Label.new()
	title.text = "المرآب"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	if GarageSystem:
		GarageSystem.refresh_from_economy()
		for id in GarageSystem.list_stored():
			var l := Label.new()
			l.text = "• " + str(id)
			v.add_child(l)
		for col_name in ["black", "gold", "white", "red"]:
			var b := Button.new()
			b.text = "طلاء: " + col_name
			var cn := col_name
			b.pressed.connect(func():
				GarageSystem.set_paint(cn)
			)
			v.add_child(b)
	var close := Button.new()
	close.text = "إغلاق"
	close.pressed.connect(func():
		emit_signal("closed")
		queue_free()
	)
	v.add_child(close)
