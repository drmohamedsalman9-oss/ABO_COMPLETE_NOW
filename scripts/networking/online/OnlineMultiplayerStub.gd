extends Node
## بنية اللعب الجماعي عبر الإنترنت
## الجزء 1: هيكل فقط — لا تنفيذ كامل
## مملكة الصحاب | Mamlaket El Sohab
##
## سيتم لاحقاً استخدام:
## - خادم مصادقة (حسابات)
## - غرف ومطابقة (Matchmaking)
## - مزامنة حالة اللاعبين والمركبات
## - ENet / WebRTC / أو حل مخصص حسب الحاجة

class_name OnlineMultiplayerStub

signal authenticated(user_id: String)
signal room_joined(room_id: String)
signal room_left
signal player_synced(player_data: Dictionary)

var is_authenticated: bool = false
var current_room_id: String = ""
var user_id: String = ""

func login(_username: String, _password: String) -> void:
	push_warning("[OnlineMultiplayer] login — البنية جاهزة، التنفيذ في أجزاء قادمة")

func create_room(_max_players: int = 8) -> void:
	push_warning("[OnlineMultiplayer] create_room — البنية جاهزة")

func join_room(_room_id: String) -> void:
	push_warning("[OnlineMultiplayer] join_room — البنية جاهزة")

func leave_room() -> void:
	current_room_id = ""
	print("[OnlineMultiplayer] left room (stub)")

func get_status() -> String:
	return "غير متصل (الجزء 1 — بنية فقط)"
