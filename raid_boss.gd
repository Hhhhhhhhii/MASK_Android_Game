extends CharacterBody3D
class_name RaidBoss

enum RaidType { LUCIFER, GOD }

@export var raid_type: RaidType = RaidType.LUCIFER

var max_health := 200.0
var health := 200.0
var speed := 4.5
var damage := 14.0
var damage_cooldown := 0.0
var special_cooldown := 0.0
var player_ref: Node3D = null
var mesh_inst: MeshInstance3D
var aura: MeshInstance3D
var label: Label3D
var alive := true
var phase := 1

signal raid_defeated(type: int)

func _ready() -> void:
	match raid_type:
		RaidType.LUCIFER:
			max_health = 220.0
			speed = 4.8
			damage = 16.0
		RaidType.GOD:
			max_health = 240.0
			speed = 4.2
			damage = 15.0
	health = max_health
	_build_visual()
	call_deferred("_find_player")

func _find_player() -> void:
	var root = get_tree().current_scene
	if root:
		player_ref = root.get_node_or_null("Player")

func _build_visual() -> void:
	mesh_inst = MeshInstance3D.new()
	var mat = StandardMaterial3D.new()
	mat.roughness = 0.35
	mat.emission_enabled = true

	match raid_type:
		RaidType.LUCIFER:
			var s = SphereMesh.new()
			s.radius = 1.6
			s.height = 3.2
			mesh_inst.mesh = s
			mat.albedo_color = Color(0.15, 0.02, 0.02)
			mat.emission = Color(0.9, 0.15, 0.05) * 0.85
		RaidType.GOD:
			var s = SphereMesh.new()
			s.radius = 1.7
			s.height = 3.4
			mesh_inst.mesh = s
			mat.albedo_color = Color(0.95, 0.92, 0.7)
			mat.emission = Color(1.0, 0.95, 0.5) * 0.9

	mesh_inst.material_override = mat
	mesh_inst.position.y = 1.7
	add_child(mesh_inst)

	# Aura ring
	aura = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 1.8
	torus.outer_radius = 2.3
	aura.mesh = torus
	var amat = StandardMaterial3D.new()
	amat.albedo_color = mat.emission
	amat.emission_enabled = true
	amat.emission = mat.emission * 0.6
	amat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	amat.albedo_color.a = 0.5
	aura.material_override = amat
	aura.position.y = 0.3
	add_child(aura)

	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 1.5
	col.shape = shape
	col.position.y = 1.7
	add_child(col)

	label = Label3D.new()
	label.text = _boss_name() + "  RAID"
	label.font_size = 56
	label.position = Vector3(0, 4.0, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func _boss_name() -> String:
	match raid_type:
		RaidType.LUCIFER: return "Lucifer"
		RaidType.GOD: return "God"
	return "Raid Boss"

func take_damage(amount: float) -> void:
	if not alive:
		return
	health -= amount
	# Phase shift at 50%
	if phase == 1 and health <= max_health * 0.5:
		phase = 2
		speed *= 1.25
		damage *= 1.2
		label.text = "%s  PHASE 2  %.0f" % [_boss_name(), health]
	else:
		label.text = "%s  %.0f / %.0f" % [_boss_name(), health, max_health]
	if health <= 0:
		_die()

func _die() -> void:
	alive = false
	label.text = "%s DEFEATED" % _boss_name()
	emit_signal("raid_defeated", raid_type)
	var tween = create_tween()
	tween.tween_property(mesh_inst, "scale", Vector3.ZERO, 1.0)
	tween.parallel().tween_property(aura, "scale", Vector3.ZERO, 1.0)
	tween.tween_callback(queue_free)

func _physics_process(delta: float) -> void:
	if not alive or not player_ref:
		return
	damage_cooldown = max(0.0, damage_cooldown - delta)
	special_cooldown = max(0.0, special_cooldown - delta)

	# Rotate aura
	if aura:
		aura.rotate_y(delta * 1.5)

	var to_player = player_ref.global_position - global_position
	var dist = to_player.length()
	to_player.y = 0

	# Special attack telegraph every few seconds
	if special_cooldown <= 0.0 and dist < 18.0:
		special_cooldown = 5.5 if phase == 1 else 3.8
		_special_attack()

	if dist > 2.2:
		var dir = to_player.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		if dir.length() > 0.1:
			look_at(global_position + dir, Vector3.UP)
	else:
		velocity.x = 0
		velocity.z = 0
		if damage_cooldown <= 0.0:
			damage_cooldown = 0.9 if phase == 1 else 0.65
			if player_ref.has_method("take_damage"):
				player_ref.take_damage(damage)

	if not is_on_floor():
		velocity.y -= 22.0 * delta
	move_and_slide()

func _special_attack() -> void:
	# Burst damage if player is close when special fires
	if not player_ref:
		return
	var dist = global_position.distance_to(player_ref.global_position)
	if dist < 10.0 and player_ref.has_method("take_damage"):
		var burst = damage * 1.6
		player_ref.take_damage(burst)
		if player_ref.get("status_label"):
			player_ref.status_label.text = "%s unleashes a raid strike!" % _boss_name()
