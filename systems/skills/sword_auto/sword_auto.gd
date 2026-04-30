extends Area2D

const WAIT_TIME = 1.0 # 每把剑攻击后的冷却时间
const STAGGER_TIME = 0.3 # 初始交错间隔
const HOVER_OFFSET_X = 40.0 # 左右悬浮偏移

var player: Node2D = null
var enemies_in_range: Array[Node2D] = []
var swords: Array[Node2D] = []
var sword_timers: Array[float] = []


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	swords = [$Sword, $Sword2]
	var offsets = [Vector2(-HOVER_OFFSET_X, 0), Vector2(HOVER_OFFSET_X, 0)]
	for i in swords.size():
		swords[i].top_level = true
		swords[i].set_player(player)
		swords[i].set_hover_offset(offsets[i])
		sword_timers.append(i * STAGGER_TIME)


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if not is_instance_valid(player):
			return
		for sword in swords:
			sword.set_player(player)

	global_position = player.global_position

	for i in swords.size():
		if not swords[i].is_idle():
			continue
		sword_timers[i] -= delta
		if sword_timers[i] <= 0.0:
			_try_launch(i)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("enemy"):
		return
	enemies_in_range.append(body)


func _on_body_exited(body: Node2D) -> void:
	enemies_in_range.erase(body)


func _try_launch(index: int) -> void:
	var target = _get_closest_enemy()
	if not is_instance_valid(target):
		sword_timers[index] = WAIT_TIME
		return

	var target_list: Array[Node2D] = [target]
	swords[index].launch(target_list)
	sword_timers[index] = WAIT_TIME


func _get_closest_enemy() -> Node2D:
	var closest: Node2D = null
	var min_dist = INF
	for body in enemies_in_range:
		if not is_instance_valid(body):
			continue
		var dist = player.global_position.distance_to(body.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = body
	return closest
