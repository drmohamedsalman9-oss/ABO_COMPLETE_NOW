extends CanvasLayer
## خريطة كاملة تفاعلية + تحديد وجهة
## الجزء 11

signal destination_set(pos: Vector3)

@onready var panel: Panel = $Panel
@onready var map_draw: Control = $Panel/MapDraw
@onready var btn_close: Button = $Panel/BtnClose
@onready var btn_open: Button = $OpenBtn
@onready var info: Label = $Panel/Info
@onready var btn_clear: Button = $Panel/BtnClear

var player: Node3D = null
var markers: Dictionary = {}
var destination: Variant = null  # Vector3 or null
var map_range: float = 4000.0

func _ready() -> void:
	layer = 20
	panel.visible = false
	btn_close.pressed.connect(func(): panel.visible = false)
	btn_open.pressed.connect(toggle)
	btn_clear.pressed.connect(func():
		destination = null
		info.text = "لا وجهة"
		if map_draw.has_method("queue_redraw"):
			map_draw.queue_redraw()
	)
	map_draw.gui_input.connect(_on_map_input)
	map_draw.set_script(load("res://scripts/ui/FullMapDraw.gd"))
	set_process(true)

func setup(p_player: Node3D, p_markers: Dictionary) -> void:
	player = p_player
	markers = p_markers.duplicate(true)
	if map_draw.has_method("setup"):
		map_draw.setup(player, markers, map_range)

func toggle() -> void:
	panel.visible = not panel.visible
	if panel.visible and map_draw.has_method("setup"):
		map_draw.setup(player, markers, map_range)

func _process(_d: float) -> void:
	if panel.visible and map_draw:
		map_draw.queue_redraw()
	# بوصلة وجهة على الشاشة الصغيرة تُحدَّث عبر DestinationCompass

func _on_map_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local: Vector2 = event.position
		var world := _map_to_world(local)
		# أقرب نقطة اهتمام
		var best_key := ""
		var best_d := 80.0
		for k in markers:
			var pos: Vector3 = markers[k].get("pos", Vector3.ZERO)
			var d := Vector2(pos.x, pos.z).distance_to(Vector2(world.x, world.z))
			if d < best_d:
				best_d = d
				best_key = k
		if best_key != "":
			destination = markers[best_key]["pos"]
			info.text = "وجهة: " + str(markers[best_key].get("label", best_key))
			emit_signal("destination_set", destination)
		else:
			destination = world
			info.text = "وجهة مخصصة"
			emit_signal("destination_set", destination)
		map_draw.destination = destination
		map_draw.queue_redraw()

func _map_to_world(local: Vector2) -> Vector3:
	var s: Vector2 = map_draw.size
	var nx := (local.x / s.x) - 0.5
	var nz := (local.y / s.y) - 0.5
	return Vector3(nx * map_range, 0.0, nz * map_range)

func get_destination():
	return destination
