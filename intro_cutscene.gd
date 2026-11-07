extends CanvasLayer
class_name IntroCutscene

# MASK intro — same low-poly / simple mesh aesthetic as the game
# Plane → wings tear off → panic bag drops → struggle → faint → start world

signal finished

var viewport_scene: SubViewport
var container: SubViewportContainer
var world: Node3D
var plane: Node3D
var wing_l: MeshInstance3D
var wing_r: MeshInstance3D
var bag: MeshInstance3D
var player_mesh: MeshInstance3D
var cam: Camera3D
var label: Label
var overlay: ColorRect
var running := false
var t := 0.0
var phase := 0

func _ready() -> void:
	layer = 50
	_build_ui()
	_build_scene()
	visible = false

func _build_ui() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 1)
	overlay.anchor_right = 1
	overlay.anchor_bottom = 1
	add_child(overlay)

	container = SubViewportContainer.new()
	container.anchor_right = 1
	container.anchor_bottom = 1
	container.stretch = true
	add_child(container)

	viewport_scene = SubViewport.new()
	viewport_scene.size = Vector2i(1280, 720)
	viewport_scene.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport_scene)

	label = Label.new()
	label.anchor_left = 0.1
	label.anchor_right = 0.9
	label.anchor_top = 0.85
	label.anchor_bottom = 0.95
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.text = ""
	add_child(label)

	var skip = Button.new()
	skip.text = "SKIP"
	skip.anchor_left = 0.88
	skip.anchor_right = 0.98
	skip.anchor_top = 0.04
	skip.anchor_bottom = 0.10
	skip.pressed.connect(_end)
	add_child(skip)

func _build_scene() -> void:
	world = Node3D.new()
	viewport_scene.add_child(world)

	# Sky-ish background
	var env = WorldEnvironment.new()
	var e = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.45, 0.62, 0.85)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.75, 0.85)
	e.ambient_light_energy = 0.8
	env.environment = e
	world.add_child(env)

	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-30, 40, 0)
	sun.light_energy = 1.2
	world.add_child(sun)

	# Plane body
	plane = Node3D.new()
	plane.position = Vector3(0, 8, 0)
	world.add_child(plane)

	var body = MeshInstance3D.new()
	var body_mesh = BoxMesh.new()
	body_mesh.size = Vector3(2.2, 1.0, 6.0)
	body.mesh = body_mesh
	var bmat = StandardMaterial3D.new()
	bmat.albedo_color = Color(0.75, 0.78, 0.82)
	body.material_override = bmat
	plane.add_child(body)

	# Nose
	var nose = MeshInstance3D.new()
	var nmesh = SphereMesh.new()
	nmesh.radius = 0.55
	nmesh.height = 1.1
	nose.mesh = nmesh
	nose.position = Vector3(0, 0, -3.2)
	nose.material_override = bmat
	plane.add_child(nose)

	# Wings
	wing_l = _make_wing()
	wing_l.position = Vector3(-2.8, 0, 0)
	plane.add_child(wing_l)
	wing_r = _make_wing()
	wing_r.position = Vector3(2.8, 0, 0)
	plane.add_child(wing_r)

	# Tail
	var tail = MeshInstance3D.new()
	var tmesh = BoxMesh.new()
	tmesh.size = Vector3(0.2, 1.2, 1.5)
	tail.mesh = tmesh
	tail.position = Vector3(0, 0.8, 2.8)
	tail.material_override = bmat
	plane.add_child(tail)

	# Player (simple capsule head+body — same aesthetic)
	player_mesh = MeshInstance3D.new()
	var pmesh = CapsuleMesh.new()
	pmesh.radius = 0.25
	pmesh.height = 1.0
	player_mesh.mesh = pmesh
	var pmat = StandardMaterial3D.new()
	pmat.albedo_color = Color(0.35, 0.55, 0.75)
	player_mesh.material_override = pmat
	player_mesh.position = Vector3(0, 0.9, -0.5)
	plane.add_child(player_mesh)

	# Panic bag
	bag = MeshInstance3D.new()
	var bagmesh = BoxMesh.new()
	bagmesh.size = Vector3(0.35, 0.4, 0.2)
	bag.mesh = bagmesh
	var bagmat = StandardMaterial3D.new()
	bagmat.albedo_color = Color(0.85, 0.2, 0.15)
	bag.material_override = bagmat
	bag.position = Vector3(0.4, 0.7, -0.3)
	plane.add_child(bag)

	# Camera — looking forward from behind player slightly
	cam = Camera3D.new()
	cam.position = Vector3(0.3, 1.2, 1.2)
	cam.look_at(Vector3(0, 1.0, -4))
	cam.current = true
	plane.add_child(cam)

