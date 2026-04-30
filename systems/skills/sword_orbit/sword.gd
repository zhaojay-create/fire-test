extends Area2D

# 剑的状态
# 状态: IDLE / FLYING / RETURNING
#
# IDLE:
#   - 悬浮在 player 身边
#
# FLYING:
#   - targets 队列非空 → 飞向 targets[0]
#   - 到达/命中 targets[0] → 造成伤害，pop 掉
#   - targets[0] 已死（invalid）→ 直接 pop，看下一个
#   - 队列空了 → 切到 RETURNING
#
# RETURNING:
#   - 飞向 player
#   - 到达 player → 切到 IDLE

const FLY_SPEED_INIT = 100.0
const FLY_SPEED_MAX = 800.0
const FLY_ACCEL = 1200.0
const RETURN_SPEED_INIT = 150.0
const RETURN_SPEED_MAX = 1200.0
const RETURN_ACCEL = 1800.0
const WINDUP_TIME = 0.15
const WINDUP_OFFSET = 12.0
const SLOW_DIST_FLY = 80.0
const SLOW_DIST_RETURN = 60.0
const HIT_DIST = 20.0
const ARRIVE_DIST = 10.0

enum State { IDLE, FLYING, RETURNING }

var state: State = State.IDLE
var player: Node2D = null
var targets: Array[Node2D] = []
var current_speed: float = 0.0
var hover_offset: Vector2 = Vector2.ZERO # 由父节点设置，左或右偏移


func set_player(p: Node2D) -> void:
	player = p

func set_hover_offset(offset: Vector2) -> void:
	hover_offset = offset


func is_idle() -> bool:
	return state == State.IDLE


func is_busy() -> bool:
	return state != State.IDLE


func launch(target_list: Array[Node2D]) -> void:
	if not is_instance_valid(player) or state != State.IDLE:
		return
	if target_list.is_empty():
		return

	targets = target_list.duplicate()

	# 蓄力：tween 后拉再切到 FLYING
	var first_target = _peek_target()
	if not is_instance_valid(first_target):
		targets.clear()
		return

	var windup_dir = global_position.direction_to(first_target.global_position)
	var windup_pos = global_position - windup_dir * WINDUP_OFFSET
	var target_rot = windup_dir.angle() - PI / 2.0

	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "global_position", windup_pos, WINDUP_TIME)
	tw.tween_property(self, "rotation", target_rot, WINDUP_TIME)
	tw.chain().tween_callback(_start_flying)


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	match state:
		State.IDLE:
			_process_idle(delta)
		State.FLYING:
			_process_flying(delta)
		State.RETURNING:
			_process_returning(delta)


func _process_idle(delta: float) -> void:
	var hover_y = sin(Time.get_ticks_msec() * 0.003 + hover_offset.x) * 5.0
	global_position = player.global_position + hover_offset + Vector2(0, hover_y)
	var target_rot = 0.0
	if player.velocity.length() > 10.0:
		target_rot = player.velocity.angle() - PI / 2.0
	rotation = lerp_angle(rotation, target_rot, 8.0 * delta)


func _process_flying(delta: float) -> void:
	var target = _peek_target()
	if not is_instance_valid(target):
		# 当前目标已死，弹出并看下一个
		_pop_target()
		if targets.is_empty():
			_start_returning()
		else:
			current_speed = FLY_SPEED_INIT
		return

	var dir = global_position.direction_to(target.global_position)
	var dist = global_position.distance_to(target.global_position)
	rotation = lerp_angle(rotation, dir.angle() - PI / 2.0, 10.0 * delta)

	if dist < HIT_DIST:
		_hit_target(target)
	elif dist < SLOW_DIST_FLY:
		current_speed = max(current_speed - FLY_ACCEL * 2.0 * delta, FLY_SPEED_INIT)
		global_position += dir * current_speed * delta
	else:
		current_speed = min(current_speed + FLY_ACCEL * delta, FLY_SPEED_MAX)
		global_position += dir * current_speed * delta


func _process_returning(delta: float) -> void:
	var ret_target = player.global_position + hover_offset
	var ret_dist = global_position.distance_to(ret_target)
	if ret_dist < ARRIVE_DIST:
		state = State.IDLE
		return
	var dir = global_position.direction_to(ret_target)
	rotation = lerp_angle(rotation, dir.angle() - PI / 2.0, 10.0 * delta)
	if ret_dist < SLOW_DIST_RETURN:
		var min_speed = max(RETURN_SPEED_INIT, player.velocity.length() * 1.5)
		current_speed = max(current_speed - RETURN_ACCEL * 2.0 * delta, min_speed)
	else:
		current_speed = min(current_speed + RETURN_ACCEL * delta, RETURN_SPEED_MAX)
	var step = min(current_speed * delta, ret_dist)
	global_position += dir * step


func _start_flying() -> void:
	current_speed = FLY_SPEED_INIT
	state = State.FLYING


func _start_returning() -> void:
	targets.clear()
	current_speed = RETURN_SPEED_INIT
	state = State.RETURNING


func _peek_target() -> Node2D:
	if targets.is_empty():
		return null
	return targets[0]


func _pop_target() -> void:
	if not targets.is_empty():
		targets.pop_front()


func _hit_target(target: Node2D) -> void:
	if target.has_method("take_damage"):
		target.call_deferred("take_damage")
	_pop_target()
	if targets.is_empty():
		_start_returning()
	else:
		# 还有下一个目标，重置速度继续飞
		current_speed = FLY_SPEED_INIT


func _on_body_entered(body: Node2D) -> void:
	if state == State.FLYING and body == _peek_target():
		_hit_target(body)
