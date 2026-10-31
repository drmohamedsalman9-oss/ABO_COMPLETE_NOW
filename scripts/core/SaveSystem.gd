extends Node
## حفظ ذري + نسخة احتياطية + حفظ دوري + عند الخروج للخلفية

signal save_completed(success: bool)
signal load_completed(success: bool, data: Dictionary)
signal save_error(message: String)

const SAVE_PATH := "user://save_slot_0.json"
const BACKUP_PATH := "user://save_slot_0.bak.json"
const TEMP_PATH := "user://save_slot_0.tmp.json"
const SAVE_VERSION := 4
const AUTOSAVE_INTERVAL := 45.0

var current_save: Dictionary = {}
var _autosave_timer: float = 0.0
var _saving: bool = false
var _player_ref: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[SaveSystem] v", SAVE_VERSION)

func _process(delta: float) -> void:
	if GameManager and GameManager.current_state != GameManager.GameState.PLAYING:
		return
	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		_autosave_timer = 0.0
		request_quick_save()

func _notification(what: int) -> void:
	# إغلاق النافذة / الخروج
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		request_quick_save()
	# فقدان التركيز / خلفية (أندرويد غالباً)
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		request_quick_save()
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		request_quick_save()

func create_default_save() -> Dictionary:
	var hp := Vector3(-6.0, 1.3, 20.0)
	if GameManager:
		hp = GameManager.get_home_global_position()
	return {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"player": {
			"position": {"x": hp.x, "y": hp.y, "z": hp.z},
			"yaw": 0.0,
			"money": 500,
			"health": 100.0,
			"inside_home": true
		},
		"quests": {},
		"economy": {},
		"weapons": {},
		"settings_ref": true,
		"achievements": {},
		"garage": [],
		"appearance": "ملكي",
		"quests_progress": {},
		"vehicle": {
			"is_driving": false,
			"position": {"x": 0.0, "y": 0.0, "z": 0.0}
		}
	}

func bind_player(p: Node) -> void:
	_player_ref = p

func request_quick_save() -> void:
	if _saving:
		return
	var data := capture_full_state(_player_ref)
	save_game(data)

func capture_full_state(player: Node = null) -> Dictionary:
	var data := current_save.duplicate(true) if not current_save.is_empty() else create_default_save()
	data["version"] = SAVE_VERSION
	data["timestamp"] = Time.get_unix_time_from_system()
	var p: Node = player if player else _player_ref
	if p and is_instance_valid(p) and p is Node3D:
		var n3: Node3D = p
		# لو اللاعب ابن مركبة — احفظ موضع آمن بجانب المركبة
		var parent := n3.get_parent()
		var pos := n3.global_position
		var driving := false
		if parent and (parent is VehicleBody3D or parent.has_method("exit_vehicle") or "is_occupied" in parent):
			driving = true
			pos = parent.global_position + parent.global_transform.basis.x * 2.5 + Vector3(0, 0.8, 0)
			data["vehicle"] = {
				"is_driving": true,
				"position": {"x": parent.global_position.x, "y": parent.global_position.y, "z": parent.global_position.z}
			}
		else:
			data["vehicle"] = {"is_driving": false, "position": {"x": 0.0, "y": 0.0, "z": 0.0}}
		data["player"]["position"] = {"x": pos.x, "y": pos.y, "z": pos.z}
		data["player"]["yaw"] = n3.rotation.y
		data["player"]["inside_home"] = false
	if EconomyManager:
		data["player"]["money"] = EconomyManager.get_balance() if EconomyManager.has_method("get_balance") else EconomyManager.balance
		if "owned_vehicles" in EconomyManager:
			data["garage"] = EconomyManager.owned_vehicles.duplicate()
		if EconomyManager.has_method("to_save"):
			data["economy"] = EconomyManager.to_save()
	if QuestManager and "progress" in QuestManager:
		data["quests_progress"] = QuestManager.progress.duplicate(true)
		if "active_quest_id" in QuestManager:
			data["active_quest_id"] = QuestManager.active_quest_id
	if AchievementSystem and AchievementSystem.has_method("to_save"):
		data["achievements"] = AchievementSystem.to_save()
	# صحة
	if p and is_instance_valid(p):
		var vitals = p.get_node_or_null("PlayerVitals")
		if vitals and "health" in vitals:
			data["player"]["health"] = vitals.health
	return data

