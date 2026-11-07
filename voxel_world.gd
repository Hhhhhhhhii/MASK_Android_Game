extends Node3D
class_name VoxelWorld

enum Block {
	AIR = 0,
	SOIL = 1,
	VERDANT = 2,
	STONEHARD = 3,
	CRYSTALITE = 4,
	TIMBER = 5,
	DEEPSLATE = 6,
	CORE_STONE = 7,
	SAND = 8,
	SNOW = 9,
	ICE = 10,
	MOSS = 11,
	BASALT = 12,
	CLAY = 13,
	PORTAL_FRAME = 14,
	COAL = 15,
	COPPER = 16,
	IRON = 17,
	GOLD = 18,
	DIAMOND = 19,
	FLOWER_RED = 20,
	FLOWER_BLUE = 21,
	FLOWER_YELLOW = 22,
	FLOWER_PURPLE = 23
}

const WORLD_SIZE_X := 56
const WORLD_SIZE_Y := 36
const WORLD_SIZE_Z := 56

var world_seed: int = 91

var blocks: PackedByteArray
var mesh_instance: MeshInstance3D
var collision_body: StaticBody3D
var collision_shape: CollisionShape3D

var block_colors := {
	Block.SOIL: Color(0.30, 0.17, 0.08),
	Block.VERDANT: Color(0.20, 0.46, 0.16),
	Block.STONEHARD: Color(0.40, 0.43, 0.50),
	Block.CRYSTALITE: Color(0.28, 0.68, 0.88),
	Block.TIMBER: Color(0.45, 0.26, 0.11),
	Block.DEEPSLATE: Color(0.16, 0.17, 0.22),
	Block.CORE_STONE: Color(0.50, 0.32, 0.14),
	Block.SAND: Color(0.78, 0.70, 0.48),
	Block.SNOW: Color(0.92, 0.94, 0.97),
	Block.ICE: Color(0.55, 0.75, 0.90),
	Block.MOSS: Color(0.25, 0.42, 0.18),
	Block.BASALT: Color(0.22, 0.20, 0.25),
	Block.CLAY: Color(0.55, 0.42, 0.32),
	Block.PORTAL_FRAME: Color(0.55, 0.15, 0.75),
	Block.COAL: Color(0.12, 0.12, 0.14),
	Block.COPPER: Color(0.72, 0.42, 0.22),
	Block.IRON: Color(0.62, 0.64, 0.68),
	Block.GOLD: Color(0.92, 0.78, 0.22),
	Block.DIAMOND: Color(0.35, 0.85, 0.95),
	Block.FLOWER_RED: Color(0.9, 0.2, 0.25),
	Block.FLOWER_BLUE: Color(0.3, 0.45, 0.95),
	Block.FLOWER_YELLOW: Color(0.95, 0.88, 0.2),
	Block.FLOWER_PURPLE: Color(0.65, 0.3, 0.85)
}

func _ready() -> void:
	blocks = PackedByteArray()
	blocks.resize(WORLD_SIZE_X * WORLD_SIZE_Y * WORLD_SIZE_Z)
	blocks.fill(Block.AIR)
	_generate_world()
	_build_mesh()
	_build_collision()

func _idx(x: int, y: int, z: int) -> int:
	return x + WORLD_SIZE_X * (y + WORLD_SIZE_Y * z)

func is_in_bounds(x: int, y: int, z: int) -> bool:
	return x >= 0 and x < WORLD_SIZE_X and y >= 0 and y < WORLD_SIZE_Y and z >= 0 and z < WORLD_SIZE_Z

func get_block(x: int, y: int, z: int) -> int:
	if not is_in_bounds(x, y, z):
		return Block.AIR
	return blocks[_idx(x, y, z)]

func set_block(x: int, y: int, z: int, type: int) -> void:
	if is_in_bounds(x, y, z):
		blocks[_idx(x, y, z)] = type

