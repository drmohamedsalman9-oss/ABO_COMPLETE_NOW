extends Node3D
## مملكة الصحاب — خريطة معدّلة: مدن + قرى + صحراء + أنهار + كباري
## عالم 1,000,000 × 1,000,000
## محمد ماهر | Mohammed Maher

signal city_built

const WORLD_SIZE := 1000000.0
const HALF := WORLD_SIZE * 0.5

var buildings_root: Node3D
var roads_root: Node3D
var props_root: Node3D
var lights_root: Node3D
var terrain_root: Node3D
var water_root: Node3D
var bounds_root: Node3D
var landmarks_root: Node3D

var mat_asphalt: StandardMaterial3D
var mat_dirt_road: StandardMaterial3D
var mat_sidewalk: StandardMaterial3D
var mat_dirt: StandardMaterial3D
var mat_sand: StandardMaterial3D
var mat_sand2: StandardMaterial3D
var mat_grass: StandardMaterial3D
var mat_water: StandardMaterial3D
var mat_house: StandardMaterial3D
var mat_house2: StandardMaterial3D
var mat_house3: StandardMaterial3D
var mat_warehouse: StandardMaterial3D
var mat_tower: StandardMaterial3D
var mat_roof: StandardMaterial3D
var mat_roof_red: StandardMaterial3D
var mat_gold: StandardMaterial3D
var mat_tree: StandardMaterial3D
var mat_pole: StandardMaterial3D
var mat_bulb: StandardMaterial3D
var mat_wall: StandardMaterial3D
var mat_bridge: StandardMaterial3D
var mat_bridge_rail: StandardMaterial3D

var important_points: Dictionary = {}

func _ready() -> void:
	_create_materials()
	_create_roots()
	_build_world()
	emit_signal("city_built")
	print("[CityBuilder] خريطة جديدة — مدن وقرى | عالم %.0f×%.0f" % [WORLD_SIZE, WORLD_SIZE])

func get_world_size() -> float:
	return WORLD_SIZE

func get_important_points() -> Dictionary:
	return important_points

func _create_materials() -> void:
	mat_asphalt = _mat(Color(0.11, 0.11, 0.13), 0.95, 0.0)
	mat_dirt_road = _mat(Color(0.42, 0.34, 0.22), 0.95, 0.0)
	mat_sidewalk = _mat(Color(0.4, 0.38, 0.35), 0.9, 0.0)
	mat_dirt = _mat(Color(0.32, 0.26, 0.16), 0.95, 0.0)
	mat_sand = _mat(Color(0.62, 0.54, 0.36), 0.92, 0.0)
	mat_sand2 = _mat(Color(0.52, 0.44, 0.28), 0.93, 0.0)
	mat_grass = _mat(Color(0.22, 0.36, 0.14), 0.95, 0.0)
	mat_water = _mat(Color(0.12, 0.32, 0.42, 0.75), 0.12, 0.05)
	mat_water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_house = _mat(Color(0.72, 0.68, 0.58), 0.88, 0.0)
	mat_house2 = _mat(Color(0.55, 0.48, 0.40), 0.88, 0.0)
	mat_house3 = _mat(Color(0.78, 0.72, 0.65), 0.85, 0.0)
	mat_warehouse = _mat(Color(0.35, 0.38, 0.40), 0.8, 0.05)
	mat_tower = _mat(Color(0.3, 0.32, 0.36), 0.75, 0.1)
	mat_roof = _mat(Color(0.25, 0.22, 0.20), 0.9, 0.0)
	mat_roof_red = _mat(Color(0.55, 0.22, 0.15), 0.85, 0.0)
	mat_gold = _mat(Color(0.85, 0.65, 0.13), 0.3, 0.6)
	mat_tree = _mat(Color(0.14, 0.32, 0.10), 0.95, 0.0)
	mat_pole = _mat(Color(0.18, 0.18, 0.20), 0.7, 0.1)
	mat_bulb = _mat(Color(1.0, 0.9, 0.55), 0.25, 0.0)
	mat_bulb.emission_enabled = true
	mat_bulb.emission = Color(1.0, 0.85, 0.4)
	mat_bulb.emission_energy_multiplier = 0.0
	mat_wall = _mat(Color(0.05, 0.05, 0.07, 0.12), 1.0, 0.0)
	mat_wall.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_bridge = _mat(Color(0.28, 0.28, 0.30), 0.7, 0.15)
	mat_bridge_rail = _mat(Color(0.2, 0.2, 0.22), 0.6, 0.2)

