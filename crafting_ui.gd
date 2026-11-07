extends Panel
class_name CraftingUI

signal crafted(id: int, count: int)

var is_3x3 := false
var grid_btns: Array = []
var grid_ids: Array = []
var result_btn: Button
var inv_ref: Node = null

func setup(table_3x3: bool, inventory) -> void:
	is_3x3 = table_3x3
	inv_ref = inventory
	_build()

func _build() -> void:
	for c in get_children():
		c.queue_free()
	grid_btns.clear()
	grid_ids.clear()
	var n = 9 if is_3x3 else 4
	var cols = 3 if is_3x3 else 2
	var v = VBoxContainer.new()
	add_child(v)
	var title = Label.new()
	title.text = "Crafting 3x3 (Table)" if is_3x3 else "Crafting 2x2"
	v.add_child(title)
	var grid = GridContainer.new()
	grid.columns = cols
	v.add_child(grid)
	for i in range(n):
		grid_ids.append(-1)
		var b = Button.new()
		b.custom_minimum_size = Vector2(48, 48)
		b.text = ""
		var idx = i
		b.pressed.connect(func(): _on_cell(idx))
		grid.add_child(b)
		grid_btns.append(b)
	result_btn = Button.new()
	result_btn.text = "Result"
	result_btn.custom_minimum_size = Vector2(64, 48)
	result_btn.pressed.connect(_craft)
	v.add_child(result_btn)
	var hint = Label.new()
	hint.text = "Tap cell = put selected hotbar item"
	hint.add_theme_font_size_override("font_size", 12)
	v.add_child(hint)

func _on_cell(idx: int) -> void:
	if not inv_ref:
		return
	var id = -1
	if inv_ref.has_method("get_selected_item"):
		id = inv_ref.get_selected_item()
	if id < 0:
		grid_ids[idx] = -1
		grid_btns[idx].text = ""
	else:
		grid_ids[idx] = id
		grid_btns[idx].text = str(id)
	_update_result_preview()

func _update_result_preview() -> void:
	var out = MaskCrafting.match_recipe(grid_ids, is_3x3)
	if out.size() >= 2:
		result_btn.text = "Craft %s x%d" % [str(out[0]), out[1]]
	else:
		result_btn.text = "No recipe"

func _craft() -> void:
	var out = MaskCrafting.match_recipe(grid_ids, is_3x3)
	if out.size() < 2:
		return
	# consume one from each filled cell via inv if possible
	if inv_ref and inv_ref.has_method("consume_selected"):
		for id in grid_ids:
			if id >= 0:
				inv_ref.consume_selected()
	emit_signal("crafted", out[0], out[1])
	# clear grid
	for i in range(grid_ids.size()):
		grid_ids[i] = -1
		grid_btns[i].text = ""
	result_btn.text = "Crafted!"
