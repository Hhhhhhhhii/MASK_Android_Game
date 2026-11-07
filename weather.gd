extends Node3D
class_name MaskWeather

# Simple biome-aware weather for MASK

var particles: GPUParticles3D
var current_weather := "clear"  # clear, rain, snow
var timer := 0.0
var change_interval := 45.0

func _ready() -> void:
	_build_particles()
	timer = change_interval * 0.5

func _build_particles() -> void:
	particles = GPUParticles3D.new()
	particles.amount = 600
	particles.lifetime = 3.5
	particles.visibility_aabb = AABB(Vector3(-40, -5, -40), Vector3(80, 40, 80))
	particles.position = Vector3(0, 25, 0)

	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 12.0
	mat.initial_velocity_min = 4.0
	mat.initial_velocity_max = 8.0
	mat.gravity = Vector3(0, -2, 0)
	mat.scale_min = 0.04
	mat.scale_max = 0.09
	particles.process_material = mat

	var draw = StandardMaterial3D.new()
	draw.albedo_color = Color(0.75, 0.8, 0.9, 0.7)
	draw.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw.vertex_color_use_as_albedo = true
	var mesh = QuadMesh.new()
	mesh.size = Vector2(0.08, 0.08)
	particles.draw_pass_1 = mesh
	particles.material_override = draw

	particles.emitting = false
	add_child(particles)

func set_weather(type: String) -> void:
	current_weather = type
	match type:
		"rain":
			particles.emitting = true
			particles.amount = 700
			var mat: ParticleProcessMaterial = particles.process_material
			mat.initial_velocity_min = 6.0
			mat.initial_velocity_max = 11.0
			mat.gravity = Vector3(0, -6, 0)
			var draw: StandardMaterial3D = particles.material_override
			draw.albedo_color = Color(0.6, 0.7, 0.9, 0.55)
		"snow":
			particles.emitting = true
			particles.amount = 400
			var mat2: ParticleProcessMaterial = particles.process_material
			mat2.initial_velocity_min = 1.5
			mat2.initial_velocity_max = 3.5
			mat2.gravity = Vector3(0, -1.2, 0)
			var draw2: StandardMaterial3D = particles.material_override
			draw2.albedo_color = Color(0.95, 0.96, 1.0, 0.8)
		_:
			particles.emitting = false

func _process(delta: float) -> void:
	timer -= delta
	if timer <= 0.0:
		timer = change_interval + randf_range(-10, 15)
		# Simple random weather change
		var r = randf()
		if r < 0.55:
			set_weather("clear")
		elif r < 0.80:
			set_weather("rain")
		else:
			set_weather("snow")