func _mat(c: Color, r: float, m: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = r
	mat.metallic = m
	return mat

func _create_roots() -> void:
	terrain_root = _root("Terrain")
	water_root = _root("Water")
	roads_root = _root("Roads")
	buildings_root = _root("Buildings")
	props_root = _root("Props")
	lights_root = _root("StreetLights")
	landmarks_root = _root("Landmarks")
	bounds_root = _root("WorldBounds")
	call_deferred("_reparent_lights")

func _root(n: String) -> Node3D:
	var node := Node3D.new()
	node.name = n
	add_child(node)
	return node

func _reparent_lights() -> void:
	var world := get_parent()
	if world and lights_root.get_parent() == self:
		remove_child(lights_root)
		world.add_child(lights_root)

func _build_world() -> void:
	_build_terrain()
	_build_desert_zones()
	_build_rivers_and_bridges()
	_build_highway_network()
	
	# ═══════ مدن (كبيرة وكثيفة) ═══════
	_build_city(Vector3(0, 0, 0), "مدينة الصحاب", true)           # العاصمة
	_build_city(Vector3(900, 0, 700), "مدينة الشرق")
	_build_city(Vector3(-850, 0, 600), "مدينة الغرب")
	_build_city(Vector3(200, 0, -900), "مدينة الجنوب")
	_build_city(Vector3(-100, 0, 1100), "مدينة الشمال")
	
	# ═══════ قرى (صغيرة ومتباعدة) ═══════
	_build_village(Vector3(350, 0, 250), "قرية النخيل")
	_build_village(Vector3(-400, 0, 300), "قرية الوادي")
	_build_village(Vector3(450, 0, -350), "قرية الرمال")
	_build_village(Vector3(-380, 0, -400), "قرية الجبل")
	_build_village(Vector3(600, 0, 100), "قرية الميناء الصغير")
	_build_village(Vector3(-550, 0, -150), "قرية الزيتون")
	_build_village(Vector3(150, 0, 550), "قرية الصفا")
	_build_village(Vector3(-200, 0, -600), "قرية البركة")
	_build_village(Vector3(700, 0, -200), "قرية السرايا")
	_build_village(Vector3(-700, 0, 200), "قرية العيون")
	
	# مدن/قرى أبعد على مقياس العالم الكبير
	_build_city(Vector3(3500, 0, 2000), "مدينة بعيدة أ")
	_build_city(Vector3(-3000, 0, 2500), "مدينة بعيدة ب")
	_build_village(Vector3(2000, 0, -1500), "قرية بعيدة 1")
	_build_village(Vector3(-2500, 0, -1800), "قرية بعيدة 2")
	_build_village(Vector3(0, 0, 4500), "قرية الشمال البعيد")
	_build_village(Vector3(6000, 0, 0), "قرية الشرق البعيد")
	
	_build_garage(Vector3(60, 0, -100))
	_build_road_lights()
	_build_trees()
	_remote_landmarks()
	_build_world_bounds()
	_register_markers()

func _build_terrain() -> void:
	var tile := 25000.0
	for ix in range(-2, 3):
		for iz in range(-2, 3):
			var cx := float(ix) * tile
			var cz := float(iz) * tile
			var mat := mat_grass
			if absf(cx) > 2000.0 or absf(cz) > 2000.0:
				mat = mat_sand
			elif absf(cx) > 800.0 or absf(cz) > 800.0:
				mat = mat_dirt
			_box_static(Vector3(cx, -0.8, cz), Vector3(tile + 80.0, 1.2, tile + 80.0), mat, terrain_root)
	_box_mesh(Vector3(0, -0.05, 0), Vector3(600, 0.2, 600), mat_grass, terrain_root)

func _build_desert_zones() -> void:
	for d in [
		Vector3(1100, 0.02, 900), Vector3(-1000, 0.02, 800),
		Vector3(950, 0.02, -1000), Vector3(-900, 0.02, -950),
		Vector3(1500, 0.02, 0), Vector3(-1500, 0.02, 100)
	]:
		_box_mesh(d, Vector3(400, 0.14, 400), mat_sand, terrain_root)
		_box_mesh(d + Vector3(100, 0.03, -80), Vector3(200, 0.1, 180), mat_sand2, terrain_root)
	important_points["desert"] = {"pos": Vector3(1100, 1, 900), "type": "landmark", "label": "الصحراء"}

func _build_rivers_and_bridges() -> void:
	_box_mesh(Vector3(0, -0.4, 120), Vector3(1200, 0.7, 30), mat_water, water_root)
	_box_mesh(Vector3(250, -0.4, -200), Vector3(30, 0.7, 700), mat_water, water_root)
	_box_mesh(Vector3(-400, -0.4, 250), Vector3(600, 0.7, 24), mat_water, water_root)
	_box_mesh(Vector3(900, -0.4, 700), Vector3(200, 0.7, 22), mat_water, water_root)
	
	_make_bridge(Vector3(0, 0, 120), 0.0)
	_make_bridge(Vector3(180, 0, 120), 0.0)
	_make_bridge(Vector3(-180, 0, 120), 0.0)
	_make_bridge(Vector3(250, 0, -150), 90.0)
	_make_bridge(Vector3(250, 0, -300), 90.0)
	_make_bridge(Vector3(-300, 0, 250), 0.0)
	_make_bridge(Vector3(900, 0, 700), 0.0)
	
	important_points["bridge_main"] = {"pos": Vector3(0, 2, 120), "type": "landmark", "label": "الكوبري الرئيسي"}
	important_points["river"] = {"pos": Vector3(0, 1, 120), "type": "landmark", "label": "النهر"}

func _make_bridge(pos: Vector3, yaw_deg: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = deg_to_rad(yaw_deg)
	var deck := StaticBody3D.new()
	deck.collision_layer = 1
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(14, 0.8, 42)
	mi.mesh = box
	mi.material_override = mat_bridge
	deck.add_child(mi)
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(14, 0.8, 42)
	col.shape = sh
	deck.add_child(col)
	deck.position.y = 1.2
	root.add_child(deck)
	for side in [-6.5, 6.5]:
		var rail := MeshInstance3D.new()
		var rm := BoxMesh.new()
		rm.size = Vector3(0.3, 1.2, 42)
		rail.mesh = rm
		rail.material_override = mat_bridge_rail
		rail.position = Vector3(side, 2.0, 0)
		root.add_child(rail)
	for z in [-14.0, 0.0, 14.0]:
		var pillar := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(1.5, 3.5, 1.5)
		pillar.mesh = pm
		pillar.material_override = mat_bridge
		pillar.position = Vector3(0, -0.5, z)
		root.add_child(pillar)
	props_root.add_child(root)

func _build_highway_network() -> void:
	_road(Vector3(0, 0.06, 0), Vector3(14, 0.1, 2500), mat_asphalt)
	_road(Vector3(0, 0.06, 0), Vector3(2500, 0.1, 14), mat_asphalt)
	_road(Vector3(9, 0.07, 0), Vector3(2.0, 0.05, 2480), mat_sidewalk)
	_road(Vector3(-9, 0.07, 0), Vector3(2.0, 0.05, 2480), mat_sidewalk)
	# ربط المدن
	_road(Vector3(450, 0.06, 350), Vector3(12, 0.09, 900), mat_asphalt)
	_road(Vector3(-420, 0.06, 300), Vector3(12, 0.09, 800), mat_asphalt)
	_road(Vector3(100, 0.06, -450), Vector3(12, 0.09, 1000), mat_asphalt)
	_road(Vector3(-50, 0.06, 550), Vector3(12, 0.09, 1200), mat_asphalt)
	_road(Vector3(450, 0.06, 0), Vector3(1000, 0.09, 12), mat_asphalt)
	_road(Vector3(-400, 0.06, 0), Vector3(900, 0.09, 12), mat_asphalt)
	# طرق ترابية للقرى
	for p in [
		[Vector3(175, 0.05, 125), Vector3(7, 0.06, 200)],
		[Vector3(-200, 0.05, 150), Vector3(7, 0.06, 180)],
		[Vector3(225, 0.05, -175), Vector3(180, 0.06, 7)],
		[Vector3(-190, 0.05, -200), Vector3(160, 0.06, 7)],
		[Vector3(300, 0.05, 50), Vector3(7, 0.06, 150)],
		[Vector3(-280, 0.05, -80), Vector3(7, 0.06, 140)]
	]:
		_road(p[0], p[1], mat_dirt_road)
	# طرق بعيدة
	_road(Vector3(0, 0.05, 2500), Vector3(16, 0.1, 5000), mat_asphalt)
	_road(Vector3(3000, 0.05, 0), Vector3(7000, 0.1, 16), mat_asphalt)
	_road(Vector3(0, 0.05, -2500), Vector3(16, 0.1, 5000), mat_asphalt)
	_road(Vector3(-3000, 0.05, 0), Vector3(7000, 0.1, 16), mat_asphalt)

func _road(pos: Vector3, size: Vector3, mat: Material) -> void:
	_box_mesh(pos, size, mat, roads_root)

# ═══════════════ مدينة ═══════════════
func _build_city(origin: Vector3, name: String, is_capital: bool = false) -> void:
	var size_mul := 1.35 if is_capital else 1.0
	var ground := 140.0 * size_mul
	_box_mesh(origin + Vector3(0, 0.05, 0), Vector3(ground, 0.12, ground), mat_dirt, terrain_root)
	# شبكة شوارع داخل المدينة
	_road(origin, Vector3(10, 0.08, ground * 0.85), mat_asphalt)
	_road(origin, Vector3(ground * 0.85, 0.08, 10), mat_asphalt)
	_road(origin + Vector3(35, 0, 0), Vector3(7, 0.07, ground * 0.7), mat_asphalt)
	_road(origin + Vector3(-35, 0, 0), Vector3(7, 0.07, ground * 0.7), mat_asphalt)
	_road(origin + Vector3(0, 0, 35), Vector3(ground * 0.7, 0.07, 7), mat_asphalt)
	_road(origin + Vector3(0, 0, -35), Vector3(ground * 0.7, 0.07, 7), mat_asphalt)
	
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(origin.x) * 17 + absf(origin.z) * 11) + 42
	
	# عمائر وبيوت كثيفة
	var count := 28 if is_capital else 18
	for i in range(count):
		var ox := rng.randf_range(-ground * 0.4, ground * 0.4)
		var oz := rng.randf_range(-ground * 0.4, ground * 0.4)
		if absf(ox) < 12.0 and absf(oz) < 12.0:
			continue
		var is_tower := rng.randf() > 0.65
		var h: float
		var w: float
		var d: float
		var mat: Material
		if is_tower:
			h = 14.0 + rng.randf() * 20.0
			w = 8.0 + rng.randf() * 4.0
			d = w
			mat = mat_tower
		else:
			h = 4.5 + rng.randf() * 6.0
			w = 6.0 + rng.randf() * 5.0
			d = 6.0 + rng.randf() * 5.0
			mat = [mat_house, mat_house2, mat_house3][i % 3]
		_house(origin + Vector3(ox, 0, oz), Vector3(w, h, d), mat, rng.randf() > 0.45)
	
	# ميدان / مركز
	if is_capital:
		_box_static(origin + Vector3(0, 0.6, 0), Vector3(10, 1.0, 10), mat_gold, landmarks_root, "CapitalPlaza")
		_house(origin + Vector3(0, 0, -50), Vector3(10, 40, 10), mat_gold, false)
		important_points["spawn"] = {"pos": origin + Vector3(0, 1.5, 25), "type": "spawn", "label": "الظهور"}
		important_points["plaza"] = {"pos": origin + Vector3(0, 1, 0), "type": "activity", "label": name}
	else:
		_box_mesh(origin + Vector3(0, 0.5, 0), Vector3(8, 0.6, 8), mat_sidewalk, props_root)
	
	# لافتة المدينة
	var sign := Label3D.new()
	sign.text = name
	sign.font_size = 48
	sign.modulate = Color(0.92, 0.75, 0.2)
	sign.outline_size = 8
	sign.position = origin + Vector3(0, 8, 0)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	landmarks_root.add_child(sign)
	
	var id := "city_%s" % name.hash()
	important_points[id] = {"pos": origin + Vector3(0, 1, 0), "type": "city", "label": name}

# ═══════════════ قرية ═══════════════
func _build_village(origin: Vector3, name: String) -> void:
	_box_mesh(origin + Vector3(0, 0.04, 0), Vector3(55, 0.1, 55), mat_dirt, terrain_root)
	_road(origin, Vector3(6, 0.06, 45), mat_dirt_road)
	_road(origin, Vector3(45, 0.06, 6), mat_dirt_road)
	
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(origin.x) * 9 + absf(origin.z) * 5) + 7
	
	# 5–8 بيوت قرية
	var count := 5 + rng.randi() % 4
	for i in range(count):
		var ox := rng.randf_range(-22.0, 22.0)
		var oz := rng.randf_range(-22.0, 22.0)
		if absf(ox) < 6.0 and absf(oz) < 6.0:
			ox += 10.0
		var h := 3.2 + rng.randf() * 2.5
		var w := 5.0 + rng.randf() * 3.5
		var d := 5.0 + rng.randf() * 3.5
		var mat: Material = [mat_house, mat_house2, mat_house3][i % 3]
		_house(origin + Vector3(ox, 0, oz), Vector3(w, h, d), mat, true)
	
	# بئر / مركز القرية
	var well := MeshInstance3D.new()
	var wm := CylinderMesh.new()
	wm.top_radius = 1.2
	wm.bottom_radius = 1.4
	wm.height = 1.0
	well.mesh = wm
	well.material_override = mat_warehouse
	well.position = origin + Vector3(0, 0.5, 0)
	props_root.add_child(well)
	
	var sign := Label3D.new()
	sign.text = name
	sign.font_size = 32
	sign.modulate = Color(0.85, 0.8, 0.5)
	sign.outline_size = 6
	sign.position = origin + Vector3(0, 5, 0)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	landmarks_root.add_child(sign)
	
	var id := "village_%s" % name.hash()
	important_points[id] = {"pos": origin + Vector3(0, 1, 0), "type": "village", "label": name}

