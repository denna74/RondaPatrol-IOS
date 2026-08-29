extends Node

# Headless regression test for MapGenerator connectivity fix.
# Verifies buildings never seal off walkable space:
#   - all jimpitan coins reachable from player start
#   - all poskamlings reachable from player start
#   - player start is never in a tiny pocket boxed in by buildings
# Run: godot --headless res://tests/map_generator_test.tscn

const MapGenerator = preload("res://scenes/gameplay/MapGenerator.gd")

var _failures: int = 0


func _ready() -> void:
	var levels := [1, 3, 5, 10, 20, 40, 80]
	var iters := 100
	var coin_unreachable := 0
	var poskamling_unreachable := 0
	var start_tiny := 0
	var maps_checked := 0
	for lvl in levels:
		for i in range(iters):
			var md = MapGenerator.generate(lvl)
			var grid: Array = md["grid"]
			var cols: int = md["cols"]
			var rows: int = md["rows"]
			var start: Vector2i = md["player_start"]
			var reach := _reachable_set(grid, cols, rows, start)
			maps_checked += 1
			if reach.size() <= 6:
				start_tiny += 1
			for jp in md["jimpitans"]:
				if not reach.has(Vector2i(jp.x, jp.y)):
					coin_unreachable += 1
			for pp in md["poskamlings"]:
				if not reach.has(Vector2i(pp.x, pp.y)):
					poskamling_unreachable += 1
	_check(coin_unreachable == 0, "all jimpitan coins reachable (unreachable=%d)" % coin_unreachable)
	_check(poskamling_unreachable == 0, "all poskamlings reachable (unreachable=%d)" % poskamling_unreachable)
	_check(start_tiny == 0, "player start never boxed in by buildings (tiny=%d)" % start_tiny)
	print("TEST SUMMARY: failures=", _failures, " maps_checked=", maps_checked)
	get_tree().quit(0 if _failures == 0 else 1)


func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS: ", name)
	else:
		_failures += 1
		push_error("FAIL: " + name)


func _reachable_set(grid: Array, cols: int, rows: int, start: Vector2i) -> Dictionary:
	var seen := {}
	var stack: Array = [start]
	seen[start] = true
	while stack.size() > 0:
		var c: Vector2i = stack.pop_back()
		for n: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nxt: Vector2i = c + n
			if nxt.x < 0 or nxt.x >= cols or nxt.y < 0 or nxt.y >= rows:
				continue
			if seen.has(nxt):
				continue
			if grid[nxt.x][nxt.y] == 0 or grid[nxt.x][nxt.y] == 2:
				seen[nxt] = true
				stack.append(nxt)
	return seen
