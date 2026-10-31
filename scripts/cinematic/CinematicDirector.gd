extends CanvasLayer
## مشاهد سينمائية — كاميرا + شريط أسود + حوار + تجميد التحكم
## أبو كردوم | الملك الأخير

signal cinematic_finished(id: String)

@onready var top_bar: ColorRect = $Bars/Top
@onready var bottom_bar: ColorRect = $Bars/Bottom
@onready var subtitle: Label = $Subtitle
@onready var skip_btn: Button = $SkipBtn

var is_playing: bool = false
var _id: String = ""
var _lines: Array = []
var _line_i: int = 0
var _cam: Camera3D = null
var _orig_cam: Camera3D = null
var _player: Node = null
var _waypoints: Array = []  # Vector3 look targets
var _timer: float = 0.0
var _line_duration: float = 3.2
var _hold: float = 0.0

func _ready() -> void:
	layer = 30
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if skip_btn:
		skip_btn.pressed.connect(skip)
	set_process(false)

func play(cinematic_id: String, lines: Array, camera_points: Array = [], player: Node = null) -> void:
	if is_playing:
		return
	_id = cinematic_id
	_lines = lines
	_line_i = 0
	_waypoints = camera_points
	_player = player
	is_playing = true
	visible = true
	set_process(true)
	# تجميد اللاعب
	if _player and _player.has_method("set_control_enabled"):
		_player.set_control_enabled(false)
	_setup_cine_camera()
	_show_line()
	# شريط سينمائي
	if top_bar:
		top_bar.offset_bottom = 0
	_animate_bars(true)

func _setup_cine_camera() -> void:
	_orig_cam = get_viewport().get_camera_3d()
	_cam = Camera3D.new()
	_cam.name = "CineCam"
	_cam.current = true
	_cam.fov = 55.0
	var scene := get_tree().current_scene
	if scene:
		scene.add_child(_cam)
	if _waypoints.size() > 0:
		var p: Vector3 = _waypoints[0]
		_cam.global_position = p + Vector3(8, 6, 8)
		_cam.look_at(p, Vector3.UP)
	elif _player:
		_cam.global_position = _player.global_position + Vector3(6, 4, 6)
		_cam.look_at(_player.global_position + Vector3(0, 1.5, 0), Vector3.UP)

func _animate_bars(show_bars: bool) -> void:
	if top_bar == null:
		return
	# ارتفاع الشريط
	var h := 70.0 if show_bars else 0.0
	top_bar.offset_bottom = h
	bottom_bar.offset_top = -h

func _show_line() -> void:
	if _line_i >= _lines.size():
		end()
		return
	var line = _lines[_line_i]
	var text := ""
	if typeof(line) == TYPE_DICTIONARY:
		var sp := str(line.get("speaker", ""))
		var body := str(line.get("text", ""))
		text = ("%s:\n%s" % [sp, body]) if sp != "" else body
	else:
		text = str(line)
	subtitle.text = text
	_hold = _line_duration
	# حركة كاميرا بسيطة بين النقاط
	if _cam and _waypoints.size() > 0:
		var wi := mini(_line_i, _waypoints.size() - 1)
		var target: Vector3 = _waypoints[wi]
		_cam.global_position = target + Vector3(6.0 + wi * 0.5, 4.5, 7.0)
		_cam.look_at(target + Vector3(0, 1.2, 0), Vector3.UP)

func _process(delta: float) -> void:
	if not is_playing:
		return
	_hold -= delta
	if _hold <= 0.0:
		_line_i += 1
		_show_line()
	# دوران خفيف للكاميرا
	if _cam:
		_cam.rotate_y(delta * 0.08)

func skip() -> void:
	end()

func end() -> void:
	if not is_playing:
		return
	is_playing = false
	set_process(false)
	visible = false
	if _cam and is_instance_valid(_cam):
		_cam.queue_free()
	_cam = null
	if _orig_cam and is_instance_valid(_orig_cam):
		_orig_cam.current = true
	if _player and _player.has_method("set_control_enabled"):
		_player.set_control_enabled(true)
	var finished_id := _id
	_id = ""
	emit_signal("cinematic_finished", finished_id)
