extends Node

# Headless test runner for AdsManager fixes F1-F4.
# Run: godot --headless res://tests/ads_manager_test.tscn

const StubAdsManager = preload("res://tests/stub_ads_manager.gd")

var _failures: int = 0


func _ready() -> void:
	await _test_load_timeout_aborts()
	await _test_skipped_ad_aborts()
	await _test_init_guard_skips_initialize()
	await _test_pending_flow_fails_on_init_failure()
	await _test_normal_completed_flow_still_earns()
	_test_level_track_compiles()
	print("TEST SUMMARY: failures=", _failures)
	get_tree().quit(0 if _failures == 0 else 1)


func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS: ", name)
	else:
		_failures += 1
		push_error("FAIL: " + name)


func _make_manager() -> StubAdsManager:
	var m: StubAdsManager = StubAdsManager.new()
	add_child(m)
	return m


func _make_label() -> Label:
	var label := Label.new()
	add_child(label)
	return label


func _free_node(n: Node) -> void:
	n.queue_free()


func _test_load_timeout_aborts() -> void:
	var m := _make_manager()
	var got := {"failed": false}
	m.life_reward_failed.connect(func(): got["failed"] = true)
	m._kick_off_flow(_make_label())
	_check(m.is_flow_active(), "F1 flow active right after kickoff")
	await get_tree().create_timer(1.0).timeout
	_check(got["failed"], "F1 load timeout emits life_reward_failed")
	_check(not m.is_flow_active(), "F1 flow inactive after load timeout")
	_free_node(m)


func _test_skipped_ad_aborts() -> void:
	var m := _make_manager()
	var got := {"failed": false}
	m.life_reward_failed.connect(func(): got["failed"] = true)
	m._kick_off_flow(_make_label())
	UnityAds.ad_loaded.emit("Rewarded_Android")
	UnityAds.ad_completed.emit("Rewarded_Android", "SKIPPED")
	_check(got["failed"], "F2 skipped ad emits life_reward_failed")
	_check(not m.is_flow_active(), "F2 flow inactive after skip")
	_free_node(m)


func _test_init_guard_skips_initialize() -> void:
	var m := _make_manager()
	m._sdk_initialized = true
	m._ensure_sdk_initialized()
	_check(m.init_calls == 0, "F3 no initialize() call when already initialized")
	m._sdk_initialized = false
	m._ensure_sdk_initialized()
	_check(m.init_calls == 1, "F3 initialize() called when not yet initialized")
	_free_node(m)


func _test_pending_flow_fails_on_init_failure() -> void:
	var m := _make_manager()
	var got := {"failed": false}
	m.life_reward_failed.connect(func(): got["failed"] = true)
	var result: int = m.start_life_reward_flow(null)
	_check(result == m.StartResult.SDK_NOT_READY, "F4 SDK not ready returns SDK_NOT_READY")
	m._on_init_failed("TEST_ERROR", "init failed")
	_check(got["failed"], "F4 pending flow fails when SDK init fails")
	_check(m.is_flow_active() == false, "F4 no flow running after pending init failure")
	_free_node(m)


func _test_normal_completed_flow_still_earns() -> void:
	var m := _make_manager()
	var got := {"earned": false}
	m.life_reward_earned.connect(func(): got["earned"] = true)
	m._kick_off_flow(_make_label())
	UnityAds.ad_loaded.emit("Rewarded_Android")
	UnityAds.ad_completed.emit("Rewarded_Android", "COMPLETED")
	UnityAds.rewarded.emit("Rewarded_Android")
	_check(m.is_flow_active(), "F2 first COMPLETED ad keeps flow active")
	UnityAds.ad_loaded.emit("Rewarded_Android")
	UnityAds.ad_completed.emit("Rewarded_Android", "COMPLETED")
	UnityAds.rewarded.emit("Rewarded_Android")
	_check(got["earned"], "F2 normal 2-ad COMPLETED flow still earns reward")
	_check(not m.is_flow_active(), "F2 flow finished after reward")
	_free_node(m)


func _test_level_track_compiles() -> void:
	var script := load("res://scenes/menu/LevelTrack.gd")
	_check(script != null, "LevelTrack.gd compiles with autoloads registered")
