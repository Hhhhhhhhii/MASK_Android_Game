extends Node3D

const VOXEL_SCRIPT = preload("res://scripts/voxel_world.gd")
const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const CREATURE_SCRIPT = preload("res://scripts/creature.gd")
const WEATHER_SCRIPT = preload("res://scripts/weather.gd")
const DIM_SCRIPT = preload("res://scripts/dimension_manager.gd")
const BOSS_SCRIPT = preload("res://scripts/boss.gd")
const PORTAL_SCRIPT = preload("res://scripts/portal.gd")
const WORLD_MANAGER_SCRIPT = preload("res://scripts/world_manager.gd")
const WORLD_SELECT_SCRIPT = preload("res://scripts/world_select.gd")
const CHEST_SCRIPT = preload("res://scripts/chest.gd")
const GUIDE_SCRIPT = preload("res://scripts/guidebook.gd")
const SKY_SCRIPT = preload("res://scripts/sky_system.gd")
const INTRO_SCRIPT = preload("res://scripts/intro_cutscene.gd")

var sun: DirectionalLight3D
var world_env: WorldEnvironment
var time_of_day := 0.28
var day_length := 160.0
var weather: Node3D
var dim_manager: Node
var overworld: Node3D
var player: CharacterBody3D
var world_manager: Node
var world_select: CanvasLayer
var game_started := false
var sky_system: Node3D
var intro: CanvasLayer
var pending_start: Dictionary = {}

# Portal positions for compass
var portal_positions := {
	0: Vector3.ZERO,  # hell
	1: Vector3.ZERO,  # purgatory
	2: Vector3.ZERO   # heaven
}

func _ready() -> void:
	_make_environment()

	world_manager = Node.new()
	world_manager.set_script(WORLD_MANAGER_SCRIPT)
	add_child(world_manager)

	world_select = CanvasLayer.new()
	world_select.set_script(WORLD_SELECT_SCRIPT)
	add_child(world_select)
	world_select.setup(world_manager)
	world_select.start_game.connect(_on_start_game)

func _on_start_game(seed: int, wname: String, creative: bool) -> void:
	if game_started:
		return
	world_select.visible = false
	pending_start = {"seed": seed, "name": wname, "creative": creative}
	# Play intro cutscene before spawning world
	if intro == null:
		intro = CanvasLayer.new()
		intro.set_script(INTRO_SCRIPT)
		add_child(intro)
		intro.finished.connect(_on_intro_finished)
	intro.play()

func _on_intro_finished() -> void:
	if game_started:
		return
	game_started = true
	var seed = pending_start.get("seed", 91)
	var wname = pending_start.get("name", "World")
	var creative = pending_start.get("creative", false)
	_start_world(seed, wname, creative)

func _start_world(seed: int, wname: String, creative: bool) -> void:
	overworld = Node3D.new()
	overworld.set_script(VOXEL_SCRIPT)
	overworld.name = "VoxelWorld"
	overworld.set("world_seed", seed)
	add_child(overworld)

	player = CharacterBody3D.new()
	player.set_script(PLAYER_SCRIPT)
	player.name = "Player"
	player.position = Vector3(0, 22, 0)
	player.set("creative_mode", creative)
	add_child(player)

	sky_system = Node3D.new()
	sky_system.set_script(SKY_SCRIPT)
	sky_system.name = "SkySystem"
	add_child(sky_system)
	# SkySystem owns the sun light — dim the old scene sun
	if sun:
		sun.light_energy = 0.0
		sun.shadow_enabled = false

	dim_manager = Node.new()
	dim_manager.set_script(DIM_SCRIPT)
	add_child(dim_manager)
	dim_manager.setup(player, overworld)
	player.set("dim_manager", dim_manager)

	weather = Node3D.new()
	weather.set_script(WEATHER_SCRIPT)
	add_child(weather)

	var rng = RandomNumberGenerator.new()
	rng.seed = seed

	if not creative:
		var kinds = [0, 0, 1, 1, 2, 2, 3]
		for i in range(kinds.size()):
			var c = CharacterBody3D.new()
			c.set_script(CREATURE_SCRIPT)
			c.set("kind", kinds[i])
			c.position = Vector3(rng.randf_range(-18, 18), 18, rng.randf_range(-18, 18))
			overworld.add_child(c)
		_spawn_bosses_and_portals(rng)
	else:
		_spawn_portals_only(rng)

	_scatter_plants(rng)
	_spawn_chests(rng)

