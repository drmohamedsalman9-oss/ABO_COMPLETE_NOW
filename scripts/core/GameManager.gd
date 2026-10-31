extends Node
## GameManager — مدير اللعبة + اتجاه أفقي + أعلام الحفظ

signal game_state_changed(new_state: String)
signal player_ready

enum GameState {
	SPLASH,
	MAIN_MENU,
	LOADING,
	PLAYING,
	PAUSED,
	MULTIPLAYER_LOBBY
}

var current_state: GameState = GameState.SPLASH
var is_mobile: bool = false
var player_name: String = "لاعب"
var game_version: String = "1.0.0-final"

## true = متابعة حفظ | false = لعبة جديدة
var pending_continue: bool = false
var world_ready: bool = false

const SCENE_SPLASH := "res://scenes/ui/SplashScreen.tscn"
const SCENE_MAIN_MENU := "res://scenes/ui/MainMenu.tscn"
const SCENE_WORLD := "res://scenes/world/MainWorld.tscn"

## موقع المنزل الافتراضي (داخل المنزل)
const HOME_POS := Vector3(2.0, 1.3, 2.0)
const HOME_WORLD_ORIGIN := Vector3(-8.0, 0.0, 18.0)

func _ready() -> void:
	is_mobile = OS.has_feature("mobile") or OS.has_feature("android")
	_force_landscape()
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[GameManager] ", game_version, " | mobile=", is_mobile)

func _force_landscape() -> void:
	# 0 = landscape في DisplayServer
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	# نافذة أفقية على سطح المكتب أيضاً
	var w := get_window()
	if w:
		if w.size.x < w.size.y:
			w.size = Vector2i(max(w.size.y, 1280), max(w.size.x, 720))

func change_state(new_state: GameState) -> void:
	current_state = new_state
	emit_signal("game_state_changed", GameState.keys()[new_state])

func go_to_main_menu() -> void:
	world_ready = false
	change_state(GameState.MAIN_MENU)
	get_tree().change_scene_to_file(SCENE_MAIN_MENU)

func start_new_game() -> void:
	pending_continue = false
	if SaveSystem:
		var data := SaveSystem.create_default_save()
		# بداية داخل المنزل
		var hp := HOME_WORLD_ORIGIN + HOME_POS
		data["player"]["position"] = {"x": hp.x, "y": hp.y, "z": hp.z}
		data["player"]["inside_home"] = true
		data["player"]["yaw"] = 0.0
		SaveSystem.current_save = data
		SaveSystem.save_game(data)
	go_to_world()

func continue_game() -> void:
	pending_continue = true
	if SaveSystem:
		SaveSystem.load_game()
	go_to_world()

func go_to_world() -> void:
	change_state(GameState.LOADING)
	world_ready = false
	get_tree().change_scene_to_file(SCENE_WORLD)
	change_state(GameState.PLAYING)

func quit_game() -> void:
	if SaveSystem and current_state == GameState.PLAYING:
		SaveSystem.request_quick_save()
	get_tree().quit()

func get_home_global_position() -> Vector3:
	return HOME_WORLD_ORIGIN + HOME_POS
