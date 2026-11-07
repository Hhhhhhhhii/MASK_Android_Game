extends CanvasLayer
class_name InventoryUI

signal selection_changed(slot: int)
signal offhand_changed
signal closed

const HOTBAR_SIZE := 9
const BAG_SIZE := 27

var open := false
# Each slot: { "id": int, "count": int } or empty { "id": -1, "count": 0 }
var hotbar: Array = []
var bag: Array = []
var armor: Array = []  # 4 slots same structure
var offhand: Dictionary = {"id": -1, "count": 0}
var main_hand_slot := 0

var drag_from := ""
var drag_index := -1
var drag_payload: Dictionary = {}

var root_panel: Control
var hotbar_row: HBoxContainer
var bag_grid: GridContainer
var offhand_btn: Button
var main_hand_label: Label
var offhand_label: Label
var armor_label: Label
var slot_buttons := {}

func _ready() -> void:
	layer = 15
	visible = true
	_init_arrays()
	_build()

func _empty() -> Dictionary:
	return {"id": -1, "count": 0}

func _init_arrays() -> void:
	hotbar.clear()
	bag.clear()
	armor.clear()
	for i in range(HOTBAR_SIZE):
		hotbar.append(_empty())
	for i in range(BAG_SIZE):
		bag.append(_empty())
	for i in range(4):
		armor.append(_empty())
	offhand = _empty()

func _name_for(id: int) -> String:
	if id < 0:
		return ""
	var map = {
		1: "Soil", 2: "Verdant", 3: "Stone", 4: "Crystal", 5: "Timber",
		6: "Deep", 8: "Sand", 9: "Snow", 10: "Ice", 11: "Moss",
		12: "Basalt", 13: "Clay", 14: "Portal", 15: "Coal", 16: "Copper",
		17: "Iron", 18: "Gold", 19: "Diamond", 20: "FlowerR", 21: "FlowerB",
		22: "FlowerY", 23: "FlowerP", 100: "Torch",
		101: "Wood Helm", 102: "Wood Chest", 103: "Wood Legs", 104: "Wood Boots",
		201: "Copper Helm", 202: "Copper Chest", 203: "Copper Legs", 204: "Copper Boots",
		301: "Iron Helm", 302: "Iron Chest", 303: "Iron Legs", 304: "Iron Boots",
		401: "Gold Helm", 402: "Gold Chest", 403: "Gold Legs", 404: "Gold Boots",
		501: "Diamond Helm", 502: "Diamond Chest", 503: "Diamond Legs", 504: "Diamond Boots",
		601: "Crystal Helm", 602: "Crystal Chest", 603: "Crystal Legs", 604: "Crystal Boots",
		701: "Core Helm", 702: "Core Chest", 703: "Core Legs", 704: "Core Boots",
		110: "Wood Sword", 111: "Stone Sword", 112: "Iron Sword", 113: "Gold Sword",
		114: "Diamond Sword", 115: "Spear", 116: "Battle Axe", 117: "War Hammer",
		118: "Dagger", 119: "Crystal Blade", 800: "STEM", 801: "Craft Table"
	}
	return map.get(id, str(id))

func _build() -> void:
	var hotbar_panel = PanelContainer.new()
	hotbar_panel.anchor_left = 0.15
	hotbar_panel.anchor_right = 0.85
	hotbar_panel.anchor_top = 0.88
	hotbar_panel.anchor_bottom = 0.98
	add_child(hotbar_panel)
	hotbar_row = HBoxContainer.new()
	hotbar_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hotbar_panel.add_child(hotbar_row)
	for i in range(HOTBAR_SIZE):
		var b = _make_slot_button(Vector2(54, 54))
		var idx = i
		b.pressed.connect(func(): _on_hotbar_pressed(idx))
		b.button_down.connect(func(): _start_drag("hotbar", idx))
		hotbar_row.add_child(b)
		slot_buttons["hotbar_%d" % i] = b

	main_hand_label = Label.new()
	main_hand_label.position = Vector2(16, 620)
	main_hand_label.add_theme_font_size_override("font_size", 14)
	add_child(main_hand_label)
	offhand_label = Label.new()
	offhand_label.position = Vector2(16, 640)
	offhand_label.add_theme_font_size_override("font_size", 14)
	add_child(offhand_label)
	armor_label = Label.new()
	armor_label.position = Vector2(16, 660)
	armor_label.add_theme_font_size_override("font_size", 13)
	add_child(armor_label)

	root_panel = Panel.new()
	root_panel.anchor_left = 0.12
	root_panel.anchor_right = 0.88
	root_panel.anchor_top = 0.10
	root_panel.anchor_bottom = 0.82
	root_panel.visible = false
	add_child(root_panel)

	var margin = MarginContainer.new()
	margin.anchor_right = 1
	margin.anchor_bottom = 1
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	root_panel.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	margin.add_child(hbox)

	var armor_col = VBoxContainer.new()
	var at = Label.new()
	at.text = "Armor"
	armor_col.add_child(at)
	for i in range(4):
		var b = _make_slot_button(Vector2(56, 56))
		var idx = i
		b.button_down.connect(func(): _start_drag("armor", idx))
		b.pressed.connect(func(): _on_armor_pressed(idx))
		armor_col.add_child(b)
		slot_buttons["armor_%d" % i] = b
	hbox.add_child(armor_col)

	var bag_v = VBoxContainer.new()
	bag_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bt = Label.new()
	bt.text = "Inventory (stacks)"
	bag_v.add_child(bt)
	bag_grid = GridContainer.new()
	bag_grid.columns = 9
	bag_v.add_child(bag_grid)
	for i in range(BAG_SIZE):
		var b = _make_slot_button(Vector2(48, 48))
		var idx = i
		b.button_down.connect(func(): _start_drag("bag", idx))
		b.pressed.connect(func(): _on_bag_pressed(idx))
		bag_grid.add_child(b)
		slot_buttons["bag_%d" % i] = b
	hbox.add_child(bag_v)

	var right = VBoxContainer.new()
	var oh = Label.new()
	oh.text = "Left Hand"
	right.add_child(oh)
	offhand_btn = _make_slot_button(Vector2(56, 56))
	offhand_btn.button_down.connect(func(): _start_drag("offhand", 0))
	offhand_btn.pressed.connect(_on_offhand_pressed)
	right.add_child(offhand_btn)
	slot_buttons["offhand"] = offhand_btn
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(toggle)
	right.add_child(close_btn)
	hbox.add_child(right)
	_refresh_all()

