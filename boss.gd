extends CharacterBody3D
class_name MaskBoss

enum BossType { HELL_GUARDIAN, PURGATORY_SENTINEL, CUPID }

@export var boss_type: BossType = BossType.HELL_GUARDIAN
@export var max_health := 40.0
@export var call_y_min := 0.0
@export var call_y_max := 100.0

var health := 40.0
var speed := 3.2
var damage_cooldown := 0.0
var player_ref: Node3D = null
var mesh_inst: MeshInstance3D
var label: Label3D
var alive := true
var call_timer := 0.0
var call_cooldown := 4.5
var audio: AudioStreamPlayer3D

signal boss_defeated(type: int)
signal call_sign(type: int, boss_name: String)

func _ready() -> void:
	health = max_health
	_build_visual()
	_build_audio()
	call_deferred("_find_player")

func _find_player() -> void:
	var root = get_tree().current_scene
	if root:
		player_ref = root.get_node_or_null("Player")

func _build_audio() -> void:
	audio = AudioStreamPlayer3D.new()
	audio.volume_db = -4.0
	audio.max_distance = 80.0
	add_child(audio)
	# Simple generated tone as call-sign (trumpet-like placeholder)
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 0.5
	audio.stream = gen

func _play_call_sign() -> void:
	if not audio:
		emit_signal("call_sign", boss_type, _boss_name())
		return
	# Fill generator with a short harsh "horn" blip
	if audio.stream is AudioStreamGenerator:
		audio.play()
		var playback = audio.get_stream_playback()
		if playback:
			var rate = 22050.0
			var frames = int(rate * 0.35)
			var phase = 0.0
			# Two partials for a brassy call
			var f1 = 220.0 if boss_type == BossType.HELL_GUARDIAN else (180.0 if boss_type == BossType.PURGATORY_SENTINEL else 320.0)
			for i in range(frames):
				var t = float(i) / rate
				var env = 1.0 - (t / 0.35)
				var sample = sin(phase) * 0.35 * env + sin(phase * 1.5) * 0.15 * env
				phase += TAU * f1 / rate
				playback.push_frame(Vector2(sample, sample))
	elif not audio.playing:
		audio.play()
	emit_signal("call_sign", boss_type, _boss_name())

func _build_visual() -> void:
	mesh_inst = MeshInstance3D.new()
	var mat = StandardMaterial3D.new()
	mat.roughness = 0.5

	match boss_type:
		BossType.HELL_GUARDIAN:
			var s = SphereMesh.new()
			s.radius = 1.1
			s.height = 2.2
			mesh_inst.mesh = s
			mat.albedo_color = Color(0.55, 0.08, 0.05)
			mat.emission_enabled = true
			mat.emission = Color(0.6, 0.1, 0.05) * 0.5
			speed = 3.4
			max_health = 45
			call_y_min = 0.0
			call_y_max = 14.0   # lower / cave levels
		BossType.PURGATORY_SENTINEL:
			var c = BoxMesh.new()
			c.size = Vector3(1.4, 2.4, 1.4)
			mesh_inst.mesh = c
			mat.albedo_color = Color(0.25, 0.25, 0.35)
			mat.emission_enabled = true
			mat.emission = Color(0.3, 0.3, 0.5) * 0.3
			speed = 2.6
			max_health = 50
			call_y_min = 16.0
			call_y_max = 40.0  # mountain levels
		BossType.CUPID:
			var s = SphereMesh.new()
			s.radius = 0.7
			s.height = 1.4
			mesh_inst.mesh = s
			mat.albedo_color = Color(0.95, 0.85, 0.7)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.9, 0.6) * 0.4
			speed = 4.0
			max_health = 30
			call_y_min = 18.0
			call_y_max = 50.0  # high peaks

	health = max_health
	mesh_inst.material_override = mat
	mesh_inst.position.y = 1.1
	add_child(mesh_inst)

	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 1.0
	col.shape = shape
	col.position.y = 1.1
	add_child(col)

	label = Label3D.new()
	label.text = _boss_name()
	label.font_size = 48
	label.position = Vector3(0, 2.6, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func _boss_name() -> String:
	match boss_type:
		BossType.HELL_GUARDIAN: return "Hell Guardian"
		BossType.PURGATORY_SENTINEL: return "Purgatory Sentinel"
		BossType.CUPID: return "Cupid"
	return "Boss"

func take_damage(amount: float) -> void:
	if not alive:
		return
	health -= amount
	label.text = "%s  %.0f" % [_boss_name(), health]
	if health <= 0:
		_die()

func _die() -> void:
	alive = false
	label.text = "%s DEFEATED" % _boss_name()
	emit_signal("boss_defeated", boss_type)
	var tween = create_tween()
	tween.tween_property(mesh_inst, "scale", Vector3.ZERO, 0.6)
	tween.tween_callback(queue_free)

func _physics_process(delta: float) -> void:
	if not alive:
		return

	# Call-sign when player is in the boss altitude band
	call_timer -= delta
	if player_ref and call_timer <= 0.0:
		var py = player_ref.global_position.y
		if py >= call_y_min and py <= call_y_max:
			var dist = global_position.distance_to(player_ref.global_position)
			if dist < 55.0:
				call_timer = call_cooldown
				_play_call_sign()

	if not player_ref:
		return
	damage_cooldown = max(0.0, damage_cooldown - delta)

	var to_player = player_ref.global_position - global_position
	to_player.y = 0
	if to_player.length() > 1.5:
		var dir = to_player.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		if dir.length() > 0.1:
			look_at(global_position + dir, Vector3.UP)
	else:
		velocity.x = 0
		velocity.z = 0
		if damage_cooldown <= 0.0:
			damage_cooldown = 1.2
			if player_ref.has_method("take_damage"):
				player_ref.take_damage(8.0)

	if not is_on_floor():
		velocity.y -= 20.0 * delta
	move_and_slide()
