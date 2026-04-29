extends Area2D

const FLY_SPEED = 500.0  # 飞行时间
const RETURN_SPEED = 800.0 # 返回时间
const WAIT_TIME = 1.0 # 停顿的时间

enum State { IDLE, FLY_OUT, RETURNING }
var state: State = State.IDLE
var target: Node2D = null
var player: Node2D = null
var wait_timer: float = 0.0
var has_hit: bool = false # 是否攻击过


func _ready() -> void:
	top_level = true
	player = get_tree().get_first_node_in_group("player")
	pass


func _process(delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if not player:
			return
			
	match state:
		State.IDLE:
			# 停在玩家身上，等待计时
			global_position = player.global_position
			wait_timer -= delta
			if wait_timer <= 0:
				_find_and_fly()
 
		State.FLY_OUT:
			if not is_instance_valid(target):
				state = State.RETURNING
				return
			var dir = global_position.direction_to(target.global_position)
			var dist = global_position.distance_to(target.global_position)
			if dist < 20.0:
				# 到达目标，造成伤害并返回
				if not has_hit and target.has_method("take_damage"):
					has_hit = true
					target.take_damage()
				state = State.RETURNING
			global_position += dir * FLY_SPEED * delta
 
		State.RETURNING:
			var dir = global_position.direction_to(player.global_position)
			global_position += dir * RETURN_SPEED * delta
			# 到达玩家附近
			if global_position.distance_to(player.global_position) < 10.0:
				state = State.IDLE
				wait_timer = WAIT_TIME

# 有敌人进入飞行的范围
func _on_body_entered(body: Node2D) -> void:
	if has_hit:
		return
	print("有敌人进入飞行的范围, 开始攻击")
	if body.has_method("take_damage"):
		has_hit = true
		body.take_damage()
		state = State.RETURNING  # 攻击到敌人后返回
	
func _find_and_fly() -> void:
	has_hit = false
	# 找到最近的敌人
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.is_empty():
		state = State.IDLE
		wait_timer = WAIT_TIME
		return
	
	var closest: Node2D = null
	var min_dist = INF
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = enemy
	
	target = closest
	state = State.FLY_OUT
