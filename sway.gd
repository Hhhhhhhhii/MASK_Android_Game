extends Node3D
# Gentle breathe / wind sway for leaves, plants, flowers

@export var amount := 0.08
@export var speed := 1.6
var base: Vector3
var phase := 0.0

func _ready() -> void:
	base = rotation_degrees
	phase = randf() * TAU

func _process(delta: float) -> void:
	phase += delta * speed
	rotation_degrees.z = base.z + sin(phase) * amount * 57.0
	rotation_degrees.x = base.x + cos(phase * 0.7) * amount * 0.5 * 57.0
	# subtle scale breathe
	var s = 1.0 + sin(phase * 0.5) * 0.03
	scale = Vector3(s, 1.0 + sin(phase * 0.4) * 0.04, s)
