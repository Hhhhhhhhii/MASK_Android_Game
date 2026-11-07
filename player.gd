extends CharacterBody3D

@export var move_speed := 6.5
@export var sprint_speed := 10.0
@export var jump_velocity := 5.5
@export var look_sensitivity := 0.0028
@export var gamepad_look_sens := 2.8
@export var reach_distance := 5.5
@export var max_health := 100.0
var creative_mode := false

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var pitch := 0.0
var touch_look := false
var sprinting := false
var joystick_dir := Vector2.ZERO
var health := 100.0
var attack_cooldown := 0.0
var tap_start := Vector2.ZERO
var tap_time := 0.0
var pending_tap := false

var camera: Camera3D
var hud: CanvasLayer
var ray: RayCast3D
var joystick: Control
var settings: CanvasLayer
var guidebook: CanvasLayer
var inv_ui: CanvasLayer
var pause_menu: CanvasLayer
var fps_label: Label

var inventory: Dictionary = {}
var hotbar: Array[int] = []
var selected_slot := 0
var max_hotbar := 7

var has_crystal_shard := false
var has_rough_blade := false

# Portal access keys
var has_hell_compass := false
var has_purgatory_compass := false
var has_heaven_key := false
var has_stem := false
var near_craft_table := false
var craft_ui: Control

var dim_manager: Node = null
var portal_positions := {}
var compass_label: Label
var call_label: Label

var inv_label: Label
var selected_label: Label
var status_label: Label
var time_label: Label
var item_label: Label
var health_label: Label

func _ready() -> void:
	health = max_health
	_build_camera()
	_build_ray()
	_build_hud()
	_build_joystick()
	_build_settings()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if creative_mode:
		# Give plenty of every placeable block
		for b in [VoxelWorld.Block.SOIL, VoxelWorld.Block.VERDANT, VoxelWorld.Block.STONEHARD,
				  VoxelWorld.Block.CRYSTALITE, VoxelWorld.Block.TIMBER, VoxelWorld.Block.DEEPSLATE,
				  VoxelWorld.Block.SAND, VoxelWorld.Block.SNOW, VoxelWorld.Block.ICE,
				  VoxelWorld.Block.MOSS, VoxelWorld.Block.BASALT, VoxelWorld.Block.CLAY,
				  VoxelWorld.Block.PORTAL_FRAME, VoxelWorld.Block.COAL, VoxelWorld.Block.COPPER,
				  VoxelWorld.Block.IRON, VoxelWorld.Block.GOLD, VoxelWorld.Block.DIAMOND,
				  VoxelWorld.Block.FLOWER_RED, VoxelWorld.Block.FLOWER_BLUE,
				  VoxelWorld.Block.FLOWER_YELLOW, VoxelWorld.Block.FLOWER_PURPLE]:
			_add_to_inventory(b, 999)
		has_hell_compass = true
		has_purgatory_compass = true
		has_heaven_key = true
		has_rough_blade = true
	else:
		_add_to_inventory(VoxelWorld.Block.SOIL, 10)
		_add_to_inventory(VoxelWorld.Block.STONEHARD, 8)
		_add_to_inventory(VoxelWorld.Block.TIMBER, 6)
		_add_to_inventory(VoxelWorld.Block.VERDANT, 4)
		_add_to_inventory(VoxelWorld.Block.SAND, 4)
		_add_to_inventory(VoxelWorld.Block.PORTAL_FRAME, 6)
	_refresh_hotbar()

