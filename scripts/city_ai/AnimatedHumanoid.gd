extends Node3D
## يشغّل أنيميشن من نموذج KayKit إن وُجد AnimationPlayer

var ap: AnimationPlayer = null
var _state := "idle"

func setup_from_child() -> void:
	ap = find_child("AnimationPlayer", true, false) as AnimationPlayer
	play_idle()

func play_idle() -> void:
	_play(["Idle", "idle", "Idle_A", "Idle_B", "T-Pose"])
	_state = "idle"

func play_walk() -> void:
	_play(["Walking_A", "Walking_B", "Walk", "walk", "Running_A", "Run"])
	_state = "walk"

func play_run() -> void:
	_play(["Running_A", "Running_B", "Run", "Sprint"])
	_state = "run"

func _play(names: Array) -> void:
	if ap == null:
		ap = find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap == null:
		return
	for n in names:
		if ap.has_animation(str(n)):
			if ap.current_animation != str(n):
				ap.play(str(n))
			return
	var list := ap.get_animation_list()
	if list.size() > 0 and ap.current_animation == "":
		ap.play(list[0])
