extends Node3D
## مدير العالم — الجزء 3 (مدينة + مركبات)
## مملكة الصحاب | Mamlaket El Sohab

@onready var player_spawn: Marker3D = $PlayerSpawn

var player_scene: PackedScene = preload("res://scenes/player/Player.tscn")
var current_player: CharacterBody3D = null
var city_builder: Node3D = null
var day_night: Node = null
var minimap_ui: Control = null
var hud_layer: CanvasLayer = null
var vehicle_manager: Node = null
var vehicle_hud: CanvasLayer = null
var drive_camera: Camera3D = null
var mobile_controls: CanvasLayer = null
var net_sync: Node = null
var quest_hud: CanvasLayer = null

func _ready() -> void:
	if AudioManager:
		AudioManager.stop_music()
	print("[WorldManager] تحميل العالم — الجزء 3 (مركبات)")
	_setup_city()
	var NavScript: GDScript = load("res://scripts/world/CityNavigation.gd")
	if NavScript:
		var nav = NavScript.new()
		nav.name = "CityNavigation"
		add_child(nav)
	_setup_day_night()
	_spawn_player()
	_setup_enterable_buildings()
	_setup_vehicles()
	_setup_vehicle_manager()
	_setup_mobile_controls()
	_setup_network_sync()
	_setup_quests()
	_setup_police()
	call_deferred("_setup_cinematic")
	_setup_game_loop()
	_setup_combat()
	_setup_economy()
	call_deferred("_setup_city_ai")
	_setup_minimap()
	_setup_environment()
	# طقس
	var WScript = load("res://scripts/world/WeatherSystem.gd")
	if WScript:
		var weather = WScript.new()
		weather.name = "WeatherSystem"
		add_child(weather)
	# تفاعل
	var IScript = load("res://scripts/systems/InteractionSystem.gd")
	if IScript and current_player:
		var inter = IScript.new()
		inter.name = "InteractionSystem"
		add_child(inter)
		inter.setup(current_player)
	var tip_sc: PackedScene = load("res://scenes/ui/OnboardingTips.tscn")
	if tip_sc:
		add_child(tip_sc.instantiate())
	var DScript = load("res://scripts/dialogue/DialogueSystem.gd")
	if DScript:
		var dlg = DScript.new()
		dlg.name = "DialogueSystem"
		add_child(dlg)
	var RScript = load("res://scripts/systems/RaceSystem.gd")
	if RScript:
		var race = RScript.new()
		race.name = "RaceSystem"
		add_child(race)
	var SD = load("res://scripts/world/StreetDecor.gd")
	if SD:
		var decor = SD.new()
		decor.name = "StreetDecor"
		add_child(decor)
	var race = find_child("RaceSystem", true, false)
	var RH = load("res://scripts/ui/RaceHUD.gd")
	if RH:
		var rh = RH.new()
		rh.name = "RaceHUD"
		add_child(rh)
		if race:
			rh.bind(race)
	var AT = load("res://scripts/ui/AchievementToast.gd")
	if AT:
		add_child(AT.new())
	var WB = load("res://scripts/quests/WantedMissionBridge.gd")
	if WB:
		var wb = WB.new()
		wb.name = "WantedMissionBridge"
		add_child(wb)
	if SaveSystem and current_player:
		SaveSystem.bind_player(current_player)
	# حفظ أول بعد ثوانٍ من البداية
	get_tree().create_timer(3.0).timeout.connect(func():
		if SaveSystem:
			SaveSystem.request_quick_save()
	)
	print("[WorldManager] جاهز — مدن + مركبات")

func _setup_city() -> void:
	var CityBuilderScript: GDScript = load("res://scripts/world/CityBuilder.gd")
	city_builder = CityBuilderScript.new()
	city_builder.name = "CityBuilder"
	add_child(city_builder)