func world_to_grid(pos: Vector3) -> Vector3i:
	var origin = Vector3(-WORLD_SIZE_X * 0.5, 0, -WORLD_SIZE_Z * 0.5)
	var local = pos - origin
	return Vector3i(floor(local.x), floor(local.y), floor(local.z))

func grid_to_world(g: Vector3i) -> Vector3:
	var origin = Vector3(-WORLD_SIZE_X * 0.5, 0, -WORLD_SIZE_Z * 0.5)
	return origin + Vector3(g.x + 0.5, g.y + 0.5, g.z + 0.5)

func _noise2(x: float, z: float, scale: float) -> float:
	return sin(x * scale) * cos(z * scale * 1.3) * 0.5 + 0.5

func _height_at(x: float, z: float) -> float:
	var h = 11.0
	h += sin(x * 0.07) * 4.2
	h += cos(z * 0.06) * 3.6
	h += sin((x + z) * 0.035) * 5.2
	h += cos(x * 0.12) * cos(z * 0.11) * 2.6
	var peak = max(0.0, 1.0 - abs(_noise2(x, z, 0.04) - 0.72) * 3.8)
	h += peak * 9.0
	return clamp(h, 5.0, WORLD_SIZE_Y - 5)

func _biome_at(x: float, z: float) -> int:
	var n = _noise2(x * 0.9, z * 0.9, 0.022)
	if n < 0.20: return 2
	elif n < 0.38: return 0
	elif n < 0.58: return 1
	elif n < 0.76: return 4
	else: return 3

