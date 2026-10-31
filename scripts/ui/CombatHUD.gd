extends CanvasLayer
## واجهة القتال — سلاح · ذخيرة · أزرار لمس
## الجزء 9

@onready var weapon_label: Label = $Root/WeaponInfo
@onready var btn_attack: Button = $Root/BtnAttack
@onready var btn_reload: Button = $Root/BtnReload
@onready var btn_switch: Button = $Root/BtnSwitch

var combat: Node = null
var weapons: Node = null

func _ready() -> void:
	layer = 13
	btn_attack.pressed.connect(_on_attack)
	btn_reload.pressed.connect(_on_reload)
	btn_switch.pressed.connect(_on_switch)
	# إخفاء أثناء القيادة يُدار خارجياً

func setup(p_combat: Node, p_weapons: Node) -> void:
	combat = p_combat
	weapons = p_weapons
	if weapons:
		if weapons.has_signal("weapon_changed"):
			weapons.weapon_changed.connect(func(_id): _refresh())
		if weapons.has_signal("ammo_changed"):
			weapons.ammo_changed.connect(func(_a, _b): _refresh())
		if weapons.has_signal("reloading"):
			weapons.reloading.connect(func(active):
				btn_reload.disabled = active
				if active:
					weapon_label.text = "جاري التعبئة..."
				else:
					_refresh()
			)
	_refresh()

func _refresh() -> void:
	if weapons == null:
		return
	var def: Dictionary = weapons.get_current_def() if weapons.has_method("get_current_def") else {}
	var name := str(def.get("name", "—"))
	var ammo_txt := weapons.get_display_ammo() if weapons.has_method("get_display_ammo") else ""
	weapon_label.text = "%s\n%s" % [name, ammo_txt]

func _on_attack() -> void:
	if combat and combat.has_method("try_attack"):
		combat.try_attack()

func _on_reload() -> void:
	if combat and combat.has_method("try_reload"):
		combat.try_reload()

func _on_switch() -> void:
	if combat and combat.has_method("cycle_weapon"):
		combat.cycle_weapon()
	_refresh()

func set_combat_visible(v: bool) -> void:
	visible = v
