extends Node
class_name DimensionManager

# Simple dimension system for MASK
# 0 = Overworld, 1 = Hell, 2 = Purgatory, 3 = Heaven

signal dimension_changed(new_dim: int)

var current_dimension := 0
var player: CharacterBody3D
var overworld: Node3D
var hell_root: Node3D
var purgatory_root: Node3D
var heaven_root: Node3D
var moon_root: Node3D

func setup(p: CharacterBody3D, ow: Node3D) -> void:
	player = p
	overworld = ow
	_build_hell()
	_build_purgatory()
	_build_heaven()
	_build_moon()

func _build_hell() -> void:
	hell_root = Node3D.new()
	hell_root.name = "Hell"
	hell_root.visible = false
	add_child(hell_root)

	# Dark red environment platform
	var floor_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(40, 2, 40)
	floor_mesh.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.05, 0.04)
	mat.roughness = 0.9
	floor_mesh.material_override = mat
	floor_mesh.position = Vector3(0, -1, 0)
	hell_root.add_child(floor_mesh)

	var body = StaticBody3D.new()
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(40, 2, 40)
	col.shape = shape
	body.add_child(col)
	body.position = Vector3(0, -1, 0)
	hell_root.add_child(body)

	# Scattered dark pillars / rocks
	var rng = RandomNumberGenerator.new()
	rng.seed = 666
	for i in range(25):
		var p = MeshInstance3D.new()
		var m = BoxMesh.new()
		m.size = Vector3(rng.randf_range(0.8, 2.2), rng.randf_range(2, 7), rng.randf_range(0.8, 2.2))
		p.mesh = m
		var pm = StandardMaterial3D.new()
		pm.albedo_color = Color(0.15 + rng.randf()*0.1, 0.03, 0.02)
		p.material_override = pm
		p.position = Vector3(rng.randf_range(-18, 18), m.size.y * 0.5, rng.randf_range(-18, 18))
		hell_root.add_child(p)

	# Simple scary entities (dark spheres that drift)
	for i in range(6):
		var e = _make_dim_entity(Color(0.4, 0.05, 0.05), 0.5)
		e.position = Vector3(rng.randf_range(-15, 15), 1.5, rng.randf_range(-15, 15))
		hell_root.add_child(e)

	# Red ambient light
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.2, 0.1)
	light.light_energy = 2.5
	light.omni_range = 50
	light.position = Vector3(0, 8, 0)
	hell_root.add_child(light)

func _build_purgatory() -> void:
	purgatory_root = Node3D.new()
	purgatory_root.name = "Purgatory"
	purgatory_root.visible = false
	add_child(purgatory_root)

	# Dark enclosed room
	var room_size = 18.0
	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.08, 0.08, 0.1)
	wall_mat.roughness = 1.0

	# Floor
	var floor = _make_box(Vector3(room_size, 1, room_size), wall_mat)
	floor.position = Vector3(0, -0.5, 0)
	purgatory_root.add_child(floor)
	_add_static(floor.position, Vector3(room_size, 1, room_size), purgatory_root)

	# Ceiling
	var ceil = _make_box(Vector3(room_size, 1, room_size), wall_mat)
	ceil.position = Vector3(0, 8, 0)
	purgatory_root.add_child(ceil)

	# Walls
	for offset in [Vector3(0, 4, -room_size/2), Vector3(0, 4, room_size/2), Vector3(-room_size/2, 4, 0), Vector3(room_size/2, 4, 0)]:
		var w = _make_box(Vector3(room_size if abs(offset.z) > 0.1 else 1, 8, room_size if abs(offset.x) > 0.1 else 1), wall_mat)
		w.position = offset
		purgatory_root.add_child(w)
		_add_static(offset, w.mesh.size if w.mesh else Vector3(1,8,1), purgatory_root)

	# Very dim lights
	var l1 = OmniLight3D.new()
	l1.light_color = Color(0.4, 0.4, 0.5)
	l1.light_energy = 0.4
	l1.omni_range = 12
	l1.position = Vector3(0, 5, 0)
	purgatory_root.add_child(l1)

	# Silent floating wisps
	for i in range(4):
		var e = _make_dim_entity(Color(0.3, 0.3, 0.4), 0.3)
		e.position = Vector3(randf_range(-6, 6), randf_range(1, 5), randf_range(-6, 6))
		purgatory_root.add_child(e)

func _build_heaven() -> void:
	heaven_root = Node3D.new()
	heaven_root.name = "Heaven"
	heaven_root.visible = false
	add_child(heaven_root)

	var cloud_mat = StandardMaterial3D.new()
	cloud_mat.albedo_color = Color(0.92, 0.95, 1.0)
	cloud_mat.roughness = 0.7

	# Floating platforms
	var rng = RandomNumberGenerator.new()
	rng.seed = 777
	for i in range(12):
		var plat = _make_box(Vector3(rng.randf_range(4, 9), 1.2, rng.randf_range(4, 9)), cloud_mat)
		plat.position = Vector3(rng.randf_range(-25, 25), rng.randf_range(0, 8), rng.randf_range(-25, 25))
		heaven_root.add_child(plat)
		_add_static(plat.position, plat.mesh.size, heaven_root)

	# Main central platform
	var main = _make_box(Vector3(16, 1.5, 16), cloud_mat)
	main.position = Vector3(0, 0, 0)
	heaven_root.add_child(main)
	_add_static(Vector3(0, 0, 0), Vector3(16, 1.5, 16), heaven_root)

	# Soft golden light
	var sun = DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.95, 0.8)
	sun.light_energy = 1.6
	sun.rotation_degrees = Vector3(-50, 30, 0)
	heaven_root.add_child(sun)

	var ambient = OmniLight3D.new()
	ambient.light_color = Color(0.8, 0.9, 1.0)
	ambient.light_energy = 1.2
	ambient.omni_range = 60
	ambient.position = Vector3(0, 15, 0)
	heaven_root.add_child(ambient)

	# Gentle floating entities
	for i in range(5):
		var e = _make_dim_entity(Color(0.9, 0.9, 0.7), 0.35)
		e.position = Vector3(rng.randf_range(-12, 12), rng.randf_range(2, 6), rng.randf_range(-12, 12))
		heaven_root.add_child(e)

