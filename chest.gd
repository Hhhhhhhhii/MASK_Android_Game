extends StaticBody3D
class_name MaskChest

var opened := false
var mesh_inst: MeshInstance3D
var label: Label3D

signal chest_opened(loot: Dictionary)

func _ready() -> void:
	_build()

func _build() -> void:
	mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.9, 0.6, 0.6)
	mesh_inst.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.28, 0.12)
	mat.roughness = 0.8
	mesh_inst.material_override = mat
	mesh_inst.position.y = 0.3
	add_child(mesh_inst)

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.9, 0.6, 0.6)
	col.shape = shape
	col.position.y = 0.3
	add_child(col)

	label = Label3D.new()
	label.text = "Chest"
	label.font_size = 32
	label.position = Vector3(0, 1.0, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func try_open() -> Dictionary:
	if opened:
		return {}
	opened = true
	label.text = "Opened"
	var loot := _roll_loot()
	emit_signal("chest_opened", loot)
	# Visual sink
	var tween = create_tween()
	tween.tween_property(mesh_inst, "position:y", 0.05, 0.4)
	return loot

func _roll_loot() -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var loot: Dictionary = {}
	# Completely random assortment
	var pool = [
		VoxelWorld.Block.SOIL,
		VoxelWorld.Block.STONEHARD,
		VoxelWorld.Block.TIMBER,
		VoxelWorld.Block.CRYSTALITE,
		VoxelWorld.Block.COAL,
		VoxelWorld.Block.COPPER,
		VoxelWorld.Block.IRON,
		VoxelWorld.Block.GOLD,
		VoxelWorld.Block.DIAMOND,
		VoxelWorld.Block.SAND,
		VoxelWorld.Block.MOSS,
		VoxelWorld.Block.PORTAL_FRAME,
		110, 111, 112, 115, 116, 118, 119, 101, 102, 201, 301, 302, 501, 601, 701, 702, 800, 801
	]
	var rolls = rng.randi_range(2, 6)
	for i in range(rolls):
		var b = pool[rng.randi_range(0, pool.size() - 1)]
		var amt = rng.randi_range(1, 8)
		loot[b] = loot.get(b, 0) + amt
	return loot