func _make_slot_button(minsize: Vector2) -> Button:
	var b = Button.new()
	b.custom_minimum_size = minsize
	b.clip_text = true
	return b

func toggle() -> void:
	open = not open
	root_panel.visible = open
	if open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		emit_signal("closed")
	_refresh_all()

func _get_slot(from: String, index: int) -> Dictionary:
	match from:
		"hotbar":
			return hotbar[index] if index >= 0 and index < hotbar.size() else _empty()
		"bag":
			return bag[index] if index >= 0 and index < bag.size() else _empty()
		"armor":
			return armor[index] if index >= 0 and index < armor.size() else _empty()
		"offhand":
			return offhand
	return _empty()

func _set_slot(from: String, index: int, value: Dictionary) -> void:
	match from:
		"hotbar":
			if index >= 0 and index < hotbar.size():
				hotbar[index] = value.duplicate()
		"bag":
			if index >= 0 and index < bag.size():
				bag[index] = value.duplicate()
		"armor":
			if index >= 0 and index < armor.size():
				armor[index] = value.duplicate()
		"offhand":
			offhand = value.duplicate()
			emit_signal("offhand_changed")

func _start_drag(from: String, index: int) -> void:
	drag_from = from
	drag_index = index
	drag_payload = _get_slot(from, index).duplicate()

func _swap_or_move(to: String, to_index: int) -> void:
	if drag_from == "" or drag_payload.get("id", -1) < 0:
		return
	var dest = _get_slot(to, to_index).duplicate()
	# stack if same id
	if dest.get("id", -1) == drag_payload.get("id", -2) and dest.get("id", -1) >= 0:
		dest["count"] = dest.get("count", 0) + drag_payload.get("count", 1)
		_set_slot(to, to_index, dest)
		_set_slot(drag_from, drag_index, _empty())
	else:
		_set_slot(to, to_index, drag_payload)
		_set_slot(drag_from, drag_index, dest)
	drag_from = ""
	drag_index = -1
	drag_payload = {}
	_refresh_all()
	emit_signal("selection_changed", main_hand_slot)

func _on_hotbar_pressed(idx: int) -> void:
	if drag_from != "":
		_swap_or_move("hotbar", idx)
	else:
		main_hand_slot = idx
		emit_signal("selection_changed", main_hand_slot)
		_refresh_all()

func _on_bag_pressed(idx: int) -> void:
	if drag_from != "":
		_swap_or_move("bag", idx)

func _on_armor_pressed(idx: int) -> void:
	if drag_from != "":
		_swap_or_move("armor", idx)

func _on_offhand_pressed() -> void:
	if drag_from != "":
		_swap_or_move("offhand", 0)

func add_item(id: int, count: int = 1) -> void:
	var left = count
	# stack existing
	for arr in [hotbar, bag]:
		for i in range(arr.size()):
			if left <= 0:
				break
			if arr[i].get("id", -1) == id:
				arr[i]["count"] = arr[i].get("count", 0) + left
				left = 0
		if left <= 0:
			break
	# empty slots
	if left > 0:
		for arr in [hotbar, bag]:
			for i in range(arr.size()):
				if left <= 0:
					break
				if arr[i].get("id", -1) < 0:
					arr[i] = {"id": id, "count": left}
					left = 0
			if left <= 0:
				break
	_refresh_all()

