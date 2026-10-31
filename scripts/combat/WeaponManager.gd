extends Node
## إدارة الأسلحة والذخيرة — قابل للتوسعة
## الجزء 9 | أبو كردوم

signal weapon_changed(weapon_id: String)
signal ammo_changed(current: int, max_ammo: int)
signal reloading(active: bool)

const DATA_PATH := "res://data/weapons/weapons.json"

var catalog: Dictionary = {}
var inventory: Array[String] = []  # ids
var current_index: int = 0
var ammo: Dictionary = {}  # id -> current rounds in mag
var reserve: Dictionary = {}  # id -> reserve ammo
var is_reloading: bool = false
var _reload_left: float = 0.0

func _ready() -> void:
	_load_catalog()
	# حمولة افتراضية
	var defaults: Array = catalog.get("_defaults", ["fists"])
	for id in defaults:
		add_weapon(str(id))
	if inventory.is_empty():
		add_weapon("fists")
	current_index = 0
	emit_signal("weapon_changed", get_current_id())
	_emit_ammo()

func _load_catalog() -> void:
	if not FileAccess.file_exists(DATA_PATH):
		catalog = {"fists": {"id": "fists", "name": "القبضة", "type": "melee", "damage": 12, "range": 2.2, "cooldown": 0.45, "ammo_max": 0, "requires_ammo": false}}
		catalog["_defaults"] = ["fists"]
		return
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	catalog = data.get("weapons", {})
	catalog["_defaults"] = data.get("default_loadout", ["fists"])

func _process(delta: float) -> void:
	if is_reloading:
		_reload_left -= delta
		if _reload_left <= 0.0:
			_finish_reload()

func add_weapon(weapon_id: String) -> void:
	if not catalog.has(weapon_id):
		return
	if weapon_id in inventory:
		return
	inventory.append(weapon_id)
	var def: Dictionary = catalog[weapon_id]
	var max_a := int(def.get("ammo_max", 0))
	ammo[weapon_id] = max_a
	reserve[weapon_id] = max_a * 3 if max_a > 0 else 0

func get_current_id() -> String:
	if inventory.is_empty():
		return "fists"
	return inventory[clampi(current_index, 0, inventory.size() - 1)]

func get_current_def() -> Dictionary:
	var id := get_current_id()
	return catalog.get(id, {})

func next_weapon() -> void:
	if inventory.size() < 2 or is_reloading:
		return
	current_index = (current_index + 1) % inventory.size()
	emit_signal("weapon_changed", get_current_id())
	_emit_ammo()

func prev_weapon() -> void:
	if inventory.size() < 2 or is_reloading:
		return
	current_index = (current_index - 1 + inventory.size()) % inventory.size()
	emit_signal("weapon_changed", get_current_id())
	_emit_ammo()

func can_fire() -> bool:
	if is_reloading:
		return false
	var def := get_current_def()
	if def.is_empty():
		return false
	if def.get("requires_ammo", false):
		return int(ammo.get(get_current_id(), 0)) > 0
	return true

func consume_ammo() -> bool:
	var id := get_current_id()
	var def := get_current_def()
	if not def.get("requires_ammo", false):
		return true
	var cur := int(ammo.get(id, 0))
	if cur <= 0:
		return false
	ammo[id] = cur - 1
	_emit_ammo()
	return true

func start_reload() -> bool:
	if is_reloading:
		return false
	var id := get_current_id()
	var def := get_current_def()
	if not def.get("requires_ammo", false):
		return false
	var max_a := int(def.get("ammo_max", 0))
	var cur := int(ammo.get(id, 0))
	var res := int(reserve.get(id, 0))
	if cur >= max_a or res <= 0:
		return false
	is_reloading = true
	_reload_left = float(def.get("reload_time", 1.5))
	emit_signal("reloading", true)
	# صوت
	var p := AudioStreamPlayer.new()
	var s: AudioStream = load("res://assets/audio/sfx_reload.wav")
	if s:
		p.stream = s
		add_child(p)
		p.play()
		p.finished.connect(p.queue_free)
	return true

func _finish_reload() -> void:
	is_reloading = false
	var id := get_current_id()
	var def := get_current_def()
	var max_a := int(def.get("ammo_max", 0))
	var cur := int(ammo.get(id, 0))
	var res := int(reserve.get(id, 0))
	var need := max_a - cur
	var take := mini(need, res)
	ammo[id] = cur + take
	reserve[id] = res - take
	emit_signal("reloading", false)
	_emit_ammo()

func _emit_ammo() -> void:
	var id := get_current_id()
	var def := get_current_def()
	if def.get("requires_ammo", false):
		emit_signal("ammo_changed", int(ammo.get(id, 0)), int(def.get("ammo_max", 0)))
	else:
		emit_signal("ammo_changed", -1, 0)

func get_display_ammo() -> String:
	var def := get_current_def()
	if not def.get("requires_ammo", false):
		return "—"
	var id := get_current_id()
	return "%d / %d" % [int(ammo.get(id, 0)), int(reserve.get(id, 0))]

func get_save_data() -> Dictionary:
	return {
		"inventory": inventory,
		"current_index": current_index,
		"ammo": ammo,
		"reserve": reserve
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("inventory"):
		inventory.clear()
		for id in data["inventory"]:
			inventory.append(str(id))
	if data.has("ammo"):
		ammo = data["ammo"]
	if data.has("reserve"):
		reserve = data["reserve"]
	current_index = int(data.get("current_index", 0))
	_emit_ammo()