func _setup_day_night() -> void:
	var DayNightScript: GDScript = load("res://scripts/world/DayNightCycle.gd")
	day_night = DayNightScript.new()
	day_night.name = "DayNightCycle"
	add_child(day_night)

func _spawn_player() -> void:
	current_player = player_scene.instantiate()
	current_player.add_to_group("player")
	add_child(current_player)
	# موضع افتراضي: داخل منزل اللاعب
	var home_pos: Vector3 = GameManager.get_home_global_position() if GameManager else Vector3(-6, 1.3, 20)
	current_player.global_position = home_pos
	# تطبيق الحفظ بعد جاهزية الفيزياء (إطار مؤجل)
	call_deferred("_apply_spawn_from_save")
	if SaveSystem:
		SaveSystem.bind_player(current_player)
	var AppS = load("res://scripts/player/PlayerAppearance.gd")
	if AppS:
		var app = AppS.new()
		app.name = "PlayerAppearance"
		current_player.add_child(app)
	GameManager.world_ready = true
	GameManager.emit_signal("player_ready")
	print("[WorldManager] اللاعب جاهز — انتظار تطبيق الحفظ")

func _apply_spawn_from_save() -> void:
	if current_player == null or not is_instance_valid(current_player):
		return
	await get_tree().physics_frame
	await get_tree().physics_frame
	if SaveSystem == null:
		return
	var data: Dictionary = SaveSystem.current_save
	if data.is_empty() and GameManager and GameManager.pending_continue:
		data = SaveSystem.load_game()
	if data.is_empty():
		# لعبة جديدة — منزل
		current_player.global_position = GameManager.get_home_global_position()
		print("[WorldManager] بداية جديدة داخل المنزل: ", current_player.global_position)
		return
	if SaveSystem.has_method("apply_full_state"):
		SaveSystem.apply_full_state(data, current_player)
	else:
		var pd: Dictionary = data.get("player", {})
		if pd.has("position"):
			var p: Dictionary = pd["position"]
			var y := float(p.get("y", 1.3))
			if y < 0.5:
				y = 1.3
			current_player.global_position = Vector3(float(p.get("x", -6)), y, float(p.get("z", 20)))
	# تأكد فوق الأرض
	if current_player.global_position.y < 0.5:
		current_player.global_position.y = 1.3
	print("[WorldManager] موضع بعد الحفظ: ", current_player.global_position)

func _setup_enterable_buildings() -> void:
	# منزل اللاعب — نقطة بداية اللعبة الجديدة
	_add_enterable(Vector3(-8, 0, 18), Vector3(8, 4.5, 7), "player_home", "منزل أبو كردوم", Color(0.15, 0.12, 0.1))
	_add_enterable(Vector3(18, 0, 10), Vector3(6, 5, 5), "shop_1", "محل الصحاب", Color(0.45, 0.38, 0.32))
	_add_enterable(Vector3(-18, 0, 12), Vector3(7, 6, 6), "house_1", "منزل سكني", Color(0.58, 0.50, 0.42))
	_add_enterable(Vector3(12, 0, -18), Vector3(8, 7, 6), "activity_hall", "قاعة الأنشطة", Color(0.18, 0.18, 0.22))
	_add_enterable(Vector3(-25, 0, 5), Vector3(9, 5, 7), "garage_shop", "ورشة المرآب", Color(0.25, 0.22, 0.15))
	_add_enterable(Vector3(30, 0, -12), Vector3(6, 4, 6), "cafe_1", "مقهى الصحاب", Color(0.35, 0.28, 0.22))

