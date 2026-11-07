extends Node
class_name WorldManager

signal world_selected(seed: int, name: String, creative: bool)

const SAVE_PATH := "user://mask_worlds.cfg"

var worlds: Array = []
var current_seed := 91
var current_name := "Default"
var creative_mode := false

func _ready() -> void:
	_load()
	if worlds.is_empty():
		_add_world("Starter Valley", 91, false)
		_add_world("Crystal Peaks", 777, false)
		_add_world("Creative Flat", 42, true)
		_save()

func _add_world(wname: String, seed: int, creative: bool) -> void:
	worlds.append({
		"name": wname,
		"seed": seed,
		"creative": creative,
		"created": Time.get_datetime_string_from_system()
	})

func create_random_world(wname: String, creative: bool = false) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var seed = rng.randi()
	var entry = {
		"name": wname if wname != "" else "World %d" % (worlds.size() + 1),
		"seed": seed,
		"creative": creative,
		"created": Time.get_datetime_string_from_system()
	}
	worlds.append(entry)
	_save()
	return entry

func select_world(index: int) -> void:
	if index < 0 or index >= worlds.size():
		return
	var w = worlds[index]
	current_seed = w.seed
	current_name = w.name
	creative_mode = w.creative
	emit_signal("world_selected", current_seed, current_name, creative_mode)

func get_world_list() -> Array:
	return worlds

func _save() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("meta", "count", worlds.size())
	for i in range(worlds.size()):
		var w = worlds[i]
		cfg.set_value("w%d" % i, "name", w.name)
		cfg.set_value("w%d" % i, "seed", w.seed)
		cfg.set_value("w%d" % i, "creative", w.creative)
		cfg.set_value("w%d" % i, "created", w.get("created", ""))
	cfg.save(SAVE_PATH)

func _load() -> void:
	worlds.clear()
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	var count = int(cfg.get_value("meta", "count", 0))
	for i in range(count):
		worlds.append({
			"name": str(cfg.get_value("w%d" % i, "name", "World")),
			"seed": int(cfg.get_value("w%d" % i, "seed", 1)),
			"creative": bool(cfg.get_value("w%d" % i, "creative", false)),
			"created": str(cfg.get_value("w%d" % i, "created", ""))
		})
