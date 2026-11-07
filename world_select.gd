extends CanvasLayer
class_name WorldSelect

signal start_game(seed: int, wname: String, creative: bool)

var world_manager: Node
var list_container: VBoxContainer
var name_edit: LineEdit
var creative_check: CheckBox

func _ready() -> void:
	layer = 30
	_build_ui()

func setup(wm: Node) -> void:
	world_manager = wm
	_refresh_list()

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.09, 0.12, 0.95)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	var center = CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 480)
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "MASK — Select World"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(480, 220)
	vbox.add_child(scroll)

	list_container = VBoxContainer.new()
	list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list_container)

	# Create new world section
	var sep = HSeparator.new()
	vbox.add_child(sep)

	var create_label = Label.new()
	create_label.text = "Create New World"
	create_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(create_label)

	name_edit = LineEdit.new()
	name_edit.placeholder_text = "World name..."
	name_edit.text = "New World"
	vbox.add_child(name_edit)

	creative_check = CheckBox.new()
	creative_check.text = "Creative Mode (unlimited blocks, no damage, flight)"
	vbox.add_child(creative_check)

	var create_btn = Button.new()
	create_btn.text = "CREATE RANDOM WORLD"
	create_btn.pressed.connect(_on_create)
	vbox.add_child(create_btn)

func _refresh_list() -> void:
	for c in list_container.get_children():
		c.queue_free()
	if not world_manager:
		return
	var worlds = world_manager.get_world_list()
	for i in range(worlds.size()):
		var w = worlds[i]
		var hbox = HBoxContainer.new()
		var info = Label.new()
		var mode = "Creative" if w.creative else "Survival"
		info.text = "%s  |  Seed %d  |  %s" % [w.name, w.seed, mode]
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info)

		var play_btn = Button.new()
		play_btn.text = "PLAY"
		var idx = i
		play_btn.pressed.connect(func():
			_on_play(idx)
		)
		hbox.add_child(play_btn)
		list_container.add_child(hbox)

func _on_create() -> void:
	if not world_manager:
		return
	var entry = world_manager.create_random_world(name_edit.text.strip_edges(), creative_check.button_pressed)
	_refresh_list()
	# Auto start the new world
	emit_signal("start_game", entry.seed, entry.name, entry.creative)

func _on_play(index: int) -> void:
	if not world_manager:
		return
	world_manager.select_world(index)
	var w = world_manager.worlds[index]
	emit_signal("start_game", w.seed, w.name, w.creative)