func take_damage(amount: float) -> void:
	if creative_mode:
		return
	var dr = 0.0
	if inv_ui and inv_ui.has_method("get_armor_reduction"):
		dr = inv_ui.get_armor_reduction()
	var final_dmg = amount * (1.0 - dr)
	health = max(0.0, health - final_dmg)
	if dr > 0.0:
		status_label.text = "Took %.0f damage (armor -%d%%)" % [final_dmg, int(dr * 100)]
	else:
		status_label.text = "Took %.0f damage!" % final_dmg
	_update_hud()
	if health <= 0:
		if has_stem or _consume_stem_from_inv():
			has_stem = false
			health = max_health * 0.5
			status_label.text = "STEM shattered — you survived!"
			_update_hud()
			return
		status_label.text = "You were defeated... returning to Overworld"
		health = max_health
		if dim_manager:
			dim_manager.go_to_dimension(0)
		position = Vector3(0, 22, 0)

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.position = Vector3(0, 1.65, 0)
	camera.current = true
	camera.fov = 75
	add_child(camera)

func _build_ray() -> void:
	ray = RayCast3D.new()
	ray.target_position = Vector3(0, 0, -reach_distance)
	ray.enabled = true
	ray.collide_with_areas = true
	ray.collide_with_bodies = true
	camera.add_child(ray)

func _build_joystick() -> void:
	joystick = Control.new()
	joystick.set_script(load("res://scripts/virtual_joystick.gd"))
	joystick.anchor_left = 0.02
	joystick.anchor_top = 0.55
	joystick.anchor_right = 0.02
	joystick.anchor_bottom = 0.55
	joystick.offset_right = 180
	joystick.offset_bottom = 180
	hud.add_child(joystick)
	joystick.joystick_moved.connect(func(dir: Vector2):
		joystick_dir = dir
	)

func _build_settings() -> void:
	settings = CanvasLayer.new()
	settings.set_script(load("res://scripts/settings_menu.gd"))
	add_child(settings)
	settings.settings_changed.connect(_on_settings_changed)
	guidebook = CanvasLayer.new()
	guidebook.set_script(load("res://scripts/guidebook.gd"))
	add_child(guidebook)
	inv_ui = CanvasLayer.new()
	inv_ui.set_script(load("res://scripts/inventory_ui.gd"))
	add_child(inv_ui)
	inv_ui.selection_changed.connect(func(slot):
		selected_slot = slot
	)
	inv_ui.call("give_starter", creative_mode)
	pause_menu = CanvasLayer.new()
	pause_menu.set_script(load("res://scripts/pause_menu.gd"))
	add_child(pause_menu)
	pause_menu.resume_pressed.connect(func(): pass)
	pause_menu.open_settings.connect(func():
		if settings: settings.toggle()
	)
	pause_menu.save_pressed.connect(func():
		var main = get_parent()
		if main and main.get("world_manager") and main.world_manager.has_method("_save"):
			main.world_manager._save()
			status_label.text = "World list saved"
		else:
			status_label.text = "Saved"
	)
	pause_menu.quit_pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene()
	)

func _on_settings_changed() -> void:
	look_sensitivity = settings.look_sensitivity
	if joystick and joystick.has_method("set_scale_factor"):
		joystick.set_scale_factor(settings.joystick_scale)
	fps_label.visible = settings.show_fps