func _house(pos: Vector3, size: Vector3, mat: Material, red_roof: bool) -> void:
	var body := StaticBody3D.new()
	body.position = pos + Vector3(0, size.y * 0.5, 0)
	body.collision_layer = 1
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat
	body.add_child(mi)
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	col.shape = sh
	body.add_child(col)
	var roof := MeshInstance3D.new()
	var rm := BoxMesh.new()
	rm.size = Vector3(size.x + 0.4, 0.35, size.z + 0.4)
	roof.mesh = rm
	roof.position = Vector3(0, size.y * 0.5 + 0.15, 0)
	roof.material_override = mat_roof_red if red_roof else mat_roof
	body.add_child(roof)
	var door := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(1.2, minf(2.0, size.y * 0.5), 0.12)
	door.mesh = dm
	door.material_override = mat_dirt_road
	door.position = Vector3(0, -size.y * 0.5 + 1.0, size.z * 0.5 + 0.05)
	body.add_child(door)
	if size.y > 5.0:
		var win := MeshInstance3D.new()
		var wmesh := BoxMesh.new()
		wmesh.size = Vector3(size.x * 0.35, 1.0, 0.1)
		win.mesh = wmesh
		var wmat := StandardMaterial3D.new()
		wmat.albedo_color = Color(0.35, 0.5, 0.6)
		wmat.roughness = 0.2
		win.material_override = wmat
		win.position = Vector3(0, 0.5, size.z * 0.5 + 0.04)
		body.add_child(win)
	buildings_root.add_child(body)