func _spawn_portals_only(rng: RandomNumberGenerator) -> void:
	_create_portal(0, Vector3(14, 6, 14))
	_create_portal(1, Vector3(-14, 20, -12))
	_create_portal(2, Vector3(10, 22, -14))

func _spawn_bosses_and_portals(rng: RandomNumberGenerator) -> void:
	# Portals first so we know positions
	var hell_pos = Vector3(rng.randf_range(14, 20), 5, rng.randf_range(14, 20))
	var purg_pos = Vector3(rng.randf_range(-20, -12), 20, rng.randf_range(-20, -12))
	var heav_pos = Vector3(rng.randf_range(8, 16), 22, rng.randf_range(-18, -10))

	_create_portal(0, hell_pos)
	_create_portal(1, purg_pos)
	_create_portal(2, heav_pos)

	# Bosses near their altitude bands, not exactly on the portal
	var hell_boss = CharacterBody3D.new()
	hell_boss.set_script(BOSS_SCRIPT)
	hell_boss.set("boss_type", 0)
	hell_boss.position = hell_pos + Vector3(rng.randf_range(-6, 6), 2, rng.randf_range(-6, 6))
	hell_boss.boss_defeated.connect(player.on_boss_defeated)
	hell_boss.call_sign.connect(player.on_boss_call_sign)
	overworld.add_child(hell_boss)

	var purg_boss = CharacterBody3D.new()
	purg_boss.set_script(BOSS_SCRIPT)
	purg_boss.set("boss_type", 1)
	purg_boss.position = purg_pos + Vector3(rng.randf_range(-5, 5), 1, rng.randf_range(-5, 5))
	purg_boss.boss_defeated.connect(player.on_boss_defeated)
	purg_boss.call_sign.connect(player.on_boss_call_sign)
	overworld.add_child(purg_boss)

	var cupid = CharacterBody3D.new()
	cupid.set_script(BOSS_SCRIPT)
	cupid.set("boss_type", 2)
	cupid.position = heav_pos + Vector3(rng.randf_range(-5, 5), 1, rng.randf_range(-5, 5))
	cupid.boss_defeated.connect(player.on_boss_defeated)
	cupid.call_sign.connect(player.on_boss_call_sign)
	overworld.add_child(cupid)

func _create_portal(type: int, pos: Vector3) -> void:
	var p = Area3D.new()
	p.set_script(PORTAL_SCRIPT)
	p.set("portal_type", type)
	p.position = pos
	p.portal_entered.connect(_on_portal_entered)
	overworld.add_child(p)
	portal_positions[type] = pos
	# Give player access to positions for compass
	if player:
		player.set("portal_positions", portal_positions)

func _on_portal_entered(type: int) -> void:
	if not player or not dim_manager:
		return
	# type 0=hell, 1=purg, 2=heaven  → dimension 1,2,3
	var dim = type + 1
	player._try_enter_dimension(dim)


func _spawn_chests(rng: RandomNumberGenerator) -> void:
	for i in range(10):
		var chest = StaticBody3D.new()
		chest.set_script(CHEST_SCRIPT)
		chest.position = Vector3(rng.randf_range(-18, 18), 12 + rng.randf()*6, rng.randf_range(-18, 18))
		chest.chest_opened.connect(func(loot):
			if player and player.has_method("receive_loot"):
				player.receive_loot(loot)
		)
		overworld.add_child(chest)