func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)

	var title = Label.new()
	title.text = "MASK"
	title.position = Vector2(12, 6)
	title.add_theme_font_size_override("font_size", 18)
	hud.add_child(title)

	health_label = Label.new()
	health_label.position = Vector2(12, 28)
	health_label.add_theme_font_size_override("font_size", 14)
	hud.add_child(health_label)

	time_label = Label.new()
	time_label.position = Vector2(12, 48)
	time_label.add_theme_font_size_override("font_size", 12)
	hud.add_child(time_label)

	status_label = Label.new()
	status_label.position = Vector2(12, 68)
	status_label.add_theme_font_size_override("font_size", 13)
	hud.add_child(status_label)

	inv_label = Label.new()
	inv_label.position = Vector2(12, 92)
	inv_label.add_theme_font_size_override("font_size", 12)
	hud.add_child(inv_label)

	selected_label = Label.new()
	selected_label.position = Vector2(12, 210)
	selected_label.add_theme_font_size_override("font_size", 13)
	hud.add_child(selected_label)

	item_label = Label.new()
	item_label.position = Vector2(12, 232)
	item_label.add_theme_font_size_override("font_size", 12)
	hud.add_child(item_label)

	compass_label = Label.new()
	compass_label.position = Vector2(12, 255)
	compass_label.add_theme_font_size_override("font_size", 13)
	hud.add_child(compass_label)

	call_label = Label.new()
	call_label.position = Vector2(400, 8)
	call_label.add_theme_font_size_override("font_size", 16)
	call_label.modulate = Color(1.0, 0.7, 0.3)
	hud.add_child(call_label)

	fps_label = Label.new()
	fps_label.position = Vector2(1100, 8)
	fps_label.add_theme_font_size_override("font_size", 14)
	fps_label.visible = false
	hud.add_child(fps_label)

	# Center crosshair for tap-to-mine / attack
	var cross = Label.new()
	cross.name = "Crosshair"
	cross.text = "✚"
	cross.add_theme_font_size_override("font_size", 28)
	cross.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cross.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Will be recentered each frame-ish via anchors
	cross.anchor_left = 0.5
	cross.anchor_right = 0.5
	cross.anchor_top = 0.5
	cross.anchor_bottom = 0.5
	cross.offset_left = -20
	cross.offset_right = 20
	cross.offset_top = -20
	cross.offset_bottom = 20
	cross.modulate = Color(1, 1, 1, 0.9)
	hud.add_child(cross)

	_add_touch_button("JUMP", Vector2(0.90, 0.50), "jump")
	_add_touch_button("SPRINT", Vector2(0.90, 0.62), "sprint")
	_add_touch_button("ATK", Vector2(0.90, 0.74), "attack")
	_add_touch_button("BREAK", Vector2(0.78, 0.74), "break")
	_add_touch_button("PLACE", Vector2(0.66, 0.74), "place")

	_add_touch_button("OVER", Vector2(0.28, 0.93), "dim0")
	_add_touch_button("HELL", Vector2(0.42, 0.93), "dim1")
	_add_touch_button("PURG", Vector2(0.56, 0.93), "dim2")
	_add_touch_button("HEAV", Vector2(0.62, 0.93), "dim3")
	_add_touch_button("MOON", Vector2(0.76, 0.93), "dim4")
	_add_touch_button("SET", Vector2(0.92, 0.08), "settings")
	_add_touch_button("GUIDE", Vector2(0.80, 0.08), "guide")
	_add_touch_button("INV", Vector2(0.68, 0.08), "inv")
	_add_touch_button("PAUSE", Vector2(0.56, 0.08), "pause")
	_add_touch_button("CRAFT", Vector2(0.44, 0.08), "craft")

	_update_hud()

func _add_touch_button(caption: String, anchor: Vector2, action: String) -> void:
	var button = Button.new()
	button.text = caption
	button.anchor_left = anchor.x - 0.055
	button.anchor_right = anchor.x + 0.045
	button.anchor_top = anchor.y - 0.045
	button.anchor_bottom = anchor.y + 0.035
	button.pressed.connect(func():
		match action:
			"jump":
				if creative_mode:
					velocity.y = 8.0
				elif is_on_floor():
					velocity.y = jump_velocity
			"sprint":
				sprinting = not sprinting
			"break":
				_try_break()
			"place":
				_try_place()
			"attack":
				_try_attack()
			"dim0":
				_try_enter_dimension(0)
			"dim1":
				_try_enter_dimension(1)
			"dim2":
				_try_enter_dimension(2)
			"dim3":
				_try_enter_dimension(3)
			"dim4":
				_try_enter_dimension(4)
			"settings":
				if settings: settings.toggle()
			"guide":
				if guidebook: guidebook.toggle()
			"inv":
				if inv_ui: inv_ui.toggle()
			"pause":
				if pause_menu: pause_menu.toggle()
			"craft":
				_toggle_craft()
	)
	hud.add_child(button)

