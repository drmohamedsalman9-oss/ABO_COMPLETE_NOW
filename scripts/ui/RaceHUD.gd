extends CanvasLayer
## واجهة السباق: نقطة · زمن · إعادة

var race: Node = null
var _label: Label
var _time_l: Label
var _msg: Label
var _btn_retry: Button
var _running := false
var _t0 := 0.0

func _ready() -> void:
	layer = 35
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.offset_bottom = 72
	panel.offset_left = 20
	panel.offset_right = -20
	panel.offset_top = 8
	add_child(panel)
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 12
	h.offset_right = -12
	panel.add_child(h)
	_label = Label.new()
	_label.text = "سباق"
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(_label)
	_time_l = Label.new()
	_time_l.text = "0.0 ث"
	h.add_child(_time_l)
	_btn_retry = Button.new()
	_btn_retry.text = "إعادة"
	_btn_retry.visible = false
	_btn_retry.pressed.connect(_retry)
	h.add_child(_btn_retry)
	_msg = Label.new()
	_msg.position = Vector2(40, 90)
	_msg.add_theme_color_override("font_color", Color(0.95, 0.8, 0.2))
	add_child(_msg)
	visible = false

func bind(r: Node) -> void:
	race = r
	if race:
		if race.has_signal("race_started"):
			race.race_started.connect(_on_start)
		if race.has_signal("checkpoint"):
			race.checkpoint.connect(_on_cp)
		if race.has_signal("race_finished"):
			race.race_finished.connect(_on_finish)

func _on_start() -> void:
	visible = true
	_running = true
	_t0 = Time.get_ticks_msec() / 1000.0
	_btn_retry.visible = false
	_msg.text = "انطلق!"
	_label.text = "نقطة 1"

func _on_cp(i: int) -> void:
	_label.text = "نقطة %d" % (i + 2)
	_msg.text = "نقطة تفتيش!"

func _on_finish(t: float, reward: int) -> void:
	_running = false
	_time_l.text = "%.1f ث" % t
	_msg.text = "انتهى! مكافأة %d" % reward
	_btn_retry.visible = true

func _process(_d: float) -> void:
	if _running:
		var t := Time.get_ticks_msec() / 1000.0 - _t0
		_time_l.text = "%.1f ث" % t

func _retry() -> void:
	var p = get_tree().get_first_node_in_group("player")
	if race and race.has_method("start_race") and p:
		race.start_race(p)
