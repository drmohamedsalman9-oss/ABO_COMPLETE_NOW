extends Node
## المحفظة المركزية والاقتصاد — مصدر واحد للرصيد والملكية
## الجزء 10 | أبو كردوم | الملك الأخير
## محمد ماهر أبو كردوم

signal balance_changed(balance: int)
signal purchase_succeeded(item_id: String, category: String)
signal purchase_failed(reason: String)
signal transaction_logged(entry: Dictionary)

const CATALOG_PATH := "res://data/economy/catalog.json"
const MAX_LOG := 30

var balance: int = 500
var owned_weapons: Array = []  # ids beyond free fists
var owned_vehicles: Array = []  # vehicle type ids
var owned_properties: Array = []  # property ids
var claimed_rewards: Dictionary = {}  # reward_id -> true
var transactions: Array = []  # recent log
var catalog: Dictionary = {}
var _buy_lock: float = 0.0

func _ready() -> void:
	name = "EconomyManager"
	_load_catalog()
	set_process(true)

func _process(delta: float) -> void:
	_buy_lock = maxf(0.0, _buy_lock - delta)

func _load_catalog() -> void:
	if FileAccess.file_exists(CATALOG_PATH):
		var f := FileAccess.open(CATALOG_PATH, FileAccess.READ)
		var data = JSON.parse_string(f.get_as_text())
		if typeof(data) == TYPE_DICTIONARY:
			catalog = data
			balance = int(data.get("starting_balance", 500))
	else:
		catalog = {"weapons": [], "vehicles": [], "properties": []}

func get_balance() -> int:
	return balance

func add_money(amount: int, reason: String = "", reward_id: String = "") -> bool:
	if amount <= 0:
		return false
	if reward_id != "" and claimed_rewards.get(reward_id, false):
		return false  # منع التكرار
	if reward_id != "":
		claimed_rewards[reward_id] = true
	balance += amount
	_log("earn", amount, reason if reason != "" else reward_id)
	emit_signal("balance_changed", balance)
	_sync_quest_money()
	_auto_save()
	return true

func spend(amount: int, reason: String = "") -> bool:
	if amount <= 0:
		return false
	if balance < amount:
		emit_signal("purchase_failed", "رصيد غير كافٍ")
		return false
	balance -= amount
	_log("spend", -amount, reason)
	emit_signal("balance_changed", balance)
	_sync_quest_money()
	_auto_save()
	return true

func can_afford(price: int) -> bool:
	return balance >= price

func _ach_buy_hook():
	if AchievementSystem:
		AchievementSystem.unlock("first_buy")

func buy_weapon(item_id: String) -> bool:
	if _buy_lock > 0.0:
		return false
	if item_id in owned_weapons:
		emit_signal("purchase_failed", "تمتلك هذا السلاح بالفعل")
		return false
	var item := _find_catalog("weapons", item_id)
	if item.is_empty():
		emit_signal("purchase_failed", "عنصر غير موجود")
		return false
	var price := int(item.get("price", 0))
	if not spend(price, "شراء سلاح: " + str(item.get("name", item_id))):
		return false
	_buy_lock = 0.4
	owned_weapons.append(item_id)
	# أضف لـ WeaponManager
	var wm := get_tree().root.find_child("WeaponManager", true, false)
	if wm and wm.has_method("add_weapon"):
		wm.add_weapon(item_id)
	emit_signal("purchase_succeeded", item_id, "weapons")
	return true

func buy_vehicle(item_id: String) -> bool:
	if _buy_lock > 0.0:
		return false
	if item_id in owned_vehicles:
		emit_signal("purchase_failed", "تمتلك هذه المركبة")
		return false
	var item := _find_catalog("vehicles", item_id)
	if item.is_empty():
		emit_signal("purchase_failed", "مركبة غير موجودة")
		return false
	var price := int(item.get("price", 0))
	if not spend(price, "شراء مركبة: " + str(item.get("name", item_id))):
		return false
	_buy_lock = 0.4
	owned_vehicles.append(item_id)
	_spawn_owned_vehicle(item_id)
	emit_signal("purchase_succeeded", item_id, "vehicles")
	return true

func buy_property(item_id: String) -> bool:
	if _buy_lock > 0.0:
		return false
	if item_id in owned_properties:
		emit_signal("purchase_failed", "تمتلك هذا العقار")
		return false
	var item := _find_catalog("properties", item_id)
	if item.is_empty():
		emit_signal("purchase_failed", "عقار غير موجود")
		return false
	var price := int(item.get("price", 0))
	if not spend(price, "شراء عقار: " + str(item.get("name", item_id))):
		return false
	_buy_lock = 0.4
	owned_properties.append(item_id)
	emit_signal("purchase_succeeded", item_id, "properties")
	return true