func _try_enter_dimension(dim: int) -> void:
	if not dim_manager:
		return
	if dim == 0:
		dim_manager.go_to_dimension(0)
		status_label.text = "Overworld"
		return
	# Require keys for other dimensions
	if dim == 1 and not has_hell_compass:
		status_label.text = "Need Hell Compass (defeat Hell Guardian in caves)"
		return
	if dim == 2 and not has_purgatory_compass:
		status_label.text = "Need Purgatory Compass (defeat Sentinel on mountains)"
		return
	if dim == 3 and not has_heaven_key:
		status_label.text = "Need Heaven Key (find Cupid on high peaks)"
		return
	# dim 4 Moon — always accessible, no special equipment
	dim_manager.go_to_dimension(dim)
	match dim:
		1: status_label.text = "Entered Hell"
		2: status_label.text = "Entered Purgatory"
		3: status_label.text = "Entered Heaven"
		4: status_label.text = "Entered the Moon — barren and silent"


func _crosshair_action() -> void:
	# Single tap on crosshair: attack entity if any, otherwise mine block
	if attack_cooldown > 0.0:
		return
	# Prefer entity hit
	if ray.is_colliding():
		var collider = ray.get_collider()
		var node = collider
		while node:
			if node is MaskBoss or node is RaidBoss:
				_try_attack()
				return
			if node is MaskChest:
				_try_attack()
				return
			node = node.get_parent()
		# No entity — mine the block
		_try_break()
	else:
		status_label.text = "Nothing in crosshair"

func _consume_stem_from_inv() -> bool:
	if not inv_ui:
		return false
	# check hotbar for STEM id 800
	if inv_ui.get("hotbar"):
		for i in range(inv_ui.hotbar.size()):
			var s = inv_ui.hotbar[i]
			if s.get("id", -1) == 800:
				inv_ui.hotbar[i] = {"id": -1, "count": 0}
				inv_ui._refresh_all()
				return true
	return false

func _toggle_craft() -> void:
	if craft_ui and is_instance_valid(craft_ui):
		craft_ui.queue_free()
		craft_ui = null
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	craft_ui = Panel.new()
	craft_ui.set_script(load("res://scripts/crafting_ui.gd"))
	hud.add_child(craft_ui)
	craft_ui.anchor_left = 0.3
	craft_ui.anchor_right = 0.7
	craft_ui.anchor_top = 0.25
	craft_ui.anchor_bottom = 0.75
	var use_3x3 = near_craft_table
	craft_ui.setup(use_3x3, inv_ui)
	craft_ui.crafted.connect(func(id, count):
		if inv_ui:
			inv_ui.add_item(id, count)
			if id == 800:
				has_stem = true
				status_label.text = "STEM crafted — holds death once"
		_update_hud()
	)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func get_weapon_damage() -> float:
	var id = get_hand_item() if has_method("get_hand_item") else -1
	match id:
		110: return 14.0   # wood sword
		111: return 18.0   # stone
		112: return 24.0   # iron
		113: return 20.0   # gold
		114: return 32.0   # diamond
		115: return 22.0   # spear
		116: return 28.0   # battle axe
		117: return 30.0   # war hammer
		118: return 12.0   # dagger
		119: return 36.0   # crystal blade
		_:
			return 18.0 if has_rough_blade else 12.0

func _try_attack() -> void:

	if attack_cooldown > 0.0:
		return
	attack_cooldown = 0.45
	# Raycast for boss
	if ray.is_colliding():
		var collider = ray.get_collider()
		var node = collider
		while node:
			if node is MaskBoss:
				var dmg = get_weapon_damage()
				node.take_damage(dmg)
				status_label.text = "Hit %s" % node._boss_name()
				return
			if node is RaidBoss:
				var dmg = get_weapon_damage()
				node.take_damage(dmg)
				status_label.text = "Hit %s" % node._boss_name()
				return
			if node is MaskChest:
				var loot = node.try_open()
				if loot.size() > 0:
					receive_loot(loot)
				else:
					status_label.text = "Chest already opened"
				return
			node = node.get_parent()
	status_label.text = "Attack swung"

