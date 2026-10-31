extends Node
## بطولة سباقات: عدة حلبات + نقاط + جائزة نهائية

signal race_started
signal checkpoint(index: int)
signal race_finished(time_sec: float, reward: int)
signal tournament_finished(total_points: int, reward: int)

var tracks := {
	"center": [Vector3(0,0,25), Vector3(40,0,10), Vector3(40,0,-30), Vector3(-20,0,-40), Vector3(-50,0,10), Vector3(0,0,25)],
	"east": [Vector3(20,0,0), Vector3(50,0,20), Vector3(70,0,-10), Vector3(40,0,-40), Vector3(20,0,0)],
	"north": [Vector3(0,0,-10), Vector3(-30,0,-40), Vector3(30,0,-50), Vector3(0,0,-70), Vector3(0,0,-10)],
	"west": [Vector3(-15,0,5), Vector3(-45,0,25), Vector3(-60,0,-5), Vector3(-30,0,-25), Vector3(-15,0,5)],
	"loop": [Vector3(0,0,20), Vector3(25,0,20), Vector3(25,0,-20), Vector3(-25,0,-20), Vector3(-25,0,20), Vector3(0,0,20)],
}
var track_names: Array = ["center", "east", "north", "west", "loop"]
var track_i := 0
var checkpoints: Array[Vector3] = []
var index := 0
var active := false
var _t0 := 0.0
var reward_base := 400
var player: Node3D = null
var current_track := "center"
var tournament_mode := false
var tournament_points := 0
var tournament_races_done := 0
const TOURNAMENT_LEN := 5

func setup_default_track() -> void:
	current_track = track_names[track_i % track_names.size()]
	checkpoints = []
	for p in tracks[current_track]:
		checkpoints.append(p)

func next_track() -> void:
	track_i = (track_i + 1) % track_names.size()
	setup_default_track()

func start_race(p: Node3D) -> void:
	if checkpoints.is_empty():
		setup_default_track()
	player = p
	index = 0
	active = true
	_t0 = Time.get_ticks_msec() / 1000.0
	emit_signal("race_started")
	print("[Race] ", current_track)

func start_tournament(p: Node3D) -> void:
	tournament_mode = true
	tournament_points = 0
	tournament_races_done = 0
	track_i = 0
	setup_default_track()
	start_race(p)

func _process(_d: float) -> void:
	if not active or player == null or not is_instance_valid(player):
		return
	if player.global_position.distance_to(checkpoints[index]) < 12.0:
		emit_signal("checkpoint", index)
		index += 1
		if index >= checkpoints.size():
			_finish()

func _finish() -> void:
	active = false
	var elapsed := Time.get_ticks_msec() / 1000.0 - _t0
	var reward := reward_base + int(maxf(0.0, 120.0 - elapsed) * 5.0)
	var pts := int(maxf(0.0, 100.0 - elapsed))
	if EconomyManager:
		EconomyManager.add_money(reward, "سباق")
	emit_signal("race_finished", elapsed, reward)
	if tournament_mode:
		tournament_points += pts
		tournament_races_done += 1
		if tournament_races_done >= TOURNAMENT_LEN:
			tournament_mode = false
			var bonus := 800 + tournament_points * 5
			if EconomyManager:
				EconomyManager.add_money(bonus, "بطولة")
			emit_signal("tournament_finished", tournament_points, bonus)
			print("[Race] بطولة انتهت نقاط=", tournament_points, " مكافأة=", bonus)
		else:
			next_track()
			# السباق التالي بعد ثانيتين
			get_tree().create_timer(2.0).timeout.connect(func():
				if player and is_instance_valid(player):
					start_race(player)
			)
	else:
		next_track()
