extends Node3D
class_name SkySystem

# MASK celestial system — sun/moon spheres, stars, clouds, eclipses

const DAY_LENGTH_SEC := 30.0 * 60.0   # 30 minutes day
const NIGHT_LENGTH_SEC := 30.0 * 60.0 # 30 minutes night
const FULL_CYCLE := DAY_LENGTH_SEC + NIGHT_LENGTH_SEC
const ECLIPSE_EVERY_DAYS := 24

var time_of_day := 0.25  # 0..1 within full cycle (0=midnight start-ish, 0.25 morning)
var day_counter := 0
var sun: MeshInstance3D
var moon: MeshInstance3D
var sun_light: DirectionalLight3D
var stars: Node3D
var clouds: Node3D
var eclipse_active := false
var eclipse_timer := 0.0

signal day_advanced(day: int)
signal eclipse_started
signal eclipse_ended

func _ready() -> void:
	_build_sun()
	_build_moon()
	_build_stars()
	_build_clouds()
	_build_light()

func _build_sun() -> void:
	sun = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 8.0
	sphere.height = 16.0
	sun.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.92, 0.55)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.4) * 2.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sun.material_override = mat
	sun.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sun)

func _build_moon() -> void:
	moon = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 5.5
	sphere.height = 11.0
	moon.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.82, 0.84, 0.88)
	mat.roughness = 0.95
	mat.metallic = 0.05
	# subtle shading — not unshaded so it looks like a lit sphere
	moon.material_override = mat
	moon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(moon)

func _build_stars() -> void:
	stars = Node3D.new()
	add_child(stars)
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345
	for i in range(120):
		var s = MeshInstance3D.new()
		var m = SphereMesh.new()
		m.radius = rng.randf_range(0.15, 0.45)
		m.height = m.radius * 2.0
		s.mesh = m
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.95, 1.0)
		mat.emission_enabled = true
		mat.emission = Color(0.8, 0.85, 1.0) * rng.randf_range(0.8, 1.5)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		s.material_override = mat
		# place on large sphere shell
		var dir = Vector3(rng.randf_range(-1, 1), rng.randf_range(0.1, 1), rng.randf_range(-1, 1)).normalized()
		s.position = dir * rng.randf_range(180.0, 260.0)
		stars.add_child(s)
	stars.visible = false

func _build_clouds() -> void:
	clouds = Node3D.new()
	add_child(clouds)
	var rng = RandomNumberGenerator.new()
	rng.seed = 99
	for i in range(18):
		var c = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(rng.randf_range(12, 28), rng.randf_range(2, 5), rng.randf_range(8, 18))
		c.mesh = box
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1, 1, 1, 0.55)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.roughness = 1.0
		c.material_override = mat
		c.position = Vector3(rng.randf_range(-80, 80), rng.randf_range(40, 70), rng.randf_range(-80, 80))
		clouds.add_child(c)
	clouds.visible = true

func _build_light() -> void:
	sun_light = DirectionalLight3D.new()
	sun_light.shadow_enabled = true
	sun_light.shadow_bias = 0.03
	sun_light.shadow_normal_bias = 1.0
	sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun_light.directional_shadow_max_distance = 120.0
	sun_light.light_energy = 1.2
	sun_light.light_volumetric_fog_energy = 1.0
	add_child(sun_light)

func _process(delta: float) -> void:
	var prev = time_of_day
	time_of_day = fmod(time_of_day + delta / FULL_CYCLE, 1.0)
	if time_of_day < prev:
		day_counter += 1
		emit_signal("day_advanced", day_counter)
		# Eclipse check: every 24 days, near midday
		if day_counter > 0 and day_counter % ECLIPSE_EVERY_DAYS == 0:
			eclipse_active = true
			eclipse_timer = 90.0  # ~1.5 minutes eclipse
			emit_signal("eclipse_started")

	if eclipse_active:
		eclipse_timer -= delta
		if eclipse_timer <= 0.0:
			eclipse_active = false
			emit_signal("eclipse_ended")

	_update_celestial()
	_update_light()
	_update_visibility()

func _update_celestial() -> void:
	# time 0 = midnight, 0.25 = sunrise, 0.5 = noon, 0.75 = sunset
	var angle = time_of_day * TAU
	# Sun opposite to "night"
	var sun_dir = Vector3(sin(angle), -cos(angle), 0.15)
	var moon_dir = -sun_dir
	var dist = 120.0
	if sun:
		sun.global_position = global_position + sun_dir.normalized() * dist
		# during eclipse, move moon to cover sun
		if eclipse_active and time_of_day > 0.45 and time_of_day < 0.55:
			var cover = 1.0 - abs(time_of_day - 0.5) * 20.0
			cover = clampf(cover, 0.0, 1.0)
			if moon:
				moon.global_position = sun.global_position + Vector3(0, 0, 2.0) * (1.0 - cover) * 3.0
				moon.global_position = sun.global_position.lerp(sun.global_position + Vector3(0.5, 0, 0), 1.0 - cover * 0.95)
		elif moon:
			moon.global_position = global_position + moon_dir.normalized() * (dist * 0.95)
	if sun_light:
		sun_light.look_at(sun_light.global_position - sun_dir)

func _update_light() -> void:
	if not sun_light:
		return
	var t = time_of_day
	var energy = 0.08
	if t > 0.2 and t < 0.8:
		energy = lerp(0.08, 1.35, smoothstep(0.2, 0.35, t))
		if t > 0.65:
			energy = lerp(1.35, 0.08, smoothstep(0.65, 0.8, t))
	if eclipse_active and t > 0.45 and t < 0.55:
		energy *= 0.12  # darken during eclipse
	sun_light.light_energy = energy
	sun_light.light_color = Color(1.0, 0.95, 0.85).lerp(Color(0.5, 0.55, 0.8), 1.0 - clampf(energy, 0, 1))

func _update_visibility() -> void:
	var day = time_of_day > 0.22 and time_of_day < 0.78
	if stars:
		stars.visible = not day or eclipse_active
	if clouds:
		clouds.visible = day and not eclipse_active
	# drift clouds slowly
	if clouds and clouds.visible:
		for c in clouds.get_children():
			c.position.x += 0.8 * get_process_delta_time()
			if c.position.x > 100:
				c.position.x = -100

func get_time_string() -> String:
	var total_minutes = time_of_day * (FULL_CYCLE / 60.0)
	var hours = int(total_minutes / 2.5) % 24  # aesthetic clock
	# Better: map 0..1 to 24h
	hours = int(time_of_day * 24.0)
	var mins = int(fmod(time_of_day * 24.0, 1.0) * 60.0)
	var period = "AM" if hours < 12 else "PM"
	var h12 = hours % 12
	if h12 == 0:
		h12 = 12
	var extra = ""
	if eclipse_active:
		extra = " | ECLIPSE"
	return "Day %d | %d:%02d %s%s" % [day_counter + 1, h12, mins, period, extra]

func is_day() -> bool:
	return time_of_day > 0.22 and time_of_day < 0.78 and not eclipse_active