func _make_wing() -> MeshInstance3D:
	var w = MeshInstance3D.new()
	var m = BoxMesh.new()
	m.size = Vector3(3.5, 0.12, 1.4)
	w.mesh = m
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.72, 0.76)
	w.material_override = mat
	return w

func play() -> void:
	visible = true
	running = true
	t = 0.0
	phase = 0
	overlay.color = Color(0, 0, 0, 1)
	label.text = "MASK"
	# fade in
	var tw = create_tween()
	tw.tween_property(overlay, "color:a", 0.0, 1.2)

func _process(delta: float) -> void:
	if not running:
		return
	t += delta

	# Gentle plane shake / forward motion feel
	if plane and phase < 5:
		plane.position.y = 8.0 + sin(t * 2.0) * 0.15
		plane.rotation_degrees.z = sin(t * 1.5) * 2.0
		plane.position.z -= delta * 2.0

	match phase:
		0:  # calm flight
			label.text = "A quiet flight..."
			if t > 3.0:
				phase = 1
				t = 0.0
		1:  # turbulence
			label.text = "Something's wrong—"
			if plane:
				plane.rotation_degrees.z = sin(t * 12.0) * 8.0
				plane.rotation_degrees.x = sin(t * 7.0) * 3.0
			if t > 2.5:
				phase = 2
				t = 0.0
		2:  # wings tear off
			label.text = "The wings tear away!"
			if wing_l:
				wing_l.position += Vector3(-delta * 6.0, -delta * 2.0, delta * 3.0)
				wing_l.rotate_z(delta * 4.0)
			if wing_r:
				wing_r.position += Vector3(delta * 6.0, -delta * 2.0, delta * 3.0)
				wing_r.rotate_z(-delta * 4.0)
			if plane:
				plane.rotation_degrees.x += delta * 15.0
				plane.position.y -= delta * 4.0
			if t > 2.8:
				phase = 3
				t = 0.0
		3:  # panic bag drops, struggle
			label.text = "The panic bag drops — reach for it!"
			if bag:
				bag.position += Vector3(delta * 0.5, -delta * 3.5, delta * 1.5)
				bag.rotate_x(delta * 5.0)
			if player_mesh:
				# struggle: reach forward then sag
				var reach = sin(t * 6.0) * 0.15
				player_mesh.position = Vector3(reach, 0.9 - t * 0.08, -0.5 - t * 0.1)
				player_mesh.rotation_degrees.x = t * 12.0
			if plane:
				plane.position.y -= delta * 6.0
				plane.rotation_degrees.x += delta * 10.0
			if t > 4.0:
				phase = 4
				t = 0.0
		4:  # faint
			label.text = "Darkness..."
			if player_mesh:
				player_mesh.rotation_degrees.x = min(80.0, 48.0 + t * 20.0)
				player_mesh.position.y = max(0.2, 0.6 - t * 0.2)
			overlay.color.a = min(1.0, t / 2.5)
			if t > 3.0:
				phase = 5
				t = 0.0
		5:  # hold black then end
			label.text = ""
			overlay.color = Color(0, 0, 0, 1)
			if t > 1.2:
				_end()

func _end() -> void:
	if not running:
		return
	running = false
	visible = false
	emit_signal("finished")