func get_selected_item() -> int:
	if main_hand_slot >= 0 and main_hand_slot < hotbar.size():
		return hotbar[main_hand_slot].get("id", -1)
	return -1

func consume_selected() -> void:
	if main_hand_slot >= 0 and main_hand_slot < hotbar.size():
		var s = hotbar[main_hand_slot]
		if s.get("count", 0) > 1:
			s["count"] -= 1
		else:
			hotbar[main_hand_slot] = _empty()
		_refresh_all()

func get_armor_reduction() -> float:
	# Quality-based DR per piece (wood → core)
	var total := 0.0
	for a in armor:
		var id = a.get("id", -1)
		if id < 0:
			continue
		var tier = id / 100  # 1=wood, 2=copper, 3=iron, 4=gold, 5=diamond, 6=crystal, 7=core
		match tier:
			1: total += 0.04   # wood
			2: total += 0.07   # copper
			3: total += 0.10   # iron
			4: total += 0.08   # gold (weaker than iron)
			5: total += 0.13   # diamond
			6: total += 0.15   # crystal
			7: total += 0.18   # core — hardest / most resilient
			_: total += 0.05
	return clampf(total, 0.0, 0.72)  # cap 72%

func _refresh_all() -> void:
	for i in range(HOTBAR_SIZE):
		var b: Button = slot_buttons.get("hotbar_%d" % i)
		if b:
			var s = hotbar[i]
			var id = s.get("id", -1)
			var c = s.get("count", 0)
			b.text = ("%s\nx%d" % [_name_for(id), c]) if id >= 0 else ""
			b.modulate = Color(1.25, 1.2, 0.7) if i == main_hand_slot else Color.WHITE
	for i in range(BAG_SIZE):
		var b2: Button = slot_buttons.get("bag_%d" % i)
		if b2:
			var s2 = bag[i]
			var id2 = s2.get("id", -1)
			b2.text = ("%s\nx%d" % [_name_for(id2), s2.get("count", 0)]) if id2 >= 0 else ""
	var anames = ["Head", "Chest", "Legs", "Feet"]
	for i in range(4):
		var b3: Button = slot_buttons.get("armor_%d" % i)
		if b3:
			var s3 = armor[i]
			var id3 = s3.get("id", -1)
			b3.text = _name_for(id3) if id3 >= 0 else anames[i]
	if offhand_btn:
		var oid = offhand.get("id", -1)
		offhand_btn.text = ("%s x%d" % [_name_for(oid), offhand.get("count", 0)]) if oid >= 0 else "Offhand"
	_update_hand_labels()

func _update_hand_labels() -> void:
	var main_id = get_selected_item()
	var mc = 0
	if main_hand_slot >= 0 and main_hand_slot < hotbar.size():
		mc = hotbar[main_hand_slot].get("count", 0)
	if main_hand_label:
		main_hand_label.text = "Right hand: %s%s" % [
			_name_for(main_id) if main_id >= 0 else "empty",
			(" x%d" % mc) if main_id >= 0 else ""
		]
	if offhand_label:
		var oid = offhand.get("id", -1)
		offhand_label.text = "Left hand: %s%s" % [
			_name_for(oid) if oid >= 0 else "empty",
			(" x%d" % offhand.get("count", 0)) if oid >= 0 else ""
		]
	if armor_label:
		armor_label.text = "Armor DR: %d%%" % int(get_armor_reduction() * 100)

func give_starter(creative: bool) -> void:
	_init_arrays()
	if creative:
		var ids = [1, 2, 3, 110, 112, 114, 115, 116, 15, 19, 14, 100]
		for i in range(mini(ids.size(), HOTBAR_SIZE)):
			hotbar[i] = {"id": ids[i], "count": 64}
		offhand = {"id": 100, "count": 16}
		armor = [
			{"id": 701, "count": 1},
			{"id": 702, "count": 1},
			{"id": 703, "count": 1},
			{"id": 704, "count": 1}
		]
		# also put extra sets in bag
		add_item(101, 1); add_item(102, 1); add_item(103, 1); add_item(104, 1)
		add_item(301, 1); add_item(302, 1); add_item(303, 1); add_item(304, 1)
		add_item(501, 1); add_item(502, 1); add_item(503, 1); add_item(504, 1)
		add_item(800, 2)
		add_item(801, 4)
	else:
		hotbar[0] = {"id": 1, "count": 16}
		hotbar[1] = {"id": 3, "count": 8}
		hotbar[2] = {"id": 5, "count": 8}
		hotbar[3] = {"id": 110, "count": 1}
		hotbar[4] = {"id": 100, "count": 4}
		offhand = {"id": 100, "count": 4}
		armor = [
			{"id": 101, "count": 1},
			{"id": 102, "count": 1},
			{"id": 103, "count": 1},
			{"id": 104, "count": 1}
		]
	_refresh_all()
