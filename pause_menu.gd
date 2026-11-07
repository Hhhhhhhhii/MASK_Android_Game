extends CanvasLayer
class_name PauseMenu

signal resume_pressed
signal open_settings
signal save_pressed
signal quit_pressed

var open := false
var panel: Panel

func _ready() -> void:
	layer = 40
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()

func _build() -> void:
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.anchor_right = 1
	dim.anchor_bottom = 1
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			pass
	)
	add_child(dim)

	panel = Panel.new()
	panel.anchor_left = 0.3
	panel.anchor_right = 0.7
	panel.anchor_top = 0.22
	panel.anchor_bottom = 0.78
	add_child(panel)

	var v = VBoxContainer.new()
	v.anchor_right = 1
	v.anchor_bottom = 1
	v.offset_left = 24
	v.offset_right = -24
	v.offset_top = 20
	v.offset_bottom = -20
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)

	var title = Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	v.add_child(title)

	var b_resume = Button.new()
	b_resume.text = "Resume"
	b_resume.pressed.connect(func():
		toggle()
		emit_signal("resume_pressed")
	)
	v.add_child(b_resume)

	var b_set = Button.new()
	b_set.text = "Settings"
	b_set.pressed.connect(func(): emit_signal("open_settings"))
	v.add_child(b_set)

	var b_save = Button.new()
	b_save.text = "Save World List"
	b_save.pressed.connect(func(): emit_signal("save_pressed"))
	v.add_child(b_save)

	var b_quit = Button.new()
	b_quit.text = "Quit to World Select"
	b_quit.pressed.connect(func(): emit_signal("quit_pressed"))
	v.add_child(b_quit)

func toggle() -> void:
	open = not open
	visible = open
	get_tree().paused = open
	if open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