func on_boss_call_sign(type: int, boss_name: String) -> void:
	if call_label:
		call_label.text = "⚔ CALL SIGN: %s ⚔" % boss_name
		# clear after a few seconds
		get_tree().create_timer(2.8).timeout.connect(func():
			if call_label: call_label.text = ""
		)

func receive_loot(loot: Dictionary) -> void:
	var parts: PackedStringArray = []
	for k in loot.keys():
		_add_to_inventory(k, loot[k])
		if inv_ui and inv_ui.has_method("add_item"):
			inv_ui.add_item(k, loot[k])
			if k == 800:
				has_stem = true
		parts.append("%s x%d" % [_block_name(k), loot[k]])
	status_label.text = "Chest: " + ", ".join(parts)
	_update_hud()

func on_raid_defeated(type: int) -> void:
	match type:
		0:
			status_label.text = "Lucifer defeated! Hell is subdued."
		1:
			status_label.text = "God defeated! Heaven acknowledges you."
	_update_hud()

func on_boss_defeated(type: int) -> void:


	match type:
		0:  # HELL_GUARDIAN
			has_hell_compass = true
			status_label.text = "Hell Compass obtained!"
		1:  # PURGATORY_SENTINEL
			has_purgatory_compass = true
			status_label.text = "Purgatory Compass obtained!"
		2:  # CUPID
			has_heaven_key = true
			status_label.text = "Heaven Key obtained from Cupid!"
	_update_hud()

func _block_name(t: int) -> String:
	match t:
		VoxelWorld.Block.SOIL: return "Soil"
		VoxelWorld.Block.VERDANT: return "Verdant"
		VoxelWorld.Block.STONEHARD: return "Stonehard"
		VoxelWorld.Block.CRYSTALITE: return "Crystalite"
		VoxelWorld.Block.TIMBER: return "Timber"
		VoxelWorld.Block.DEEPSLATE: return "Deepslate"
		VoxelWorld.Block.CORE_STONE: return "Core Stone"
		VoxelWorld.Block.SAND: return "Sand"
		VoxelWorld.Block.SNOW: return "Snow"
		VoxelWorld.Block.ICE: return "Ice"
		VoxelWorld.Block.MOSS: return "Moss"
		VoxelWorld.Block.BASALT: return "Basalt"
		VoxelWorld.Block.CLAY: return "Clay"
		VoxelWorld.Block.PORTAL_FRAME: return "Portal Frame"
		VoxelWorld.Block.COAL: return "Coal"
		VoxelWorld.Block.COPPER: return "Copper"
		VoxelWorld.Block.IRON: return "Iron"
		VoxelWorld.Block.GOLD: return "Gold"
		VoxelWorld.Block.DIAMOND: return "Diamond"
		VoxelWorld.Block.FLOWER_RED: return "Red Flower"
		VoxelWorld.Block.FLOWER_BLUE: return "Blue Flower"
		VoxelWorld.Block.FLOWER_YELLOW: return "Yellow Flower"
		VoxelWorld.Block.FLOWER_PURPLE: return "Purple Flower"
		_: return "Unknown"

func _add_to_inventory(type: int, amount: int = 1) -> void:
	if type == VoxelWorld.Block.AIR or type == VoxelWorld.Block.CORE_STONE:
		return
	inventory[type] = inventory.get(type, 0) + amount
	if type == VoxelWorld.Block.CRYSTALITE and inventory.get(type, 0) >= 3 and not has_crystal_shard:
		has_crystal_shard = true
		status_label.text = "Formed Crystal Shard"
	if type == VoxelWorld.Block.STONEHARD and inventory.get(VoxelWorld.Block.TIMBER, 0) >= 2 and not has_rough_blade:
		has_rough_blade = true
		status_label.text = "Crafted Rough Blade"
	_refresh_hotbar()
	_update_hud()