func _spawn_owned_vehicle(vtype: String) -> void:
	var world := get_tree().current_scene
	if world == null:
		return
	# نقطة الجراج
	var pos := Vector3(55, 0.5, -100)
	pos.x += owned_vehicles.size() * 4.0
	var path := ""
	match vtype:
		"car":
			path = "res://scripts/vehicles/CarVehicle.gd"
		"motorcycle":
			path = "res://scripts/vehicles/MotorcycleVehicle.gd"
		"tuktuk":
			path = "res://scripts/vehicles/TukTukVehicle.gd"
		_:
			path = "res://scripts/vehicles/CarVehicle.gd"
	var script: GDScript = load(path)
	if script == null:
		return
	var veh: Node = script.new()
	veh.position = pos
	world.add_child(veh)
	if veh.has_method("setup_as_owned"):
		veh.setup_as_owned(true)

func _find_catalog(category: String, item_id: String) -> Dictionary:
	var arr: Array = catalog.get(category, [])
	for it in arr:
		if str(it.get("id", "")) == item_id:
			return it
	return {}

func get_catalog(category: String) -> Array:
	return catalog.get(category, [])

func owns_weapon(id: String) -> bool:
	return id in owned_weapons or id == "fists"

func owns_vehicle(id: String) -> bool:
	return id in owned_vehicles

func owns_property(id: String) -> bool:
	return id in owned_properties

func _log(kind: String, amount: int, reason: String) -> void:
	var entry := {
		"kind": kind,
		"amount": amount,
		"reason": reason,
		"balance": balance,
		"t": Time.get_unix_time_from_system()
	}
	transactions.push_front(entry)
	while transactions.size() > MAX_LOG:
		transactions.pop_back()
	emit_signal("transaction_logged", entry)

func _sync_quest_money() -> void:
	var qm := get_node_or_null("/root/QuestManager")
	if qm:
		qm.money = balance

func sync_from_quest_manager() -> void:
	# عند التحميل القديم
	var qm := get_node_or_null("/root/QuestManager")
	if qm and int(qm.money) > balance:
		balance = int(qm.money)
		emit_signal("balance_changed", balance)

func claim_mission_reward(mission_id: String, amount: int) -> bool:
	return add_money(amount, "مكافأة مهمة", "mission_" + mission_id)

func get_save_data() -> Dictionary:
	return {
		"version": 1,
		"balance": balance,
		"owned_weapons": owned_weapons,
		"owned_vehicles": owned_vehicles,
		"owned_properties": owned_properties,
		"claimed_rewards": claimed_rewards,
		"transactions": transactions.slice(0, mini(10, transactions.size()))
	}

func load_save_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	balance = maxi(0, int(data.get("balance", balance)))
	owned_weapons = data.get("owned_weapons", [])
	owned_vehicles = data.get("owned_vehicles", [])
	owned_properties = data.get("owned_properties", [])
	claimed_rewards = data.get("claimed_rewards", {})
	if data.has("transactions"):
		transactions = data["transactions"]
	emit_signal("balance_changed", balance)
	_sync_quest_money()
	# إعادة إضافة الأسلحة للمدير
	var wm := get_tree().root.find_child("WeaponManager", true, false)
	if wm and wm.has_method("add_weapon"):
		for id in owned_weapons:
			wm.add_weapon(str(id))

func _auto_save() -> void:
	if not SaveSystem:
		return
	var data := SaveSystem.current_save if not SaveSystem.current_save.is_empty() else SaveSystem.create_default_save()
	data["economy"] = get_save_data()
	data["player"] = data.get("player", {})
	data["player"]["money"] = balance
	SaveSystem.current_save = data
	SaveSystem.save_game(data)


## مزامنة شبكة مبسّطة — السيرفر هو المصدر عند التفعيل
@rpc("authority", "call_local", "reliable")
func rpc_set_balance(value: int) -> void:
	if "balance" in self:
		balance = value
	emit_signal("balance_changed", balance)

func network_add_money(amount: int, reason: String = "") -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		# العميل يطلب من السيرفر
		rpc_id(1, "server_add_money", amount, reason)
		return
	add_money(amount, reason)

@rpc("any_peer", "reliable")
func server_add_money(amount: int, reason: String = "") -> void:
	if not multiplayer.is_server():
		return
	add_money(amount, reason)
	rpc("rpc_set_balance", balance if "balance" in self else 0)