func _make_box(size: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat
	return mi

func _add_static(pos: Vector3, size: Vector3, parent: Node) -> void:
	var body = StaticBody3D.new()
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	body.position = pos
	parent.add_child(body)

func _make_dim_entity(col: Color, radius: float) -> Node3D:
	var e = Node3D.new()
	var mesh = MeshInstance3D.new()
	var s = SphereMesh.new()
	s.radius = radius
	s.height = radius * 2
	mesh.mesh = s
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col * 0.4
	mesh.material_override = mat
	e.add_child(mesh)
	# simple drift script via process later if needed
	return e

var lucifer_spawned := false
var god_spawned := false


func _build_moon() -> void:
	moon_root = Node3D.new()
	moon_root.name = "Moon"
	moon_root.visible = false
	add_child(moon_root)
	# Blank grey surface — nothing else
	var floor_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(80, 2, 80)
	floor_mesh.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.55, 0.58)
	mat.roughness = 1.0
	floor_mesh.material_override = mat
	floor_mesh.position = Vector3(0, -1, 0)
	moon_root.add_child(floor_mesh)
	var body = StaticBody3D.new()
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(80, 2, 80)
	col.shape = shape
	body.add_child(col)
	body.position = Vector3(0, -1, 0)
	moon_root.add_child(body)
	# Crater nubs for slight detail but still barren
	var rng = RandomNumberGenerator.new()
	rng.seed = 13
	for i in range(20):
		var p = MeshInstance3D.new()
		var s = SphereMesh.new()
		s.radius = rng.randf_range(0.8, 3.0)
		s.height = s.radius * 0.4
		p.mesh = s
		var pm = StandardMaterial3D.new()
		pm.albedo_color = Color(0.45, 0.45, 0.48)
		p.material_override = pm
		p.position = Vector3(rng.randf_range(-35, 35), 0.1, rng.randf_range(-35, 35))
		moon_root.add_child(p)
	# Dim sun light on moon
	var light = DirectionalLight3D.new()
	light.light_energy = 0.7
	light.light_color = Color(0.9, 0.9, 1.0)
	light.rotation_degrees = Vector3(-40, 20, 0)
	moon_root.add_child(light)
	var fill = OmniLight3D.new()
	fill.light_energy = 0.3
	fill.omni_range = 60
	fill.position = Vector3(0, 20, 0)
	moon_root.add_child(fill)

func go_to_dimension(dim: int) -> void:
	if dim == current_dimension:
		return
	# Hide all
	if overworld: overworld.visible = (dim == 0)
	if hell_root: hell_root.visible = (dim == 1)
	if purgatory_root: purgatory_root.visible = (dim == 2)
	if heaven_root: heaven_root.visible = (dim == 3)

	current_dimension = dim
	# Move player to safe spawn in target dimension
	match dim:
		0:
			player.position = Vector3(0, 20, 0)
		1:
			player.position = Vector3(0, 3, 0)
			_spawn_lucifer_if_needed()
		2:
			player.position = Vector3(0, 2, 0)
		3:
			player.position = Vector3(0, 3, 0)
			_spawn_god_if_needed()
	player.velocity = Vector3.ZERO
	emit_signal("dimension_changed", dim)

func _spawn_lucifer_if_needed() -> void:
	if lucifer_spawned or not hell_root:
		return
	lucifer_spawned = true
	var boss = CharacterBody3D.new()
	boss.set_script(load("res://scripts/raid_boss.gd"))
	boss.set("raid_type", 0)  # LUCIFER
	boss.position = Vector3(8, 3, 8)
	if player and player.has_method("on_raid_defeated"):
		boss.raid_defeated.connect(player.on_raid_defeated)
	hell_root.add_child(boss)
	if player and player.get("status_label"):
		player.status_label.text = "Lucifer has awakened!"

func _spawn_god_if_needed() -> void:
	if god_spawned or not heaven_root:
		return
	god_spawned = true
	var boss = CharacterBody3D.new()
	boss.set_script(load("res://scripts/raid_boss.gd"))
	boss.set("raid_type", 1)  # GOD
	boss.position = Vector3(-6, 4, 6)
	if player and player.has_method("on_raid_defeated"):
		boss.raid_defeated.connect(player.on_raid_defeated)
	heaven_root.add_child(boss)
	if player and player.get("status_label"):
		player.status_label.text = "God has appeared!"

func get_dimension_name() -> String:
	match current_dimension:
		0: return "Overworld"
		1: return "Hell"
		2: return "Purgatory"
		3: return "Heaven"
		4: return "Moon"
		_: return "Unknown"