func _refresh_hotbar() -> void:
	hotbar.clear()
	for k in inventory.keys():
		if inventory[k] > 0:
			hotbar.append(k)
			if hotbar.size() >= max_hotbar:
				break
	if selected_slot >= hotbar.size():
		selected_slot = max(0, hotbar.size() - 1)

func _selected_block() -> int:
	if hotbar.is_empty():
		return VoxelWorld.Block.AIR
	return hotbar[selected_slot]

func _update_hud() -> void:
	health_label.text = "HP: %.0f / %.0f" % [health, max_health]
	var lines: PackedStringArray = []
	for t in inventory:
		if inventory[t] > 0:
			lines.append("%s: %d" % [_block_name(t), inventory[t]])
	inv_label.text = "Inv\n" + ("\n".join(lines) if lines.size() > 0 else "(empty)")

	var sel = _selected_block()
	selected_label.text = "Sel: [%d] %s" % [selected_slot + 1, _block_name(sel)] if sel != VoxelWorld.Block.AIR else "Sel: (none)"

	var items = []
	if has_crystal_shard: items.append("Shard")
	if has_rough_blade: items.append("Blade")
	if has_hell_compass: items.append("HellCompass")
	if has_purgatory_compass: items.append("PurgCompass")
	if has_heaven_key: items.append("HeavenKey")
	item_label.text = "Keys/Items: " + (", ".join(items) if items.size() > 0 else "none")

func _unhandled_input(event: InputEvent) -> void:
	if settings and settings.open:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look(event.relative)
	elif event is InputEventScreenTouch:
		if event.pressed:
			tap_start = event.position
			tap_time = Time.get_ticks_msec() / 1000.0
			pending_tap = true
			# Right side still used for look drag
			touch_look = event.position.x > get_viewport().size.x * 0.42
		else:
			# Short tap without much movement = mine / attack through crosshair
			if pending_tap:
				var held = (Time.get_ticks_msec() / 1000.0) - tap_time
				var moved = event.position.distance_to(tap_start)
				if held < 0.35 and moved < 28.0:
					_crosshair_action()
			pending_tap = false
			touch_look = false
	elif event is InputEventScreenDrag:
		if event.position.distance_to(tap_start) > 25.0:
			pending_tap = false  # it's a drag, not a tap
		if touch_look:
			_look(event.relative)
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if settings: settings.toggle()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_7:
			var idx = event.keycode - KEY_1
			if idx < hotbar.size():
				selected_slot = idx
				_update_hud()
		elif event.keycode == KEY_F1:
			_try_enter_dimension(0)
		elif event.keycode == KEY_F2:
			_try_enter_dimension(1)
		elif event.keycode == KEY_F3:
			_try_enter_dimension(2)
		elif event.keycode == KEY_F4:
			_try_enter_dimension(3)
		elif event.keycode == KEY_F5:
			_try_enter_dimension(4)
	
	elif event is InputEventJoypadButton and event.pressed:
		# Minecraft-style controller layout (functional mapping only)
		match event.button_index:
			JOY_BUTTON_SOUTH:  # A / X — Jump
				if creative_mode:
					velocity.y = 8.0
				elif is_on_floor():
					velocity.y = jump_velocity
			JOY_BUTTON_EAST:  # B / Circle — Drop / cancel sprint
				sprinting = false
			JOY_BUTTON_WEST:  # X / Square — Inventory hint / status
				status_label.text = "Hotbar: use D-Pad 1- style / face for slots"
			JOY_BUTTON_NORTH:  # Y / Triangle — Sprint (like sprint key)
				sprinting = not sprinting
			JOY_BUTTON_LEFT_SHOULDER:  # LB / L1 — Hotbar prev
				if hotbar.size() > 0:
					selected_slot = (selected_slot - 1) % hotbar.size()
					_update_hud()
			JOY_BUTTON_RIGHT_SHOULDER:  # RB / R1 — Hotbar next
				if hotbar.size() > 0:
					selected_slot = (selected_slot + 1) % hotbar.size()
					_update_hud()
			JOY_BUTTON_LEFT_STICK:  # L3 — Sprint toggle
				sprinting = not sprinting
			JOY_BUTTON_RIGHT_STICK:  # R3 — Sneak/slow (halve speed via flag)
				sprinting = false
			JOY_BUTTON_START:  # Menu / Options — Settings (pause-like)
				if settings: settings.toggle()
			JOY_BUTTON_BACK:  # View / Share — Guide
				if guidebook: guidebook.toggle()
			JOY_BUTTON_DPAD_UP:
				if hotbar.size() > 0:
					selected_slot = 0
					_update_hud()
			JOY_BUTTON_DPAD_RIGHT:
				if hotbar.size() > 1:
					selected_slot = min(1, hotbar.size() - 1)
					_update_hud()
			JOY_BUTTON_DPAD_DOWN:
				if hotbar.size() > 2:
					selected_slot = min(2, hotbar.size() - 1)
					_update_hud()
			JOY_BUTTON_DPAD_LEFT:
				if hotbar.size() > 3:
					selected_slot = min(3, hotbar.size() - 1)
					_update_hud()

elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_crosshair_action()  # mine or attack under crosshair
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_try_place()

func _look(delta: Vector2) -> void:
	rotate_y(-delta.x * look_sensitivity)
	pitch = clamp(pitch - delta.y * look_sensitivity, -1.45, 1.45)
	camera.rotation.x = pitch

func _get_world() -> VoxelWorld:
	var main = get_parent()
	if main and main.get("overworld"):
		return main.overworld
	for c in get_parent().get_children():
		if c is VoxelWorld:
			return c
	return null

func _try_break() -> void:
	var world = _get_world()
	if not world or not ray.is_colliding():
		status_label.text = "Nothing in reach"
		return
	var hit = ray.get_collision_point()
	var normal = ray.get_collision_normal()
	var inside = hit - normal * 0.1
	var g = world.world_to_grid(inside)
	var broken = world.break_block(g.x, g.y, g.z)
	if broken != VoxelWorld.Block.AIR:
		_add_to_inventory(broken, 1)
		if inv_ui and inv_ui.has_method("add_item"):
			inv_ui.add_item(broken, 1)
		status_label.text = "Got %s" % _block_name(broken)
	else:
		status_label.text = "Cannot break"

func get_hand_item() -> int:
	if inv_ui and inv_ui.has_method("get_selected_item"):
		var v = inv_ui.get_selected_item()
		if v >= 0:
			return v
	return _selected_block()

func _try_place() -> void:

	var world = _get_world()
	var type = get_hand_item()
	if not world or type == VoxelWorld.Block.AIR:
		status_label.text = "No block / wrong dim"
		return
	if inventory.get(type, 0) <= 0:
		status_label.text = "Out of %s" % _block_name(type)
		return
	if not ray.is_colliding():
		status_label.text = "Nothing to place on"
		return
	var hit = ray.get_collision_point()
	var normal = ray.get_collision_normal()
	var place_pos = hit + normal * 0.1
	var g = world.world_to_grid(place_pos)
	var player_grid = world.world_to_grid(global_position)
	if abs(g.x - player_grid.x) <= 1 and abs(g.y - player_grid.y) <= 1 and abs(g.z - player_grid.z) <= 1:
		status_label.text = "Too close"
		return
	if world.place_block(g.x, g.y, g.z, type):
		if not creative_mode:
			if inv_ui and inv_ui.has_method("consume_selected"):
				inv_ui.consume_selected()
			elif inventory.has(type):
				inventory[type] -= 1
				if inventory[type] <= 0:
					inventory.erase(type)
				_refresh_hotbar()
		_update_hud()
		status_label.text = "Placed %s" % _block_name(type)
	else:
		status_label.text = "Cannot place"