func _generate_world() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = world_seed

	for z in range(WORLD_SIZE_Z):
		for x in range(WORLD_SIZE_X):
			var h = int(_height_at(x, z))
			var biome = _biome_at(x, z)
			for y in range(WORLD_SIZE_Y):
				var type = Block.AIR
				if y == 0:
					type = Block.CORE_STONE
				elif y < h - 6:
					type = Block.BASALT if biome == 2 else Block.DEEPSLATE
				elif y < h - 2:
					type = Block.STONEHARD
				elif y < h:
					match biome:
						2: type = Block.SAND
						3: type = Block.SNOW
						4: type = Block.CLAY
						_: type = Block.SOIL
				elif y == h:
					match biome:
						0, 1: type = Block.VERDANT
						2: type = Block.SAND
						3: type = Block.SNOW
						4: type = Block.MOSS
				set_block(x, y, z, type)

			# More trees
			if (biome == 0 or biome == 1) and get_block(x, h, z) == Block.VERDANT and rng.randf() < 0.07:
				var th = rng.randi_range(3, 7)
				for ty in range(1, th + 1):
					if h + ty < WORLD_SIZE_Y:
						set_block(x, h + ty, z, Block.TIMBER)
				for dx in range(-1, 2):
					for dz in range(-1, 2):
						if h + th < WORLD_SIZE_Y and is_in_bounds(x+dx, h+th, z+dz):
							if get_block(x+dx, h+th, z+dz) == Block.AIR:
								set_block(x+dx, h+th, z+dz, Block.MOSS)
						if h + th - 1 < WORLD_SIZE_Y and is_in_bounds(x+dx, h+th-1, z+dz):
							if get_block(x+dx, h+th-1, z+dz) == Block.AIR and rng.randf() < 0.5:
								set_block(x+dx, h+th-1, z+dz, Block.MOSS)
			# Flowers on surface
			if (biome == 0 or biome == 1) and get_block(x, h, z) == Block.VERDANT and rng.randf() < 0.06:
				if h + 1 < WORLD_SIZE_Y and get_block(x, h + 1, z) == Block.AIR:
					var fl = [Block.FLOWER_RED, Block.FLOWER_BLUE, Block.FLOWER_YELLOW, Block.FLOWER_PURPLE][rng.randi_range(0, 3)]
					set_block(x, h + 1, z, fl)
			if biome == 3 and rng.randf() < 0.04:
				set_block(x, h, z, Block.ICE)

	# Crystal clusters
	for i in range(30):
		var cx = rng.randi_range(3, WORLD_SIZE_X - 4)
		var cy = rng.randi_range(2, 11)
		var cz = rng.randi_range(3, WORLD_SIZE_Z - 4)
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				for dz in range(-1, 2):
					if rng.randf() < 0.5:
						set_block(cx+dx, cy+dy, cz+dz, Block.CRYSTALITE)


	# Ore veins in stone / deepslate layers
	for i in range(90):
		var ox = rng.randi_range(2, WORLD_SIZE_X - 3)
		var oy = rng.randi_range(2, 16)
		var oz = rng.randi_range(2, WORLD_SIZE_Z - 3)
		var ore_type = Block.COAL
		var r = rng.randf()
		if r < 0.35:
			ore_type = Block.COAL
		elif r < 0.58:
			ore_type = Block.COPPER
		elif r < 0.78:
			ore_type = Block.IRON
		elif r < 0.92:
			ore_type = Block.GOLD
		else:
			ore_type = Block.DIAMOND
		var vein = rng.randi_range(2, 6)
		for v in range(vein):
			var vx = ox + rng.randi_range(-1, 1)
			var vy = oy + rng.randi_range(-1, 1)
			var vz = oz + rng.randi_range(-1, 1)
			if is_in_bounds(vx, vy, vz):
				var existing = get_block(vx, vy, vz)
				if existing == Block.STONEHARD or existing == Block.DEEPSLATE or existing == Block.BASALT:
					set_block(vx, vy, vz, ore_type)

	# Caves
	for i in range(14):
		var cx = float(rng.randi_range(8, WORLD_SIZE_X-9))
		var cy = float(rng.randi_range(4, 15))
		var cz = float(rng.randi_range(8, WORLD_SIZE_Z-9))
		var dir = Vector3(rng.randf_range(-1,1), rng.randf_range(-0.3,0.25), rng.randf_range(-1,1)).normalized()
		for s in range(rng.randi_range(12, 26)):
			var rad = rng.randi_range(1, 3)
			for dx in range(-rad, rad+1):
				for dy in range(-rad, rad+1):
					for dz in range(-rad, rad+1):
						if dx*dx + dy*dy + dz*dz <= rad*rad + 1:
							var bx = int(cx+dx)
							var by = int(cy+dy)
							var bz = int(cz+dz)
							if is_in_bounds(bx,by,bz) and get_block(bx,by,bz) != Block.CORE_STONE:
								set_block(bx,by,bz, Block.AIR)
			cx += dir.x * 1.3
			cy += dir.y * 1.0
			cz += dir.z * 1.3
			dir = (dir + Vector3(rng.randf_range(-0.25,0.25), rng.randf_range(-0.15,0.15), rng.randf_range(-0.25,0.25))).normalized()

	# Chambers
	for i in range(4):
		var cx = rng.randi_range(10, WORLD_SIZE_X-11)
		var cy = rng.randi_range(5, 12)
		var cz = rng.randi_range(10, WORLD_SIZE_Z-11)
		var rad = rng.randi_range(4, 6)
		for dx in range(-rad, rad+1):
			for dy in range(-rad, rad+1):
				for dz in range(-rad, rad+1):
					if dx*dx + dy*dy + dz*dz < rad*rad:
						if is_in_bounds(cx+dx, cy+dy, cz+dz) and get_block(cx+dx, cy+dy, cz+dz) != Block.CORE_STONE:
							set_block(cx+dx, cy+dy, cz+dz, Block.AIR)

	# A few portal frame structures (visual only for now)
	for i in range(3):
		var px = rng.randi_range(8, WORLD_SIZE_X-9)
		var pz = rng.randi_range(8, WORLD_SIZE_Z-9)
		var py = int(_height_at(px, pz)) + 1
		if py + 3 < WORLD_SIZE_Y:
			for ly in range(3):
				set_block(px, py+ly, pz, Block.PORTAL_FRAME)
				set_block(px+2, py+ly, pz, Block.PORTAL_FRAME)
			set_block(px+1, py+2, pz, Block.PORTAL_FRAME)
			set_block(px+1, py, pz, Block.PORTAL_FRAME)