func _add_enterable(pos: Vector3, size: Vector3, id: String, label: String, color: Color) -> void:
	var EnterableScript: GDScript = load("res://scripts/world/EnterableBuilding.gd")
	var b: StaticBody3D = EnterableScript.new()
	b.building_id = id
	b.building_label = label
	b.position = pos + Vector3(0, size.y * 0.5, 0)
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	mesh_inst.material_override = mat
	b.add_child(mesh_inst)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	b.add_child(col)
	var door := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(1.4, 2.2, 0.15)
	door.mesh = dm
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.85, 0.65, 0.13)
	dmat.metallic = 0.5
	door.material_override = dmat
	door.position = Vector3(0, -size.y * 0.5 + 1.1, size.z * 0.5 + 0.05)
	b.add_child(door)
	var sign := Label3D.new()
	sign.text = label
	sign.font_size = 32
	sign.modulate = Color(0.92, 0.75, 0.2)
	sign.outline_size = 4
	sign.position = Vector3(0, size.y * 0.5 + 0.4, 0)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	b.add_child(sign)
	add_child(b)

func _setup_vehicles() -> void:
	# نشر مركبات في العاصمة وحولها
	var spots := [
		{"pos": Vector3(8, 0.5, 20), "type": "car"},
		{"pos": Vector3(-10, 0.5, 18), "type": "car"},
		{"pos": Vector3(15, 0.5, 5), "type": "motorcycle"},
		{"pos": Vector3(-12, 0.5, 8), "type": "tuktuk"},
		{"pos": Vector3(25, 0.5, 30), "type": "car"},
		{"pos": Vector3(-20, 0.5, 25), "type": "motorcycle"},
		{"pos": Vector3(5, 0.5, -15), "type": "tuktuk"},
		{"pos": Vector3(40, 0.5, 10), "type": "car"},
		{"pos": Vector3(-35, 0.5, -5), "type": "car"},
		{"pos": Vector3(0, 0.5, 40), "type": "motorcycle"},
		{"pos": Vector3(60, 0.5, -90), "type": "car"},  # عند الجراج
		{"pos": Vector3(55, 0.5, -95), "type": "tuktuk"},
	]
	for s in spots:
		_spawn_vehicle(s["pos"], s["type"])
	print("[WorldManager] تم نشر ", spots.size(), " مركبة")

func _spawn_vehicle(pos: Vector3, vtype: String) -> void:
	var script_path := "res://scripts/vehicles/CarVehicle.gd"
	if vtype == "motorcycle":
		script_path = "res://scripts/vehicles/MotorcycleVehicle.gd"
	elif vtype == "tuktuk":
		script_path = "res://scripts/vehicles/TukTukVehicle.gd"
	var scr: GDScript = load(script_path)
	var veh: CharacterBody3D = scr.new()
	veh.position = pos
	add_child(veh)

func _setup_vehicle_manager() -> void:
	var VMScript: GDScript = load("res://scripts/vehicles/VehicleManager.gd")
	vehicle_manager = VMScript.new()
	vehicle_manager.name = "VehicleManager"
	add_child(vehicle_manager)
	vehicle_manager.setup(current_player)
	vehicle_manager.vehicle_entered.connect(_on_vehicle_entered)
	vehicle_manager.vehicle_exited.connect(_on_vehicle_exited)
	
	var hud_scene: PackedScene = load("res://scenes/ui/VehicleHUD.tscn")
	if hud_scene:
		vehicle_hud = hud_scene.instantiate()
		add_child(vehicle_hud)
		if vehicle_hud.has_method("setup"):
			vehicle_hud.setup(vehicle_manager)
	
	# كاميرا قيادة
	drive_camera = Camera3D.new()
	drive_camera.name = "DriveCamera"
	drive_camera.current = false
	drive_camera.fov = 75.0
	drive_camera.far = 50000.0
	add_child(drive_camera)

