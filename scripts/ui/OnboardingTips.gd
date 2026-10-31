extends CanvasLayer
## تعليمات قصيرة للاعب الجديد

@onready var label: Label = $Label

var _tips := [
	"F5 حفظ سريع · H مرآب · J مظهر · G سباق",

	"حرك بالإبهام الأيسر · انظر باليمين",
	"E للركوب والنزول والتفاعل",
	"🏪 متجر · 🗺️ خريطة · Esc إيقاف",
	"P لتجربة المطلوبية · N لكثافة المدينة",
]
var _i := 0

func _ready() -> void:
	layer = 25
	label.text = _tips[0]
	var t := get_tree().create_timer(4.0)
	t.timeout.connect(_next)

func _next() -> void:
	_i += 1
	if _i >= _tips.size():
		queue_free()
		return
	label.text = _tips[_i]
	get_tree().create_timer(4.0).timeout.connect(_next)
