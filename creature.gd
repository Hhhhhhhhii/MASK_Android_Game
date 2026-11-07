extends CharacterBody3D
class_name MaskCreature

enum Kind { WANDERER, HOPPER, SLITHER, FLUTTER }

@export var kind: Kind = Kind.WANDERER
var move_speed := 2.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var dir := Vector3.ZERO
var timer := 0.0
var mesh_inst: MeshInstance3D
var hop_cooldown := 0.0

func _ready() -> void:
	match kind:
		Kind.WANDERER:
			move_speed = 2.1
		Kind.HOPPER:
			move_speed = 1.6
		Kind.SLITHER:
			move_speed = 2.8
		Kind.FLUTTER:
			move_speed = 3.2
	_build_visual()
	_pick_new_dir()

func _build_visual() -> void:
	mesh_inst = MeshInstance3D.new()
	var mat = StandardMaterial3D.new()
	mat.roughness = 0.65

	match kind:
		Kind.WANDERER:
			var s = SphereMesh.new()
			s.radius = 0.32
			s.height = 0.64
			mesh_inst.mesh = s
			mat.albedo_color = Color(0.55, 0.42, 0.28)
		Kind.HOPPER:
			var s = SphereMesh.new()
			s.radius = 0.28
			s.height = 0.45
			mesh_inst.mesh = s
			mat.albedo_color = Color(0.25, 0.55, 0.22)
		Kind.SLITHER:
			var c = CapsuleMesh.new()
			c.radius = 0.12
			c.height = 0.7
			mesh_inst.mesh = c
			mat.albedo_color = Color(0.35, 0.55, 0.30)
			mesh_inst.rotation_degrees.x = 90
		Kind.FLUTTER:
			var s = SphereMesh.new()
			s.radius = 0.18
			s.height = 0.25
			mesh_inst.mesh = s
			mat.albedo_color = Color(0.85, 0.75, 0.25)

	mesh_inst.material_override = mat
	mesh_inst.position.y = 0.3
	add_child(mesh_inst)

	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.3
	col.shape = shape
	col.position.y = 0.3
	add_child(col)

func _pick_new_dir() -> void:
	dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	timer = randf_range(1.2, 3.8)

func _physics_process(delta: float) -> void:
	if not is_on_floor() and kind != Kind.FLUTTER:
		velocity.y -= gravity * delta

	timer -= delta
	if timer <= 0.0:
		_pick_new_dir()

	if kind == Kind.HOPPER:
		hop_cooldown -= delta
		if hop_cooldown <= 0.0 and is_on_floor() and randf() < 0.02:
			velocity.y = 5.5
			hop_cooldown = 1.2

	if kind == Kind.FLUTTER:
		velocity.y = sin(Time.get_ticks_msec() * 0.005 + float(get_instance_id())) * 1.8
		position.y = clamp(position.y, 2.0, 22.0)

	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	move_and_slide()

	if dir.length() > 0.1 and kind != Kind.FLUTTER:
		var look_target = global_position + dir
		look_target.y = global_position.y
		if look_target.distance_to(global_position) > 0.1:
			look_at(look_target, Vector3.UP)
