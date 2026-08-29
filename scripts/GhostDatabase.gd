class_name GhostDatabase
extends RefCounted

static func get_ghost_data(index: int) -> Dictionary:
	var db = _load_db()
	if index < 0 or index >= db.size():
		return {}
	return db[index]

static func get_ghost_coins(index: int) -> int:
	var data = get_ghost_data(index)
	return data.get("coins", 1)

static func get_ghost_name(index: int) -> String:
	var data = get_ghost_data(index)
	return data.get("name", "")

static func get_unlocked_count(current_level: int) -> int:
	var db = _load_db()
	var count = 0
	for entry in db:
		if entry.get("level", 0) <= current_level:
			count += 1
	return count

static func get_total_ghost_count() -> int:
	return _load_db().size()

static func _load_db() -> Array:
	var file = FileAccess.open("res://resources/ghosts.json", FileAccess.READ)
	if not file:
		return []
	var json = JSON.parse_string(file.get_as_text())
	if json is Array:
		return json
	return []
