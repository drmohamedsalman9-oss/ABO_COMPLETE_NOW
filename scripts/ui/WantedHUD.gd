extends CanvasLayer
## مؤشر المطلوبية — أسود وذهبي

@onready var stars_label: Label = $Root/Stars
@onready var chase_label: Label = $Root/ChaseAlert
@onready var escape_label: Label = $Root/EscapeBar
@onready var event_label: Label = $Root/Event
@onready var state_label: Label = $Root/State

var police: Node = null
var _event_timer: float = 0.0

func _ready() -> void:
	layer = 14
	chase_label.visible = false
	stars_label.text = ""
	escape_label.text = ""
	event_label.text = ""
	state_label.text = ""
	set_process(true)

func setup(mgr: Node) -> void:
	police = mgr
	if police == null:
		return
	police.wanted_changed.connect(_on_wanted)
	police.chase_started.connect(func():
		chase_label.visible = true
		chase_label.text = "⚠ مطاردة"
	)
	police.chase_ended.connect(func():
		chase_label.visible = false
		escape_label.text = ""
		state_label.text = ""
	)
	police.player_arrested.connect(func():
		chase_label.text = "تم القبض"
		chase_label.visible = true
	)
	if police.has_signal("chase_event"):
		police.chase_event.connect(_on_event)

func _process(delta: float) -> void:
	if police == null:
		return
	var wl := int(police.wanted_level) if "wanted_level" in police else 0
	if wl > 0:
		var ep := float(police.escape_progress) if "escape_progress" in police else 0.0
		var filled := int(ep / 10.0)
		var bar := ""
		for i in range(10):
			bar += "█" if i < filled else "░"
		escape_label.text = "اختباء [" + bar + "]"
		escape_label.visible = true
		if police.get("_searching"):
			state_label.text = "الشرطة تبحث..."
		elif police.get("_in_chase"):
			state_label.text = "تحت المراقبة"
		else:
			state_label.text = ""
	else:
		escape_label.visible = false
		state_label.text = ""
	if _event_timer > 0.0:
		_event_timer -= delta
		if _event_timer <= 0.0:
			event_label.text = ""

func _on_wanted(level: int) -> void:
	if level <= 0:
		stars_label.text = ""
		return
	var s := ""
	for i in range(level):
		s += "★"
	for i in range(5 - level):
		s += "☆"
	stars_label.text = s

func _on_event(text: String) -> void:
	event_label.text = text
	_event_timer = 3.0