func _scatter_plants(rng: RandomNumberGenerator) -> void:
	# Cylindrical trees + swaying canopies (game-consistent simple meshes)
	for i in range(22):
		var tree = Node3D.new()
		tree.position = Vector3(rng.randf_range(-22, 22), 11 + rng.randf()*4, rng.randf_range(-22, 22))
		var trunk = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = rng.randf_range(0.25, 0.45)
		cyl.bottom_radius = rng.randf_range(0.35, 0.55)
		cyl.height = rng.randf_range(4.0, 7.5)
		trunk.mesh = cyl
		var tmat = StandardMaterial3D.new()
		tmat.albedo_color = Color(0.4, 0.25, 0.12)
		trunk.material_override = tmat
		trunk.position.y = cyl.height * 0.5
		tree.add_child(trunk)
		var canopy = MeshInstance3D.new()
		var sph = SphereMesh.new()
		sph.radius = rng.randf_range(1.4, 2.4)
		sph.height = sph.radius * 1.6
		canopy.mesh = sph
		var cmat = StandardMaterial3D.new()
		cmat.albedo_color = Color(0.18 + rng.randf()*0.12, 0.45 + rng.randf()*0.15, 0.15)
		canopy.material_override = cmat
		canopy.position.y = cyl.height + sph.radius * 0.4
		canopy.set_script(load("res://scripts/sway.gd"))
		tree.add_child(canopy)
		overworld.add_child(tree)
	# Breathing flowers / plants
	for i in range(40):
		var p = MeshInstance3D.new()
		var mesh = SphereMesh.new()
		mesh.radius = rng.randf_range(0.15, 0.35)
		mesh.height = mesh.radius * rng.randf_range(1.5, 2.5)
		p.mesh = mesh
		var mat = StandardMaterial3D.new()
		var colors = [
			Color(0.9, 0.25, 0.3), Color(0.3, 0.45, 0.95),
			Color(0.95, 0.85, 0.2), Color(0.65, 0.3, 0.85),
			Color(0.2, 0.6, 0.25)
		]
		mat.albedo_color = colors[rng.randi_range(0, colors.size()-1)]
		p.material_override = mat
		p.position = Vector3(rng.randf_range(-22, 22), 11.2 + rng.randf()*3, rng.randf_range(-22, 22))
		p.set_script(load("res://scripts/sway.gd"))
		overworld.add_child(p)
	# A few crafting tables in world
	for i in range(3):
		var table = StaticBody3D.new()
		table.position = Vector3(rng.randf_range(-15, 15), 12, rng.randf_range(-15, 15))
		var mi = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(1.2, 0.9, 1.2)
		mi.mesh = box
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.55, 0.35, 0.18)
		mi.material_override = mat
		mi.position.y = 0.45
		table.add_child(mi)
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(1.2, 0.9, 1.2)
		col.shape = shape
		col.position.y = 0.45
		table.add_child(col)
		table.set_meta("craft_table", true)
		overworld.add_child(table)


func _make_environment() -> void:
	world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.22, 0.38, 0.62)
	sky_mat.sky_horizon_color = Color(0.55, 0.68, 0.82)
	sky_mat.ground_bottom_color = Color(0.18, 0.22, 0.16)
	sky_mat.ground_horizon_color = Color(0.40, 0.48, 0.38)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAP_ACES
	env.ssao_enabled = true
	env.ssao_radius = 1.5
	env.ssao_intensity = 2.0
	env.silhouettes_enabled = false
	world_env.environment = env
	add_child(world_env)

	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, -25, 0)
	sun.light_energy = 1.3
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.shadow_enabled = true
	add_child(sun)

	var fill = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(30, 140, 0)
	fill.light_energy = 0.22
	fill.light_color = Color(0.7, 0.8, 1.0)
	add_child(fill)

func _process(delta: float) -> void:
	if not game_started:
		return
	# SkySystem handles day/night cycle (30 min day + 30 min night)
	pass

func _update_day_night() -> void:
	if dim_manager and dim_manager.current_dimension != 0:
		return
	var t = time_of_day
	var sun_angle = (t - 0.25) * 360.0
	sun.rotation_degrees.x = -sun_angle
	var energy = 0.15
	if t > 0.22 and t < 0.78:
		energy = lerp(0.15, 1.35, smoothstep(0.22, 0.35, t))
		if t > 0.65:
			energy = lerp(1.35, 0.15, smoothstep(0.65, 0.78, t))
	sun.light_energy = energy
	if world_env and world_env.environment:
		world_env.environment.ambient_light_energy = clamp(energy * 0.45, 0.12, 0.6)

func get_time_string() -> String:
	var dim_name = "Overworld"
	if dim_manager:
		dim_name = dim_manager.get_dimension_name()
	var hours = int(time_of_day * 24.0)
	var mins = int(fmod(time_of_day * 24.0, 1.0) * 60.0)
	var period = "AM" if hours < 12 else "PM"
	var h12 = hours % 12
	if h12 == 0: h12 = 12
	var w = "Clear"
	if weather and weather.get("current_weather"):
		w = str(weather.current_weather).capitalize()
	var mode = "Creative" if (player and player.get("creative_mode")) else "Survival"
	return "%s | %s | %d:%02d %s | %s" % [dim_name, mode, h12, mins, period, w]