func _update_compass() -> void:
	if not compass_label:
		return
	var parts: PackedStringArray = []
	var keys = []
	if has_hell_compass:
		keys.append((0, "Hell"))
	if has_purgatory_compass:
		keys.append((1, "Purg"))
	if has_heaven_key:
		keys.append((2, "Heav"))
	for k in keys:
		var idx = k[0]
		var name = k[1]
		if portal_positions.has(idx):
			var target: Vector3 = portal_positions[idx]
			var to = target - global_position
			to.y = 0
			var dist = to.length()
			var angle = rad_to_deg(atan2(to.x, -to.z))  # relative-ish
			# Cardinal direction from player forward would be better; simple world dir:
			var dir_txt = "?"
			if dist < 3.0:
				dir_txt = "HERE"
			else:
				var a = fposmod(angle + 180.0, 360.0)
				if a < 22.5 or a >= 337.5: dir_txt = "S"
				elif a < 67.5: dir_txt = "SW"
				elif a < 112.5: dir_txt = "W"
				elif a < 157.5: dir_txt = "NW"
				elif a < 202.5: dir_txt = "N"
				elif a < 247.5: dir_txt = "NE"
				elif a < 292.5: dir_txt = "E"
				else: dir_txt = "SE"
			parts.append("%s %s %.0fm" % [name, dir_txt, dist])
	compass_label.text = "Compass: " + (" | ".join(parts) if parts.size() > 0 else "none")

func _physics_process(delta: float) -> void:
	if settings and settings.open:
		return

	# PS4 right stick look
	var look_x = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var look_y = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	if abs(look_x) > 0.15 or abs(look_y) > 0.15:
		_look(Vector2(look_x, look_y) * gamepad_look_sens * 16.0 * delta)
	attack_cooldown = max(0.0, attack_cooldown - delta)

	# Minecraft-style triggers: RT mine/attack, LT place
	var rt = Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT)
	var lt = Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT)
	if rt > 0.6 and attack_cooldown <= 0.0:
		_crosshair_action()
	if lt > 0.6:
		# place with cooldown via attack_cooldown reuse lightly
		if attack_cooldown <= 0.0:
			_try_place()
			attack_cooldown = 0.25


	if creative_mode:
		# Creative flight
		if Input.is_action_pressed("ui_accept") or (sprinting and Input.is_key_pressed(KEY_SPACE)):
			velocity.y = 8.0
		elif Input.is_key_pressed(KEY_SHIFT) or sprinting:
			velocity.y = -8.0
		else:
			velocity.y = move_toward(velocity.y, 0, 20 * delta)
	else:
		if not is_on_floor():
			velocity.y -= gravity * delta
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = jump_velocity

	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	# PS4 / generic gamepad left stick
	var gp_move = Vector2(
		Input.get_joy_axis(0, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	)
	if gp_move.length() > 0.2:
		input_dir = gp_move
	if joystick_dir.length() > 0.05:
		input_dir = joystick_dir

	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed = sprint_speed if sprinting or Input.is_key_pressed(KEY_SHIFT) else move_speed
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed * 6 * delta)
		velocity.z = move_toward(velocity.z, 0, speed * 6 * delta)
	move_and_slide()

	var main = get_parent()
	if main and main.has_method("get_time_string"):
		time_label.text = main.get_time_string()

	if fps_label and fps_label.visible:
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	_update_compass()
	# Detect nearby crafting table for 3x3
	near_craft_table = false
	var main = get_parent()
	if main and main.get("overworld"):
		for c in main.overworld.get_children():
			if c.has_meta("craft_table") and global_position.distance_to(c.global_position) < 4.0:
				near_craft_table = true
				break

