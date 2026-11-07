extends Control
class_name VirtualJoystick

# Simple scalable virtual joystick for MASK Android

signal joystick_moved(direction: Vector2)

@export var base_radius := 80.0
@export var stick_radius := 35.0
@export var deadzone := 0.12
@export var scale_factor := 1.0

var touching := false
var touch_index := -1
var center := Vector2.ZERO
var current_dir := Vector2.ZERO

var base_draw: ColorRect
var stick_draw: ColorRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rebuild()

func set_scale_factor(s: float) -> void:
	scale_factor = clampf(s, 0.6, 1.8)
	_rebuild()

func _rebuild() -> void:
	# Clear old
	for c in get_children():
		c.queue_free()

	var br = base_radius * scale_factor
	var sr = stick_radius * scale_factor

	custom_minimum_size = Vector2(br * 2.2, br * 2.2)
	size = custom_minimum_size

	base_draw = ColorRect.new()
	base_draw.color = Color(0.15, 0.15, 0.2, 0.45)
	base_draw.size = Vector2(br * 2, br * 2)
	base_draw.position = Vector2(size.x * 0.5 - br, size.y * 0.5 - br)
	add_child(base_draw)

	stick_draw = ColorRect.new()
	stick_draw.color = Color(0.75, 0.8, 0.9, 0.75)
	stick_draw.size = Vector2(sr * 2, sr * 2)
	stick_draw.position = Vector2(size.x * 0.5 - sr, size.y * 0.5 - sr)
	add_child(stick_draw)

	center = size * 0.5

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not touching:
			touching = true
			touch_index = event.index
			_update_stick(event.position)
		elif not event.pressed and event.index == touch_index:
			touching = false
			touch_index = -1
			current_dir = Vector2.ZERO
			_reset_stick()
			joystick_moved.emit(Vector2.ZERO)
	elif event is InputEventScreenDrag and touching and event.index == touch_index:
		_update_stick(event.position)

func _update_stick(pos: Vector2) -> void:
	var br = base_radius * scale_factor
	var sr = stick_radius * scale_factor
	var offset = pos - center
	var max_len = br - sr * 0.3
	if offset.length() > max_len:
		offset = offset.normalized() * max_len
	stick_draw.position = center + offset - Vector2(sr, sr)

	var dir = offset / max_len
	if dir.length() < deadzone:
		dir = Vector2.ZERO
	current_dir = dir
	joystick_moved.emit(current_dir)

func _reset_stick() -> void:
	var sr = stick_radius * scale_factor
	stick_draw.position = center - Vector2(sr, sr)

func get_direction() -> Vector2:
	return current_dir
