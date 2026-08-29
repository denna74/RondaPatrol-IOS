class_name ItemData
extends RefCounted

enum ItemType { SENTER, KOPI, BALSEM, KACANG, CASSAVA, SAJEN }

static func get_items() -> Dictionary:
	return {
		"senter": {"name": "Senter", "price": 500, "effect": "pesugihan", "type": ItemType.SENTER, "duration": 5.0},
		"kopi": {"name": "Kopi", "price": 450, "effect": "reveal_ghosts", "type": ItemType.KOPI, "duration": 5.0},
		"balsem": {"name": "Balsem", "price": 400, "effect": "immunity", "type": ItemType.BALSEM, "duration": 5.0},
		"kacang": {"name": "Kacang", "price": 200, "effect": "restore_stamina", "type": ItemType.KACANG, "duration": 0.0},
		"cassava": {"name": "Cassava", "price": 300, "effect": "cassava", "type": ItemType.CASSAVA, "duration": 0.0},
		"sajen": {"name": "Sajen", "price": 350, "effect": "sajen", "type": ItemType.SAJEN, "duration": 0.0}
	}

static func get_item(id: String) -> Dictionary:
	return get_items().get(id, {})
