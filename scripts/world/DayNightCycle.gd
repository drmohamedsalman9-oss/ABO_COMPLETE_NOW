extends Node
## نظام النهار والليل — تغيير إضاءة حقيقي أثناء اللعب
## الجزء 2 — مملكة الصحاب | Mamlaket El Sohab

signal time_changed(hour: float, is_night: bool)
signal period_changed(period_name: String)

## مدة يوم كامل بالثواني الحقيقية (قابلة للتعديل من الإعدادات لاحقاً)
@export var day_length_seconds: float = 480.0  # 8 دقائق = يوم كامل
@export var start_hour: float = 10.0           # يبدأ الساعة 10 صباحاً

var current_hour: float = 10.0  # 0–24
var time_paused: bool = false
var is_night: bool = false

@onready var sun: DirectionalLight3D = null
@onready var world_env: WorldEnvironment = null
@onready var street_lights_root: Node3D = null

var _env: Environment = null
var _last_period: String = ""

# ألوان السماء حسب الوقت
const COLOR_DAWN := Color(0.85, 0.55, 0.35)
const COLOR_DAY := Color(0.55, 0.70, 0.90)
const COLOR_DUSK := Color(0.90, 0.45, 0.25)
const COLOR_NIGHT := Color(0.05, 0.07, 0.15)

func _ready() -> void:
	current_hour = start_hour
	call_deferred("_find_nodes")

func _find_nodes() -> void:
	var world := get_tree().current_scene
	if world == null:
		return
	sun = world.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	world_env = world.get_node_or_null("WorldEnvironment") as WorldEnvironment
	street_lights_root = world.get_node_or_null("StreetLights") as Node3D
	if world_env and world_env.environment:
		_env = world_env.environment
	_apply_time(true)
	print("[DayNight] جاهز — الساعة الحالية: %.1f" % current_hour)

func _process(delta: float) -> void:
	if time_paused:
		return
	# تقدم الوقت
	var hours_per_second := 24.0 / day_length_seconds
	current_hour = fmod(current_hour + hours_per_second * delta, 24.0)
	_apply_time(false)

func _apply_time(force: bool) -> void:
	var night := current_hour < 6.0 or current_hour >= 19.0
	if night != is_night or force:
		is_night = night
		_set_street_lights(is_night)
	
	var period := _get_period_name()
	if period != _last_period or force:
		_last_period = period
		emit_signal("period_changed", period)
	
	# تدرج الإضاءة
	var sun_energy: float
	var ambient: float
	var sky: Color
	var sun_color: Color
	
	if current_hour >= 5.5 and current_hour < 7.5:
		# فجر
		var t := (current_hour - 5.5) / 2.0
		sun_energy = lerpf(0.05, 1.1, t)
		ambient = lerpf(0.08, 0.45, t)
		sky = COLOR_DAWN.lerp(COLOR_DAY, t)
		sun_color = Color(1.0, 0.7, 0.45).lerp(Color(1, 0.95, 0.85), t)
	elif current_hour >= 7.5 and current_hour < 17.0:
		# نهار
		sun_energy = 1.2
		ambient = 0.45
		sky = COLOR_DAY
		sun_color = Color(1.0, 0.97, 0.9)
	elif current_hour >= 17.0 and current_hour < 19.5:
		# غروب
		var t := (current_hour - 17.0) / 2.5
		sun_energy = lerpf(1.1, 0.05, t)
		ambient = lerpf(0.45, 0.08, t)
		sky = COLOR_DAY.lerp(COLOR_DUSK, t).lerp(COLOR_NIGHT, maxf(0, t - 0.5) * 2.0)
		sun_color = Color(1, 0.95, 0.85).lerp(Color(1.0, 0.4, 0.2), t)
	else:
		# ليل
		sun_energy = 0.02
		ambient = 0.06
		sky = COLOR_NIGHT
		sun_color = Color(0.4, 0.45, 0.7)
	
	if sun:
		sun.light_energy = sun_energy
		sun.light_color = sun_color
		# دوران الشمس حسب الساعة
		var angle := (current_hour / 24.0) * TAU - PI * 0.5
		sun.rotation.x = -angle * 0.6 - 0.3
		sun.rotation.y = -0.6
	
	if _env:
		_env.background_color = sky
		_env.ambient_light_color = sky.lightened(0.15)
		_env.ambient_light_energy = ambient
	
	emit_signal("time_changed", current_hour, is_night)

func _set_street_lights(on: bool) -> void:
	if street_lights_root == null:
		return
	for child in street_lights_root.get_children():
		var light := child.get_node_or_null("OmniLight3D") as OmniLight3D
		if light:
			light.visible = on
		var bulb := child.get_node_or_null("Bulb") as MeshInstance3D
		if bulb and bulb.material_override:
			var mat := bulb.material_override as StandardMaterial3D
			if mat:
				mat.emission_enabled = on
				mat.emission_energy_multiplier = 2.5 if on else 0.0

func _get_period_name() -> String:
	if current_hour >= 5.5 and current_hour < 7.5:
		return "فجر"
	elif current_hour >= 7.5 and current_hour < 17.0:
		return "نهار"
	elif current_hour >= 17.0 and current_hour < 19.5:
		return "غروب"
	else:
		return "ليل"

func get_time_string() -> String:
	var h := int(current_hour)
	var m := int((current_hour - h) * 60.0)
	return "%02d:%02d" % [h, m]

func set_hour(hour: float) -> void:
	current_hour = fmod(hour, 24.0)
	_apply_time(true)

func toggle_pause() -> void:
	time_paused = not time_paused