func _build_mesh() -> void:
	if mesh_instance:
		mesh_instance.queue_free()
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var faces = [
		[Vector3(1,0,0), [Vector3(0.5,-0.5,-0.5), Vector3(0.5,0.5,-0.5), Vector3(0.5,0.5,0.5), Vector3(0.5,-0.5,0.5)]],
		[Vector3(-1,0,0), [Vector3(-0.5,-0.5,0.5), Vector3(-0.5,0.5,0.5), Vector3(-0.5,0.5,-0.5), Vector3(-0.5,-0.5,-0.5)]],
		[Vector3(0,1,0), [Vector3(-0.5,0.5,-0.5), Vector3(-0.5,0.5,0.5), Vector3(0.5,0.5,0.5), Vector3(0.5,0.5,-0.5)]],
		[Vector3(0,-1,0), [Vector3(-0.5,-0.5,0.5), Vector3(-0.5,-0.5,-0.5), Vector3(0.5,-0.5,-0.5), Vector3(0.5,-0.5,0.5)]],
		[Vector3(0,0,1), [Vector3(-0.5,-0.5,0.5), Vector3(0.5,-0.5,0.5), Vector3(0.5,0.5,0.5), Vector3(-0.5,0.5,0.5)]],
		[Vector3(0,0,-1), [Vector3(0.5,-0.5,-0.5), Vector3(-0.5,-0.5,-0.5), Vector3(-0.5,0.5,-0.5), Vector3(0.5,0.5,-0.5)]]
	]

	var origin = Vector3(-WORLD_SIZE_X * 0.5, 0, -WORLD_SIZE_Z * 0.5)

	for z in range(WORLD_SIZE_Z):
		for y in range(WORLD_SIZE_Y):
			for x in range(WORLD_SIZE_X):
				var b = get_block(x, y, z)
				if b == Block.AIR: continue
				var base_col = block_colors.get(b, Color.WHITE)
				var shade = 0.90 + 0.18 * sin(x*1.6 + y*2.1 + z*1.3)
				var col = base_col * shade
				col.a = 1.0
				var center = origin + Vector3(x+0.5, y+0.5, z+0.5)
				for f in faces:
					var normal: Vector3 = f[0]
					var nx = x + int(normal.x)
					var ny = y + int(normal.y)
					var nz = z + int(normal.z)
					if get_block(nx, ny, nz) != Block.AIR: continue
					var verts: Array = f[1]
					st.set_normal(normal)
					st.set_color(col)
					st.add_vertex(center + verts[0])
					st.add_vertex(center + verts[1])
					st.add_vertex(center + verts[2])
					st.add_vertex(center + verts[0])
					st.add_vertex(center + verts[2])
					st.add_vertex(center + verts[3])

	st.generate_normals()
	var mesh = st.commit()
	mesh_instance.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.82
	mat.metallic = 0.04
	mesh_instance.material_override = mat

func _build_collision() -> void:
	if collision_body:
		collision_body.queue_free()
	collision_body = StaticBody3D.new()
	add_child(collision_body)
	collision_shape = CollisionShape3D.new()
	collision_body.add_child(collision_shape)
	if mesh_instance and mesh_instance.mesh:
		var concave = ConcavePolygonShape3D.new()
		concave.set_faces(mesh_instance.mesh.get_faces())
		collision_shape.shape = concave

func rebuild() -> void:
	_build_mesh()
	_build_collision()

func break_block(x: int, y: int, z: int) -> int:
	var b = get_block(x, y, z)
	if b == Block.AIR or b == Block.CORE_STONE:
		return Block.AIR
	set_block(x, y, z, Block.AIR)
	rebuild()
	return b

func place_block(x: int, y: int, z: int, type: int) -> bool:
	if not is_in_bounds(x, y, z) or get_block(x, y, z) != Block.AIR:
		return false
	set_block(x, y, z, type)
	rebuild()
	return true