func _build_garage(g: Vector3) -> void:
	_box_mesh(g + Vector3(0, 0.06, 0), Vector3(45, 0.1, 30), mat_asphalt, roads_root)
	_house(g + Vector3(0, 0, -8), Vector3(26, 10, 12), mat_warehouse, false)
	_box_mesh(g + Vector3(0, 10.5, -8), Vector3(12, 0.5, 0.4), mat_gold, props_root)
	important_points["garage"] = {"pos": g + Vector3(0, 1, 0), "type": "garage", "label": "الجراج"}

func _remote_landmarks() -> void:
	for pos in [
		Vector3(25000, 0, 25000), Vector3(-25000, 0, 20000),
		Vector3(30000, 0, -25000), Vector3(-30000, 0, -20000),
		Vector3(50000, 0, 0), Vector3(-50000, 0, 0),
		Vector3(0, 0, 50000), Vector3(0, 0, -50000)
	]:
		_box_static(pos + Vector3(0, -1, 0), Vector3(3000, 1.5, 3000), mat_sand, terrain_root)
		_house(pos, Vector3(25, 45, 25), mat_gold, false)

func _build_road_lights() -> void:
	for z in range(-800, 801, 55):
		_street_light(Vector3(10.0, 0, float(z)))
		_street_light(Vector3(-10.0, 0, float(z)))
	for x in range(-800, 801, 55):
		_street_light(Vector3(float(x), 0, 10.0))
		_street_light(Vector3(float(x), 0, -10.0))

