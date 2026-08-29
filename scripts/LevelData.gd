class_name LevelData
extends RefCounted

static func get_map_size(level: int) -> Vector2i:
	var s = 10 + mini(level, 30)
	return Vector2i(s, s)

static func get_building_count(level: int) -> int:
	return clampi(3 + mini(level, 67), 3, 70)

static func get_jimpitan_quota(level: int) -> int:
	return clampi(5 + level * 3 / 4, 5, 200)

static func get_ghost_count(walkable_area: int) -> int:
	return maxi(3, walkable_area / 30)

static func get_thief_chance(level: int) -> float:
	return clampf(0.1 + mini(level, 80) * 0.005, 0.1, 0.5)


static func get_thief_coin_range(level: int) -> Array:
	if level <= 10:
		return [1, 5]
	elif level <= 30:
		return [1, 10]
	elif level <= 60:
		return [1, 20]
	else:
		return [1, 25]


static func get_max_skills_for_3_stars(level: int) -> int:
	var s = 10 + mini(level, 30)
	var buildings = clampi(3 + mini(level, 67), 3, 70)
	var walls = s * 2 + s * 2 - 4
	var walkable = s * s - buildings * 4 - walls
	var ghosts = maxi(3, walkable / 30)
	return maxi(1, ghosts / 3)


