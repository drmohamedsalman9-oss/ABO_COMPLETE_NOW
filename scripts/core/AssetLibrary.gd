extends Node
## مكتبة أصول CC0 — Kenney + KayKit (شخصيات مربوطة بهيكل)
## REALISM | أبو كردوم

const CARS := {
	"sedan": "res://assets/models/kenney/cars/sedan.glb",
	"police": "res://assets/models/kenney/cars/police.glb",
	"suv": "res://assets/models/kenney/cars/suv.glb",
	"taxi": "res://assets/models/kenney/cars/taxi.glb",
	"sports": "res://assets/models/kenney/cars/hatchback-sports.glb",
	"van": "res://assets/models/kenney/cars/van.glb",
}

# KayKit — rigged + animations داخل GLB
const RIGGED_CHARS := {
	"knight": "res://assets/models/kaykit/chars/Knight.glb",
	"rogue": "res://assets/models/kaykit/chars/Rogue.glb",
	"barbarian": "res://assets/models/kaykit/chars/Barbarian.glb",
	"mage": "res://assets/models/kaykit/chars/Mage.glb",
	"rogue_hooded": "res://assets/models/kaykit/chars/Rogue_Hooded.glb",
}

const CHARS := {
	"male_a": "res://assets/models/kenney/chars/character-male-a.glb",
	"male_b": "res://assets/models/kenney/chars/character-male-b.glb",
	"male_c": "res://assets/models/kenney/chars/character-male-c.glb",
	"female_a": "res://assets/models/kenney/chars/character-female-a.glb",
	"female_b": "res://assets/models/kenney/chars/character-female-b.glb",
}

static func instance_scene(path: String, scale: float = 1.0) -> Node3D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	var res = load(path)
	if res is PackedScene:
		var node: Node3D = res.instantiate()
		if node:
			node.scale = Vector3.ONE * scale
		return node
	return null

static func make_car(kind: String = "sedan") -> Node3D:
	var path: String = CARS.get(kind, CARS["sedan"])
	return instance_scene(path, 1.0)

static func make_rigged(kind: String = "knight") -> Node3D:
	var path: String = RIGGED_CHARS.get(kind, RIGGED_CHARS["knight"])
	# مقياس تقريبي لطول إنسان ~1.8م
	return instance_scene(path, 1.0)

static func make_character(kind: String = "male_a") -> Node3D:
	# فضّل الشخصية المربوطة إن طُلب نوع kaykit
	if RIGGED_CHARS.has(kind):
		return make_rigged(kind)
	var path: String = CHARS.get(kind, CHARS["male_a"])
	return instance_scene(path, 1.8)

static func random_civilian() -> Node3D:
	# مزيج: أحياناً kaykit stylized
	if randf() < 0.55:
		var keys: Array = RIGGED_CHARS.keys()
		return make_rigged(str(keys[randi() % keys.size()]))
	var keys2: Array = CHARS.keys()
	return make_character(str(keys2[randi() % keys2.size()]))

static func play_anim_if_any(root: Node, names: Array) -> bool:
	if root == null:
		return false
	var ap: AnimationPlayer = root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap == null:
		return false
	for n in names:
		if ap.has_animation(str(n)):
			ap.play(str(n))
			return true
	# جرّب أول أنيميشن
	var list := ap.get_animation_list()
	if list.size() > 0:
		ap.play(list[0])
		return true
	return false
