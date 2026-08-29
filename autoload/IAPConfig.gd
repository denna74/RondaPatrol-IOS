extends Node

enum SkuType { CONSUMABLE, NON_CONSUMABLE }

const SKUS := {
	"instant_coins_1": "com.rondapatrol.instant_coins_1",
	"instant_coins_2": "com.rondapatrol.instant_coins_2",
	"instant_coins_3": "com.rondapatrol.instant_coins_3",
}

const SKU_TYPES := {
	"com.rondapatrol.instant_coins_1": SkuType.CONSUMABLE,
	"com.rondapatrol.instant_coins_2": SkuType.CONSUMABLE,
	"com.rondapatrol.instant_coins_3": SkuType.CONSUMABLE,
}

const COIN_REWARDS := {
	"com.rondapatrol.instant_coins_1": 2000,
	"com.rondapatrol.instant_coins_2": 5000,
	"com.rondapatrol.instant_coins_3": 8000,
}

static func get_sku(key: String) -> String:
	return SKUS.get(key, "")

static func get_coin_reward(sku: String) -> int:
	return COIN_REWARDS.get(sku, 0)

static func get_type(sku: String) -> SkuType:
	return SKU_TYPES.get(sku, SkuType.CONSUMABLE)