func _on_vehicle_entered(veh: Node) -> void:
	if current_player and current_player.has_method("set_control_enabled"):
		current_player.set_control_enabled(false)
	if mobile_controls:
		mobile_controls.visible = false
	var ch := get_node_or_null("CombatHUD")
	if ch and ch.has_method("set_combat_visible"):
		ch.set_combat_visible(false)
	var cbt := get_node_or_null("CombatController")
	if cbt:
		cbt.combat_enabled = false
	if drive_camera and veh:
		drive_camera.current = true
		# ربط الكاميرا خلف المركبة
		if drive_camera.get_parent() != veh:
			drive_camera.get_parent().remove_child(drive_camera)
			veh.add_child(drive_camera)
		drive_camera.position = Vector3(0, 3.5, 8.0)
		drive_camera.look_at(veh.global_position + Vector3(0, 1, 0))
		drive_camera.rotation = Vector3(deg_to_rad(-15), 0, 0)
		drive_camera.position = Vector3(0, 4.0, 9.0)

func _on_vehicle_exited(_veh: Node) -> void:
	if current_player and current_player.has_method("set_control_enabled"):
		current_player.set_control_enabled(true)
	if mobile_controls:
		mobile_controls.visible = true
	var ch2 := get_node_or_null("CombatHUD")
	if ch2 and ch2.has_method("set_combat_visible"):
		ch2.set_combat_visible(true)
	var cbt2 := get_node_or_null("CombatController")
	if cbt2:
		cbt2.combat_enabled = true
	if drive_camera:
		drive_camera.current = false
		if drive_camera.get_parent() != self:
			drive_camera.get_parent().remove_child(drive_camera)
			add_child(drive_camera)
	# إعادة كاميرا اللاعب
	if current_player:
		var cam: Camera3D = current_player.get_node_or_null("CameraPivot/Camera3D")
		if cam:
			cam.current = true


func _setup_mobile_controls() -> void:
	var scene: PackedScene = load("res://scenes/ui/MobileControls.tscn")
	if scene:
		mobile_controls = scene.instantiate()
		add_child(mobile_controls)
		if mobile_controls.has_method("setup"):
			mobile_controls.setup(current_player)
		print("[WorldManager] أزرار اللمس جاهزة")


