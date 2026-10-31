extends Node
## يربط مهام survive بالشرطة عبر البحث في الشجرة (PoliceManager ليس Autoload)

var _watching := false
var _need_wanted := false
var _escape_after := 0.0
var _timer := 0.0

func _get_police() -> Node:
	var root := get_tree().root if get_tree() else null
	if root == null:
		return null
	return root.find_child("PoliceManager", true, false)

func start_heat_mission(duration: float = 40.0) -> void:
	_watching = true
	_need_wanted = true
	_escape_after = duration
	_timer = 0.0
	var pm := _get_police()
	if pm and pm.has_method("set_wanted"):
		pm.set_wanted(2)
	elif pm and "wanted_level" in pm:
		pm.wanted_level = maxi(int(pm.wanted_level), 2)

func _process(delta: float) -> void:
	if not _watching:
		return
	_timer += delta
	var wl := 0
	var pm := _get_police()
	if pm and "wanted_level" in pm:
		wl = int(pm.wanted_level)
	if _need_wanted and wl > 0:
		_need_wanted = false
	if _timer >= _escape_after:
		_watching = false
		if QuestManager and QuestManager.has_method("complete_active_if_survive"):
			QuestManager.complete_active_if_survive()
		print("[WantedMission] اكتملت مهمة الهروب")
