extends Node
## إنجازات بسيطة تُحفظ مع اللعبة

signal unlocked(id: String, title: String)

var defs := {
	"first_drive": {"title": "أول رحلة", "desc": "اركب مركبة"},
	"first_wanted": {"title": "مطلوب", "desc": "احصل على نجمة مطلوبية"},
	"first_buy": {"title": "تاجر", "desc": "اشترِ من المتجر"},
	"quest_done": {"title": "مهمة منجزة", "desc": "أكمل مهمة"},
	"rich": {"title": "ثري", "desc": "امتلك 5000+"},
}
var unlocked_ids: Array[String] = []

func unlock(id: String) -> void:
	if id in unlocked_ids or not defs.has(id):
		return
	unlocked_ids.append(id)
	emit_signal("unlocked", id, str(defs[id]["title"]))
	print("[Achievement] ", defs[id]["title"])

func to_save() -> Dictionary:
	return {"unlocked": unlocked_ids.duplicate()}

func from_save(data: Dictionary) -> void:
	unlocked_ids.clear()
	for x in data.get("unlocked", []):
		unlocked_ids.append(str(x))
