extends Area2D

const WAIT_TIME = 1.0 # 等待时间
const HOVER_OFFSET_X = 40.0 # 左右悬浮偏移

var player: Node2D = null
var wait_timer: float = 0.0
var bodies_in_range: Array[Node2D] = []
var swords: Array[Node2D] = []


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	swords = [$Sword, $Sword2]
	var offsets = [Vector2(-HOVER_OFFSET_X, 0), Vector2(HOVER_OFFSET_X, 0)]
	for i in swords.size():
		swords[i].top_level = true
		swords[i].set_player(player)
		swords[i].set_hover_offset(offsets[i])


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if not is_instance_valid(player):
			return
		for sword in swords:
			sword.set_player(player)

	global_position = player.global_position

	wait_timer -= delta
	if wait_timer <= 0.0:
		_find_and_fly()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("enemy"):
		return
	bodies_in_range.append(body)


func _on_body_exited(body: Node2D) -> void:
	bodies_in_range.erase(body)


func _find_and_fly() -> void:
	var any_flying = swords.any(func(s): return s.is_flying())
	if any_flying:
		return

	var target = _get_closest_enemy()
	if not is_instance_valid(target):
		wait_timer = WAIT_TIME
		return

	for sword in swords:
		sword.launch(target)
	wait_timer = WAIT_TIME


func _get_closest_enemy() -> Node2D:
	var closest: Node2D = null
	var min_dist = INF
	for body in bodies_in_range:
		if not is_instance_valid(body):
			continue
		var dist = player.global_position.distance_to(body.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = body
	return closest