func apply_full_state(data: Dictionary, player: Node = null) -> void:
	if data.is_empty():
		return
	current_save = data
	if EconomyManager:
		var money := int(data.get("player", {}).get("money", 500))
		if EconomyManager.has_method("set_balance"):
			EconomyManager.set_balance(money)
		elif "balance" in EconomyManager:
			EconomyManager.balance = money
			if EconomyManager.has_signal("balance_changed"):
				EconomyManager.emit_signal("balance_changed", money)
		if data.has("garage") and "owned_vehicles" in EconomyManager:
			EconomyManager.owned_vehicles = data["garage"]
		if data.has("economy") and EconomyManager.has_method("from_save"):
			EconomyManager.from_save(data["economy"])
	if QuestManager and data.has("quests_progress") and "progress" in QuestManager:
		QuestManager.progress = data["quests_progress"]
		if data.has("active_quest_id") and "active_quest_id" in QuestManager:
			QuestManager.active_quest_id = str(data["active_quest_id"])
	if AchievementSystem and data.has("achievements") and AchievementSystem.has_method("from_save"):
		AchievementSystem.from_save(data["achievements"])
	var p: Node = player if player else _player_ref
	if p and is_instance_valid(p) and p is Node3D and data.get("player", {}).has("position"):
		var pos: Dictionary = data["player"]["position"]
		var y := float(pos.get("y", 1.5))
		# حماية من تحت الأرض
		if y < 0.5:
			y = 1.3
		(p as Node3D).global_position = Vector3(float(pos.get("x", 0)), y, float(pos.get("z", 25)))
		if data["player"].has("yaw"):
			(p as Node3D).rotation.y = float(data["player"]["yaw"])
		var vitals = p.get_node_or_null("PlayerVitals")
		if vitals and data["player"].has("health") and "health" in vitals:
			vitals.health = float(data["player"]["health"])

func save_game(data: Dictionary = {}) -> bool:
	if _saving:
		return false
	_saving = true
	if data.is_empty():
		data = current_save if not current_save.is_empty() else create_default_save()
	data["version"] = SAVE_VERSION
	data["timestamp"] = Time.get_unix_time_from_system()
	# نسخ احتياطي من الملف الحالي قبل الكتابة
	if FileAccess.file_exists(SAVE_PATH):
		var old := FileAccess.get_file_as_string(SAVE_PATH)
		var bak := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
		if bak:
			bak.store_string(old)
			bak.close()
	# كتابة ذرية: tmp ثم استبدال
	var tmp := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if tmp == null:
		_saving = false
		emit_signal("save_error", "تعذّر فتح ملف مؤقت")
		emit_signal("save_completed", false)
		return false
	tmp.store_string(JSON.stringify(data, "\t"))
	tmp.close()
	# استبدال
	var dir := DirAccess.open("user://")
	if dir:
		if FileAccess.file_exists(SAVE_PATH):
			dir.remove(SAVE_PATH.get_file())
		dir.rename(TEMP_PATH.get_file(), SAVE_PATH.get_file())
	else:
		# fallback
		var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(data, "\t"))
			f.close()
	current_save = data
	_saving = false
	emit_signal("save_completed", true)
	print("[SaveSystem] حفظ ذري v", SAVE_VERSION)
	return true

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		if FileAccess.file_exists(BACKUP_PATH):
			print("[SaveSystem] استعادة من النسخة الاحتياطية")
			return _load_from(BACKUP_PATH)
		current_save = create_default_save()
		emit_signal("load_completed", true, current_save)
		return current_save
	return _load_from(SAVE_PATH)

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(BACKUP_PATH)

func _load_from(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		emit_signal("save_error", "تعذّر قراءة الحفظ")
		current_save = create_default_save()
		emit_signal("load_completed", false, current_save)
		return current_save
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		emit_signal("save_error", "ملف حفظ تالف")
		if path != BACKUP_PATH and FileAccess.file_exists(BACKUP_PATH):
			return _load_from(BACKUP_PATH)
		# لا تمسح الحفظ التالف — احتفظ بالملف
		current_save = create_default_save()
		emit_signal("load_completed", false, current_save)
		return current_save
	var data: Dictionary = json.data
	data = _migrate(data)
	if not _validate(data):
		emit_signal("save_error", "بيانات غير صالحة — استخدام افتراضي دون مسح الملف")
		if path != BACKUP_PATH and FileAccess.file_exists(BACKUP_PATH):
			return _load_from(BACKUP_PATH)
		current_save = create_default_save()
		emit_signal("load_completed", false, current_save)
		return current_save
	current_save = data
	emit_signal("load_completed", true, current_save)
	print("[SaveSystem] تحميل v", data.get("version", "?"))
	return current_save

func _migrate(data: Dictionary) -> Dictionary:
	var v := int(data.get("version", 1))
	if v < 3:
		if not data.has("achievements"):
			data["achievements"] = {}
	if v < 4:
		if not data.get("player", {}).has("yaw"):
			data["player"]["yaw"] = 0.0
		if not data.has("vehicle"):
			data["vehicle"] = {"is_driving": false, "position": {"x": 0, "y": 0, "z": 0}}
	data["version"] = SAVE_VERSION
	return data

func _validate(data: Dictionary) -> bool:
	if not data.has("player"):
		return false
	if not data["player"].has("position"):
		return false
	return true
