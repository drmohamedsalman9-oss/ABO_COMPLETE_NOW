extends CanvasLayer
## واجهة اللعب الموحدة — صحة / تلميحات / موت

@onready var hp_label: Label = $Root/HP
@onready var tip_label: Label = $Root/Tip
@onready var death_panel: Panel = $Root/DeathPanel
@onready var death_label: Label = $Root/DeathPanel/Lbl

var vitals: Node = null
var _tip_timer: float = 0.0

func _ready() -> void:
	layer = 12
	death_panel.visible = false
	tip_label.text = ""
	set_process(true)

func setup(v: Node) -> void:
	vitals = v
	if vitals:
		if vitals.has_signal("health_changed"):
			vitals.health_changed.connect(_on_hp)
		if vitals.has_signal("died"):
			vitals.died.connect(func():
				death_panel.visible = true
				death_label.text = "لقد سقطت...\nستعود عند الجراج"
			)
		if vitals.has_signal("respawned"):
			vitals.respawned.connect(func():
				death_panel.visible = false
				show_tip("عدت للجراج. انتبه للشرطة.")
			)
		_on_hp(vitals.health, vitals.max_health)
	show_tip("WASD حركة · E تفاعل · P مطلوب · Esc إيقاف")

func _process(delta: float) -> void:
	if _tip_timer > 0.0:
		_tip_timer -= delta
		if _tip_timer <= 0.0:
			tip_label.text = ""

func _on_hp(hp: float, mx: float) -> void:
	var n := int((hp / mx) * 10.0)
	var bar := ""
	for i in range(10):
		bar += "♥" if i < n else "♡"
	hp_label.text = bar + " %d" % int(hp)
	if hp < 30.0:
		hp_label.modulate = Color(1, 0.3, 0.3)
	else:
		hp_label.modulate = Color(0.95, 0.35, 0.4)

func show_tip(t: String) -> void:
	tip_label.text = t
	_tip_timer = 5.0
