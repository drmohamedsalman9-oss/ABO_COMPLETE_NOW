extends CanvasLayer
## واجهة الاقتصاد — متاجر · ممتلكات · رصيد
## الجزء 10

@onready var panel: Panel = $Panel
@onready var bal_label: Label = $Panel/VBox/Balance
@onready var tab_weapons: Button = $Panel/VBox/Tabs/BtnWeapons
@onready var tab_vehicles: Button = $Panel/VBox/Tabs/BtnVehicles
@onready var tab_props: Button = $Panel/VBox/Tabs/BtnProps
@onready var tab_owned: Button = $Panel/VBox/Tabs/BtnOwned
@onready var list: VBoxContainer = $Panel/VBox/Scroll/List
@onready var status: Label = $Panel/VBox/Status
@onready var btn_close: Button = $Panel/VBox/BtnClose
@onready var btn_open: Button = $OpenBtn

var eco: Node = null
var _tab: String = "weapons"
var _busy: bool = false

func _ready() -> void:
	layer = 18
	panel.visible = false
	btn_close.pressed.connect(func(): panel.visible = false)
	btn_open.pressed.connect(toggle)
	tab_weapons.pressed.connect(func(): _set_tab("weapons"))
	tab_vehicles.pressed.connect(func(): _set_tab("vehicles"))
	tab_props.pressed.connect(func(): _set_tab("properties"))
	tab_owned.pressed.connect(func(): _set_tab("owned"))
	eco = get_node_or_null("/root/EconomyManager")
	if eco and eco.has_signal("balance_changed"):
		eco.balance_changed.connect(func(b): bal_label.text = "💰 %d كردوم" % b)
	if eco and eco.has_signal("purchase_failed"):
		eco.purchase_failed.connect(func(r): status.text = r)
	if eco and eco.has_signal("purchase_succeeded"):
		eco.purchase_succeeded.connect(func(id, cat):
			status.text = "تم الشراء ✓"
			_refresh()
		)

func toggle() -> void:
	panel.visible = not panel.visible
	if panel.visible:
		_refresh()

func _set_tab(t: String) -> void:
	_tab = t
	_refresh()

func _refresh() -> void:
	if eco == null:
		eco = get_node_or_null("/root/EconomyManager")
	if eco == null:
		return
	bal_label.text = "💰 %d كردوم" % eco.get_balance()
	for c in list.get_children():
		c.queue_free()
	if _tab == "owned":
		_fill_owned()
		return
	var items: Array = eco.get_catalog(_tab)
	for it in items:
		_add_item_row(it, _tab)

func _add_item_row(it: Dictionary, category: String) -> void:
	var id := str(it.get("id", ""))
	var owned := false
	if category == "weapons":
		owned = eco.owns_weapon(id)
	elif category == "vehicles":
		owned = eco.owns_vehicle(id)
	elif category == "properties":
		owned = eco.owns_property(id)
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.text = "%s — %d 💰\n%s" % [str(it.get("name", id)), int(it.get("price", 0)), str(it.get("desc", ""))]
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	row.add_child(lbl)
	var btn := Button.new()
	if owned:
		btn.text = "مملوك"
		btn.disabled = true
	else:
		btn.text = "شراء"
		var cid := id
		var cat := category
		btn.pressed.connect(func(): _buy(cid, cat))
	row.add_child(btn)
	list.add_child(row)

func _fill_owned() -> void:
	var lines: Array = []
	lines.append("أسلحة: " + (", ".join(eco.owned_weapons) if eco.owned_weapons.size() else "لا يوجد"))
	lines.append("مركبات: " + (", ".join(eco.owned_vehicles) if eco.owned_vehicles.size() else "لا يوجد"))
	lines.append("عقارات: " + (", ".join(eco.owned_properties) if eco.owned_properties.size() else "لا يوجد"))
	# آخر معاملات
	lines.append("--- آخر عمليات ---")
	for t in eco.transactions.slice(0, mini(5, eco.transactions.size())):
		lines.append("%s %d — %s" % [str(t.get("kind")), int(t.get("amount")), str(t.get("reason", ""))])
	for line in lines:
		var l := Label.new()
		l.text = line
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		list.add_child(l)

func _buy(item_id: String, category: String) -> void:
	if _busy or eco == null:
		return
	_busy = true
	var ok := false
	match category:
		"weapons":
			ok = eco.buy_weapon(item_id)
		"vehicles":
			ok = eco.buy_vehicle(item_id)
		"properties":
			ok = eco.buy_property(item_id)
	_busy = false
	if ok:
		status.text = "تم الشراء ✓"
	_refresh()
