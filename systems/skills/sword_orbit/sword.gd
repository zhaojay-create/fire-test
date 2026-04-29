extends Area2D

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

enum State { IDLE, WINDUP, FLY_OUT, RETURNING }

var state: State = State.IDLE
var player: Node2D = null
var target: Node2D = null
var current_speed: float = 0.0
var windup_timer: float = 0.0
var windup_dir: Vector2 = Vector2.ZERO
var windup_position: Vector2 = Vector2.ZERO
var hover_offset: Vector2 = Vector2.ZERO # 由父节点设置，左或右偏移


func set_player(p: Node2D) -> void:
	player = p


func set_hover_offset(offset: Vector2) -> void:
	hover_offset = offset


func is_idle() -> bool:
	return state == State.IDLE


func is_flying() -> bool:
	return state == State.FLY_OUT


func launch(t: Node2D) -> void:
	if not is_instance_valid(player) or state == State.FLY_OUT:
		return
	target = t
	windup_dir = player.global_position.direction_to(target.global_position)
	windup_position = player.global_position + hover_offset - windup_dir * WINDUP_OFFSET
	windup_timer = WINDUP_TIME
	state = State.WINDUP


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	match state:
		State.IDLE:
			var hover_y = sin(Time.get_ticks_msec() * 0.003 + hover_offset.x) * 5.0
			global_position = player.global_position + hover_offset + Vector2(0, hover_y)
			rotation = lerp_angle(rotation, 0.0, 8.0 * delta)

		State.WINDUP:
			global_position = windup_position
			rotation = lerp_angle(rotation, windup_dir.angle() - PI / 2.0, 15.0 * delta)
			windup_timer -= delta
			if windup_timer <= 0.0:
				current_speed = FLY_SPEED_INIT
				state = State.FLY_OUT

		State.FLY_OUT:
			if not is_instance_valid(target):
				_start_returning()
				return
			var dir = global_position.direction_to(target.global_position)
			rotation = lerp_angle(rotation, dir.angle() - PI / 2.0, 10.0 * delta)
			var dist = global_position.distance_to(target.global_position)
			if dist < 20.0:
				_start_returning()
			elif dist < SLOW_DIST_FLY:
				current_speed = max(current_speed - FLY_ACCEL * 2.0 * delta, FLY_SPEED_INIT)
				global_position += dir * current_speed * delta
			else:
				current_speed = min(current_speed + FLY_ACCEL * delta, FLY_SPEED_MAX)
				global_position += dir * current_speed * delta

		State.RETURNING:
			var dir = global_position.direction_to(player.global_position + hover_offset)
			rotation = lerp_angle(rotation, dir.angle() - PI / 2.0, 10.0 * delta)
			var ret_dist = global_position.distance_to(player.global_position + hover_offset)
			if ret_dist < SLOW_DIST_RETURN:
				current_speed = max(current_speed - RETURN_ACCEL * 2.0 * delta, RETURN_SPEED_INIT)
			else:
				current_speed = min(current_speed + RETURN_ACCEL * delta, RETURN_SPEED_MAX)
			global_position += dir * current_speed * delta
			if ret_dist < 10.0:
				state = State.IDLE


func _start_returning() -> void:
	target = null
	current_speed = RETURN_SPEED_INIT
	state = State.RETURNING


func _on_body_entered(body: Node2D) -> void:
	if state == State.FLY_OUT and body == target:
		if body.has_method("take_damage"):
			body.call_deferred("take_damage")
		_start_returning()