func _setup_network_sync() -> void:
	if multiplayer.multiplayer_peer == null:
		return
	if not multiplayer.has_multiplayer_peer():
		return
	var SyncScript: GDScript = load("res://scripts/networking/local/NetworkPlayerSync.gd")
	if SyncScript == null:
		return
	net_sync = SyncScript.new()
	net_sync.name = "NetworkPlayerSync"
	add_child(net_sync)
	if net_sync.has_method("setup"):
		net_sync.setup(current_player, self)
	# اسم محلي فوق اللاعب
	if current_player:
		var label := Label3D.new()
		label.name = "LocalNameLabel"
		var lmp := get_tree().root.find_child("LocalMultiplayerManager", true, false)
		var n := "أنا"
		if lmp and lmp.get("local_player_name"):
			n = str(lmp.local_player_name)
		label.text = n
		label.font_size = 40
		label.modulate = Color(0.95, 0.85, 0.3)
		label.outline_size = 5
		label.position = Vector3(0, 2.35, 0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		current_player.add_child(label)
	print("[WorldManager] مزامنة الشبكة مفعّلة")


func _setup_police() -> void:
	var PoliceScript: GDScript = load("res://scripts/police/PoliceManager.gd")
	if PoliceScript == null:
		return
	var pm: Node = PoliceScript.new()
	pm.name = "PoliceManager"
	add_child(pm)
	if pm.has_method("setup"):
		pm.setup(current_player, self)
	var hud_sc: PackedScene = load("res://scenes/ui/WantedHUD.tscn")
	if hud_sc:
		var wh = hud_sc.instantiate()
		add_child(wh)
		if wh.has_method("setup"):
			wh.setup(pm)
	# مفتاح تجريبي لرفع المطلوب (لوحة مفاتيح)
	print("[WorldManager] الشرطة جاهزة — اصطدم بقوة أو اضغط P لرفع المطلوب")

func _setup_cinematic() -> void:
	var sc: PackedScene = load("res://scenes/ui/CinematicOverlay.tscn")
	if sc:
		var cine = sc.instantiate()
		cine.name = "CinematicOverlay"
		add_child(cine)
		print("[WorldManager] المشاهد السينمائية جاهزة")


func _setup_game_loop() -> void:
	# صحة اللاعب
	var VitalsScript: GDScript = load("res://scripts/player/PlayerVitals.gd")
	var vitals: Node = null
	if VitalsScript and current_player:
		vitals = VitalsScript.new()
		vitals.name = "PlayerVitals"
		current_player.add_child(vitals)
		vitals.setup(current_player)
	# HUD
	var gh: PackedScene = load("res://scenes/ui/GameHUD.tscn")
	if gh:
		var hud = gh.instantiate()
		add_child(hud)
		if hud.has_method("setup"):
			hud.setup(vitals)
	# Pause
	var ps: PackedScene = load("res://scenes/ui/PauseMenu.tscn")
	if ps:
		var pause = ps.instantiate()
		pause.name = "PauseMenu"
		add_child(pause)
		if pause.has_method("setup"):
			pause.setup(self)
	# متجر
	var ShopScript: GDScript = load("res://scripts/npc/ShopNPC.gd")
	if ShopScript:
		var shop = ShopScript.new()
		shop.position = Vector3(35, 0, -40)
		add_child(shop)
	print("[WorldManager] حلقة اللعب الحقيقية جاهزة")


func _setup_combat()
	_setup_economy()
	_setup_city_ai() -> void:
	var WepScript: GDScript = load("res://scripts/combat/WeaponManager.gd")
	var CbtScript: GDScript = load("res://scripts/combat/CombatController.gd")
	if WepScript == null or CbtScript == null or current_player == null:
		return
	var weapons: Node = WepScript.new()
	weapons.name = "WeaponManager"
	add_child(weapons)
	# تحميل حفظ
	if not SaveSystem.current_save.is_empty() and SaveSystem.current_save.has("weapons"):
		if weapons.has_method("load_save_data"):
			weapons.load_save_data(SaveSystem.current_save["weapons"])
	var combat: Node = CbtScript.new()
	combat.name = "CombatController"
	add_child(combat)
	combat.setup(current_player, weapons)
	# HUD
	var hud_sc: PackedScene = load("res://scenes/ui/CombatHUD.tscn")
	if hud_sc:
		var ch = hud_sc.instantiate()
		ch.name = "CombatHUD"
		add_child(ch)
		if ch.has_method("setup"):
			ch.setup(combat, weapons)
	# أعداء في نقاط محدودة (ليس في كل مكان)
	_spawn_combat_enemies()
	# إخفاء أزرار القتال أثناء القيادة
	print("[WorldManager] نظام القتال جاهز")

func _spawn_combat_enemies() -> void:
	var EnemyScript: GDScript = load("res://scripts/combat/EnemyAI.gd")
	if EnemyScript == null:
		return
	var spots := [
		Vector3(120, 0, 40),
		Vector3(-90, 0, -50),
		Vector3(60, 0, 100),
		Vector3(-40, 0, 130),
	]
	for i in range(spots.size()):
		var e: CharacterBody3D = EnemyScript.new()
		e.position = spots[i]
		add_child(e)
		if e.has_method("setup"):
			e.setup(current_player, 1.0)


func _setup_economy()
	_setup_city_ai() -> void:
	var eco := get_node_or_null("/root/EconomyManager")
	if eco == null:
		return
	# تحميل حفظ
	if not SaveSystem.current_save.is_empty() and SaveSystem.current_save.has("economy"):
		eco.load_save_data(SaveSystem.current_save["economy"])
	elif not SaveSystem.current_save.is_empty():
		# ترقية من مال قديم
		var old_m := int(SaveSystem.current_save.get("player", {}).get("money", 0))
		if old_m > 0:
			eco.balance = old_m
	eco.sync_from_quest_manager()
	# واجهة
	var ui_sc: PackedScene = load("res://scenes/ui/EconomyUI.tscn")
	if ui_sc:
		add_child(ui_sc.instantiate())
	# عقارات في العالم
	var PropScript: GDScript = load("res://scripts/economy/PropertyMarker.gd")
	if PropScript and eco:
		for it in eco.get_catalog("properties"):
			var m: StaticBody3D = PropScript.new()
			m.property_id = str(it.get("id", ""))
			var pos: Dictionary = it.get("pos", {})
			m.position = Vector3(float(pos.get("x", 0)), float(pos.get("y", 0)), float(pos.get("z", 0)))
			add_child(m)
	# إعادة ظهور مركبات مملوكة
	for vid in eco.owned_vehicles:
		if eco.has_method("_spawn_owned_vehicle"):
			eco._spawn_owned_vehicle(str(vid))
	print("[WorldManager] الاقتصاد جاهز — رصيد=", eco.balance)


func _setup_city_ai() -> void:
	var AIScript: GDScript = load("res://scripts/city_ai/CityAIManager.gd")
	if AIScript == null or current_player == null:
		return
	var ai: Node = AIScript.new()
	ai.name = "CityAIManager"
	add_child(ai)
	ai.setup(current_player, self)
	# خريطة كاملة + بوصلة
	var pts := {}
	if city_builder and city_builder.has_method("get_important_points"):
		pts = city_builder.get_important_points().duplicate(true)
	# نقاط اقتصاد
	pts["shop_marker"] = {"pos": Vector3(35, 1, -40), "type": "shop", "label": "متجر"}
	pts["garage"] = pts.get("garage", {"pos": Vector3(50, 1, -95), "type": "garage", "label": "الجراج"})
	var fmap: PackedScene = load("res://scenes/ui/FullMapUI.tscn")
	var map_ui = null
	if fmap:
		map_ui = fmap.instantiate()
		map_ui.name = "FullMapUI"
		add_child(map_ui)
		if map_ui.has_method("setup"):
			map_ui.setup(current_player, pts)
	var comp_sc: PackedScene = load("res://scenes/ui/DestinationCompass.tscn")
	if comp_sc:
		var comp = comp_sc.instantiate()
		add_child(comp)
		if comp.has_method("setup"):
			comp.setup(current_player, map_ui)
	print("[WorldManager] مشاة + مرور + خريطة تفاعلية")

func _setup_minimap() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "HUD"
	hud_layer.layer = 10
	add_child(hud_layer)
	var minimap_scene: PackedScene = load("res://scenes/ui/Minimap.tscn")
	if minimap_scene:
		minimap_ui = minimap_scene.instantiate()
		hud_layer.add_child(minimap_ui)
		if minimap_ui.has_method("setup"):
			minimap_ui.setup(current_player, city_builder, day_night)
		var draw_node: Control = minimap_ui.get_node_or_null("MapPanel/MapDraw")
		if draw_node and draw_node.has_method("setup"):
			var pts := {}
			if city_builder and city_builder.has_method("get_important_points"):
				pts = city_builder.get_important_points()
			draw_node.setup(current_player, pts)

func _setup_environment() -> void:
	var sun := get_node_or_null("DirectionalLight3D")
	if sun:
		sun.shadow_enabled = true

func _physics_process(_delta: float) -> void:
	_update_quest_marker()

	# تحديث موضع كاميرا القيادة خلف المركبة
	if vehicle_manager and vehicle_manager.is_driving and drive_camera and drive_camera.current:
		var veh: Node3D = vehicle_manager.current_vehicle
		if veh and is_instance_valid(veh):
			var spd := 0.0
			if "current_speed" in veh:
				spd = absf(float(veh.current_speed))
			var back := 8.0 + clampf(spd * 0.12, 0.0, 6.0)
			var up := 3.2 + clampf(spd * 0.03, 0.0, 1.5)
			drive_camera.position = drive_camera.position.lerp(Vector3(0, up, back), 0.12)
			drive_camera.rotation_degrees = Vector3(-14, 0, 0)
			drive_camera.fov = lerpf(drive_camera.fov, 70.0 + clampf(spd * 0.35, 0.0, 18.0), 0.1)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_H:
			var G = load("res://scripts/ui/GarageMenu.gd")
			if G:
				add_child(G.new())
		elif event.keycode == KEY_J:
			var A = load("res://scripts/ui/AppearanceMenu.gd")
			if A:
				add_child(A.new())
		elif event.keycode == KEY_F5:
			if SaveSystem and SaveSystem.has_method("capture_full_state"):
				var data = SaveSystem.capture_full_state(current_player)
				SaveSystem.save_game(data)
				print("[Save] حفظ سريع F5")
		elif event.keycode == KEY_G:
			var race = find_child("RaceSystem", true, false)
			if race and race.has_method("start_race") and current_player:
				race.start_race(current_player)
		elif event.keycode == KEY_Y:
			var race2 = find_child("RaceSystem", true, false)
			if race2 and race2.has_method("start_tournament") and current_player:
				race2.start_tournament(current_player)

	if event.is_action_pressed("pause"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			_save_player_state()
			GameManager.go_to_main_menu()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_T and day_night:
			day_night.current_hour = fmod(day_night.current_hour + 2.0, 24.0)
			day_night._apply_time(true)

func _save_player_state() -> void:
	if current_player == null:
		return
	# إذا كان يقود، انزل أولاً لحفظ موضع منطقي
	if vehicle_manager and vehicle_manager.is_driving:
		vehicle_manager.try_exit()
	if current_player.has_method("get_save_data"):
		var data := SaveSystem.current_save if not SaveSystem.current_save.is_empty() else SaveSystem.create_default_save()
		data["player"].merge(current_player.get_save_data(), true)
		SaveSystem.save_game(data)


func _update_quest_marker() -> void:
	var qm := get_node_or_null("/root/QuestManager")
	if qm == null or minimap_ui == null:
		return
	var pos = qm.get_objective_marker_pos() if qm.has_method("get_objective_marker_pos") else null
	var draw_node: Control = minimap_ui.get_node_or_null("MapPanel/MapDraw")
	if draw_node == null:
		return
	# points dict if stored
	if draw_node.get("points") != null or draw_node.has_method("set"):
		pass
	if draw_node.get("important_points") is Dictionary:
		var pts: Dictionary = draw_node.important_points
		if pos != null:
			pts["quest_marker"] = {"pos": pos, "type": "quest_marker", "label": "هدف"}
		elif pts.has("quest_marker"):
			pts.erase("quest_marker")



func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_CTRL:
			var cbt := get_node_or_null("CombatController")
			if cbt and cbt.has_method("try_attack"):
				cbt.try_attack()
		elif event.keycode == KEY_Q:
			var cbt2 := get_node_or_null("CombatController")
			if cbt2 and cbt2.has_method("cycle_weapon"):
				cbt2.cycle_weapon()
		elif event.keycode == KEY_R:
			var cbt3 := get_node_or_null("CombatController")
			if cbt3 and cbt3.has_method("try_reload"):
				cbt3.try_reload()
		elif event.keycode == KEY_N:
			var ai := get_node_or_null("CityAIManager")
			if ai and ai.has_method("set_density"):
				var d: int = int(ai.density)
				ai.set_density((d + 1) % 3)
				print("[CityAI] كثافة=", ai.density)
		elif event.keycode == KEY_P:
			var pm := get_node_or_null("PoliceManager")
			if pm and pm.has_method("add_heat"):
				pm.add_heat(1)
		elif event.keycode == KEY_ESCAPE or event.is_action_pressed("pause"):
			var pause := get_node_or_null("PauseMenu")
			if pause and pause.has_method("toggle"):
				pause.toggle()


func _notification(what: int) -> void:
	# حفظ عند الخروج للخلفية (أندرويد)
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_player_state()
