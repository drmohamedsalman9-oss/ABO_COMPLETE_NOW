extends CanvasLayer
## واجهة المهمات + حوار + إشعارات
## الجزء 7

@onready var panel: Panel = $Root/QuestPanel
@onready var title_l: Label = $Root/QuestPanel/VBox/Title
@onready var desc_l: Label = $Root/QuestPanel/VBox/Desc
@onready var obj_l: Label = $Root/QuestPanel/VBox/Objective
@onready var progress_l: Label = $Root/QuestPanel/VBox/Progress
@onready var money_l: Label = $Root/MoneyLabel
@onready var notify_l: Label = $Root/Notify
@onready var dialogue_panel: Panel = $Root/DialoguePanel
@onready var dlg_speaker: Label = $Root/DialoguePanel/VBox/Speaker
@onready var dlg_text: Label = $Root/DialoguePanel/VBox/Text
@onready var dlg_btn: Button = $Root/DialoguePanel/VBox/BtnNext

var qm: Node = null
var _dlg_lines: Array = []
var _dlg_index: int = 0
var _dlg_quest: String = ""
var _notify_timer: float = 0.0

func _ready() -> void:
	layer = 15
	dlg_btn.pressed.connect(_on_dlg_next)
	dialogue_panel.visible = false
	notify_l.visible = false
	qm = get_node_or_null("/root/QuestManager")
	if qm:
		qm.quest_started.connect(_refresh)
		qm.quest_updated.connect(func(_a, _b): _refresh())
		qm.quest_completed.connect(func(_a, _r): _refresh())
		qm.notification.connect(_on_notify)
		qm.dialogue_requested.connect(_on_dialogue)
	_refresh()

func _process(delta: float) -> void:
	if _notify_timer > 0.0:
		_notify_timer -= delta
		if _notify_timer <= 0.0:
			notify_l.visible = false

func _refresh(_a = null) -> void:
	if qm == null:
		return
	money_l.text = "💰 %d   XP %d" % [qm.money, qm.xp]
	var q: Dictionary = qm.get_active_quest()
	if q.is_empty():
		title_l.text = "لا مهمة نشطة"
		desc_l.text = ""
		obj_l.text = ""
		progress_l.text = ""
		return
	title_l.text = str(q.get("name", ""))
	desc_l.text = str(q.get("description", ""))
	var idx: int = int(q.get("progress", {}).get("objective_index", 0))
	var objs: Array = q.get("objectives", [])
	if idx < objs.size():
		obj_l.text = "➤ " + str(objs[idx].get("text", ""))
	else:
		obj_l.text = "مكتملة"
	progress_l.text = "الهدف %d / %d" % [mini(idx + 1, objs.size()), objs.size()]

func _on_notify(text: String) -> void:
	notify_l.text = text
	notify_l.visible = true
	_notify_timer = 3.5
	_refresh()

func _on_dialogue(lines: Array, quest_id: String) -> void:
	_dlg_lines = lines
	_dlg_index = 0
	_dlg_quest = quest_id
	dialogue_panel.visible = true
	_show_dlg_line()

func _show_dlg_line() -> void:
	if _dlg_index >= _dlg_lines.size():
		dialogue_panel.visible = false
		if qm and qm.has_method("complete_dialogue"):
			qm.complete_dialogue(_dlg_quest)
		return
	var line = _dlg_lines[_dlg_index]
	if typeof(line) == TYPE_DICTIONARY:
		dlg_speaker.text = str(line.get("speaker", ""))
		dlg_text.text = str(line.get("text", ""))
	else:
		dlg_speaker.text = ""
		dlg_text.text = str(line)

func _on_dlg_next() -> void:
	_dlg_index += 1
	_show_dlg_line()
