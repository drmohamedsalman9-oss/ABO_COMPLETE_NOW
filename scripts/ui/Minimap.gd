extends Control
## خريطة مصغّرة + لوحة وقت — الجزء 2
## أبو كردوم | الملك الأخير

@onready var map_panel: Panel = $MapPanel
@onready var map_draw: Control = $MapPanel/MapDraw
@onready var time_label: Label = $TimePanel/TimeLabel
@onready var period_label: Label = $TimePanel/PeriodLabel
@onready var hint_label: Label = $HintLabel

var player: Node3D = null
var city_builder: Node = null
var day_night: Node = null
var markers: Dictionary = {}

const MAP_WORLD_SIZE := 1000000.0  # يطابق CITY_SIZE
const MAP_PIXEL_SIZE := 140.0

func _ready() -> void:
	# إخفاء التلميح بعد ثوانٍ
	await get_tree().create_timer(6.0).timeout
	if hint_label:
		hint_label.visible = false

func setup(p_player: Node3D, p_city: Node, p_daynight: Node) -> void:
	player = p_player
	city_builder = p_city
	day_night = p_daynight
	if city_builder and city_builder.has_method("get_important_points"):
		markers = city_builder.get_important_points()
	if day_night and day_night.has_signal("time_changed"):
		day_night.time_changed.connect(_on_time_changed)
	map_draw.queue_redraw()

func _on_time_changed(hour: float, _is_night: bool) -> void:
	if time_label and day_night.has_method("get_time_string"):
		time_label.text = day_night.get_time_string()
	if period_label and day_night.has_method("_get_period_name"):
		period_label.text = day_night._get_period_name()

func _process(_delta: float) -> void:
	if map_draw:
		map_draw.queue_redraw()

func _draw_map() -> void:
	pass  # الرسم يتم في MapDraw child
