extends CanvasLayer

func _ready() -> void:
	layer = 55
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -140
	panel.offset_top = -160
	panel.offset_right = 140
	panel.offset_bottom = 160
	add_child(panel)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 12
	v.offset_top = 12
	v.offset_right = -12
	v.offset_bottom = -12
	panel.add_child(v)
	var title := Label.new()
	title.text = "المظهر"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var player = get_tree().get_first_node_in_group("player")
	var app = player.find_child("PlayerAppearance", true, false) if player else null
	var visual = player.find_child("PlayerVisual", true, false) if player else null
	if app == null and player:
		var S = load("res://scripts/player/PlayerAppearance.gd")
		if S:
			app = S.new()
			app.name = "PlayerAppearance"
			player.add_child(app)
	if app and visual:
		for preset in app.presets.keys():
			var b := Button.new()
			b.text = str(preset)
			var pn := str(preset)
			b.pressed.connect(func():
				app.apply_preset(pn, visual)
			)
			v.add_child(b)
	if app and visual:
		var crown_b := Button.new()
		crown_b.text = "تاج"
		crown_b.pressed.connect(func(): app.add_simple_accessory(visual, "crown"))
		v.add_child(crown_b)
		var glasses_b := Button.new()
		glasses_b.text = "نظارة"
		glasses_b.pressed.connect(func(): app.add_simple_accessory(visual, "glasses"))
		v.add_child(glasses_b)
	var close := Button.new()
	close.text = "إغلاق"
	close.pressed.connect(queue_free)
	v.add_child(close)