func _street_light(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	var pole := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.07
	pm.bottom_radius = 0.1
	pm.height = 6.5
	pole.mesh = pm
	pole.position.y = 3.25
	pole.material_override = mat_pole
	root.add_child(pole)
	var bulb := MeshInstance3D.new()
	bulb.name = "Bulb"
	var bm := SphereMesh.new()
	bm.radius = 0.22
	bm.height = 0.35
	bulb.mesh = bm
	bulb.position.y = 6.6
	bulb.material_override = mat_bulb.duplicate()
	root.add_child(bulb)
	var light := OmniLight3D.new()
	light.name = "OmniLight3D"
	light.position.y = 6.4
	light.light_color = Color(1.0, 0.9, 0.65)
	light.light_energy = 2.0
	light.omni_range = 18.0
	light.shadow_enabled = false
	light.visible = false
	root.add_child(light)
	lights_root.add_child(root)

func _build_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 101
	for i in range(90):
		var tx := rng.randf_range(-1200.0, 1200.0)
		var tz := rng.randf_range(-1200.0, 1200.0)
		if absf(tx) < 18.0 or absf(tz) < 18.0:
			continue
		_tree(Vector3(tx, 0, tz))

func _tree(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	var trunk := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.12
	tm.bottom_radius = 0.18
	tm.height = 2.4
	trunk.mesh = tm
	trunk.position.y = 1.2
	trunk.material_override = mat_pole
	root.add_child(trunk)
	var leaf := MeshInstance3D.new()
	var lm := SphereMesh.new()
	lm.radius = 1.3
	lm.height = 2.0
	leaf.mesh = lm
	leaf.position.y = 3.0
	leaf.material_override = mat_tree
	root.add_child(leaf)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var col := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.3
	sh.height = 2.4
	col.shape = sh
	col.position.y = 1.2
	body.add_child(col)
	root.add_child(body)
	props_root.add_child(root)

func _build_world_bounds() -> void:
	var h := 80.0
	var t := 30.0
	var edge := HALF - 20.0
	_box_static(Vector3(0, h * 0.5, -edge), Vector3(WORLD_SIZE, h, t), mat_wall, bounds_root)
	_box_static(Vector3(0, h * 0.5, edge), Vector3(WORLD_SIZE, h, t), mat_wall, bounds_root)
	_box_static(Vector3(-edge, h * 0.5, 0), Vector3(t, h, WORLD_SIZE), mat_wall, bounds_root)
	_box_static(Vector3(edge, h * 0.5, 0), Vector3(t, h, WORLD_SIZE), mat_wall, bounds_root)
	_box_static(Vector3(0, -20, 0), Vector3(120000, 3, 120000), mat_sand, bounds_root)

func _register_markers() -> void:
	important_points["mission_spot_1"] = {"pos": Vector3(50, 1, 60), "type": "mission", "label": "نقطة مهمة"}
	important_points["race_start"] = {"pos": Vector3(-70, 1, 0), "type": "race", "label": "سباق"}
	if not important_points.has("spawn"):
		important_points["spawn"] = {"pos": Vector3(0, 1.5, 25), "type": "spawn", "label": "الظهور"}

func _box_mesh(pos: Vector3, size: Vector3, mat: Material, parent: Node) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi

func _box_static(pos: Vector3, size: Vector3, mat: Material, parent: Node, node_name: String = "") -> StaticBody3D:
	var body := StaticBody3D.new()
	if node_name != "":
		body.name = node_name
	body.position = pos
	body.collision_layer = 1
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat
	body.add_child(mi)
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	col.shape = sh
	body.add_child(col)
	parent.add_child(body)
	return body
