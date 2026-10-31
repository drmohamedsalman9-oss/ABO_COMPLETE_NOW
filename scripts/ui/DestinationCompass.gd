extends CanvasLayer
## مؤشر اتجاه نحو الوجهة

@onready var arrow: Label = $Arrow
@onready var dist_label: Label = $Dist

var player: Node3D = null
var destination = null
var map_ui: Node = null

func _ready() -> void:
	layer = 11
	arrow.text = "▲"
	dist_label.text = ""
	set_process(true)

func setup(p_player: Node3D, p_map_ui: Node = null) -> void:
	player = p_player
	map_ui = p_map_ui
	if map_ui and map_ui.has_signal("destination_set"):
		map_ui.destination_set.connect(func(pos): destination = pos)

func _process(_d: float) -> void:
	if map_ui and map_ui.has_method("get_destination"):
		destination = map_ui.get_destination()
	if player == null or destination == null:
		arrow.visible = false
		dist_label.visible = false
		return
	arrow.visible = true
	dist_label.visible = true
	var to: Vector3 = destination - player.global_position
	to.y = 0.0
	var dist := to.length()
	dist_label.text = "%d م" % int(dist)
	# زاوية بالنسبة لاتجاه اللاعب
	var target_angle := atan2(to.x, to.z)
	var rel := target_angle - player.rotation.y
	arrow.rotation = -rel
