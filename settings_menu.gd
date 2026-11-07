extends CanvasLayer
class_name SettingsMenu

signal settings_changed

var look_sensitivity := 0.0028
var joystick_scale := 1.0
var render_scale := 1.0
var shadows_enabled := true
var show_fps := false

var panel: Panel
var open := false

func _ready() -> void:
	layer = 20
	visible = false
	_build_ui()

func _build_ui() -> void:
	panel = Panel.new()
	panel.anchor_left = 0.2
	panel.anchor_right = 0.8
	panel.anchor_top = 0.12
	panel.anchor_bottom = 0.88
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 20
	vbox.offset_right = -20
	vbox.offset_top = 16
	vbox.offset_bottom = -16
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "MASK SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	vbox.add_child(_spacer(12))

	# Look sensitivity
	vbox.add_child(_label("Look Sensitivity"))
	var sens = HSlider.new()
	sens.min_value = 0.001
	sens.max_value = 0.006
	sens.step = 0.0002
	sens.value = look_sensitivity
	sens.value_changed.connect(func(v):
		look_sensitivity = v
		settings_changed.emit()
	)
	vbox.add_child(sens)

	vbox.add_child(_spacer(8))

	# Joystick scale
	vbox.add_child(_label("Joystick / D-Pad Scale"))
	var jscale = HSlider.new()
	jscale.min_value = 0.6
	jscale.max_value = 1.8
	jscale.step = 0.05
	jscale.value = joystick_scale
	jscale.value_changed.connect(func(v):
		joystick_scale = v
		settings_changed.emit()
	)
	vbox.add_child(jscale)

	vbox.add_child(_spacer(8))

	# Render scale (performance)
	vbox.add_child(_label("Render Scale (Performance)"))
	var rscale = HSlider.new()
	rscale.min_value = 0.5
	rscale.max_value = 1.0
	rscale.step = 0.05
	rscale.value = render_scale
	rscale.value_changed.connect(func(v):
		render_scale = v
		get_viewport().scaling_3d_scale = v
		settings_changed.emit()
	)
	vbox.add_child(rscale)

	vbox.add_child(_spacer(8))

	# Shadows toggle
	var shadow_btn = CheckButton.new()
	shadow_btn.text = "Shadows"
	shadow_btn.button_pressed = shadows_enabled
	shadow_btn.toggled.connect(func(on):
		shadows_enabled = on
		# Find directional lights and toggle
		var root = get_tree().current_scene
		if root:
			for n in root.get_children():
				if n is DirectionalLight3D:
					n.shadow_enabled = on
		settings_changed.emit()
	)
	vbox.add_child(shadow_btn)

	vbox.add_child(_spacer(8))

	# FPS counter
	var fps_btn = CheckButton.new()
	fps_btn.text = "Show FPS"
	fps_btn.button_pressed = show_fps
	fps_btn.toggled.connect(func(on):
		show_fps = on
		settings_changed.emit()
	)
	vbox.add_child(fps_btn)

	vbox.add_child(_spacer(16))

	var close_btn = Button.new()
	close_btn.text = "CLOSE SETTINGS"
	close_btn.pressed.connect(toggle)
	vbox.add_child(close_btn)

func _label(text: String) -> Label:
	var l = Label.new()
	l.text = text
	return l

func _spacer(h: float) -> Control:
	var c = Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

func toggle() -> void:
	open = not open
	visible = open
	if open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
