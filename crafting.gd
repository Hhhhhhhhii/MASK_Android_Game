extends RefCounted
class_name MaskCrafting

# MASK crafting recipes — 2x2 inventory or 3x3 table
# Pattern strings use item ids; "." empty
# Result: [id, count]

static func recipes_2x2() -> Array:
	return [
		{"grid": ["5", "5", ".", "."], "out": [110, 1]},      # timber -> wood sword (rough)
		{"grid": ["5", ".", "5", "."], "out": [101, 1]},     # wood helm piece rough
		{"grid": ["5", "5", "5", "5"], "out": [102, 1]},     # wood chest
		{"grid": ["15", "5", ".", "."], "out": [100, 4]},    # coal+timber -> torch x4
		{"grid": ["3", "5", ".", "."], "out": [111, 1]},     # stone sword
		{"grid": ["17", "5", ".", "."], "out": [112, 1]},    # iron sword
	]

static func recipes_3x3() -> Array:
	var r = recipes_2x2().duplicate(true)
	r.append_array([
		{"grid": ["5","5","5","5",".","5","5",".","5"], "out": [102, 1]},  # chest pattern
		{"grid": ["5","5","5","5",".","5",".",".","."], "out": [101, 1]},  # helm
		{"grid": ["5","5","5","5","5","5",".","5","."], "out": [103, 1]},  # legs
		{"grid": [".",".",".","5",".","5","5",".","5"], "out": [104, 1]},  # boots
		{"grid": ["17","17","17","17",".","17",".",".","."], "out": [301, 1]},
		{"grid": ["17","17","17","17",".","17","17",".","17"], "out": [302, 1]},
		{"grid": ["17","17","17","17","17","17",".","17","."], "out": [303, 1]},
		{"grid": [".",".",".","17",".","17","17",".","17"], "out": [304, 1]},
		{"grid": ["19","19","19","19",".","19",".",".","."], "out": [501, 1]},
		{"grid": ["19","5","." ,".","5",".",".","5","."], "out": [114, 1]}, # diamond sword
		{"grid": ["4","4","4","4","100","4","4","4","4"], "out": [800, 1]}, # STEM from crystal+torch center
		{"grid": ["7","7","7","7","4","7","7","7","7"], "out": [701, 1]},  # core helm-ish
	])
	return r

static func match_recipe(cells: Array, table_3x3: bool) -> Array:
	# cells: array of id ints, size 4 or 9, -1 empty
	var recipes = recipes_3x3() if table_3x3 else recipes_2x2()
	var size = 9 if table_3x3 else 4
	for rec in recipes:
		var g: Array = rec.grid
		if g.size() != size:
			continue
		var ok = true
		for i in range(size):
			var need = g[i]
			var have = cells[i] if i < cells.size() else -1
			if need == ".":
				if have >= 0:
					ok = false
					break
			else:
				if str(have) != need:
					ok = false
					break
		if ok:
			return rec.out  # [id, count]
	return []
