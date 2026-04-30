extends CharacterBody2D


const SPEED = 200.0 # 怪物速度
const STOP_DISTANCE = 0.0 # 直接贴脸撞
const DAMAGE_INTERVAL = 1.0 # 接触伤害间隔（秒）

@export var contact_damage: int = 1 # 伤害数值

var health: int = 3 # 怪物血量
var _player_in_range: bool = false
var _damage_timer: Timer

# 找到玩家 node
@onready var player = get_tree().get_first_node_in_group("player")


func _ready() -> void:
	add_to_group("enemy")

	_damage_timer = Timer.new()
	_damage_timer.wait_time = DAMAGE_INTERVAL
	_damage_timer.timeout.connect(_on_damage_timer_timeout)
	add_child(_damage_timer)


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player):
		return

	var distance = global_position.distance_to(player.global_position)

	# 如果距离大于停止距离，才移动
	if distance > STOP_DISTANCE:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * SPEED
	else:
		velocity = Vector2.ZERO

	move_and_slide()


func take_damage():
	health -= 1
	print('被攻击了', health)

	if(health == 0):
		queue_free()


func _deal_contact_damage() -> void:
	if is_instance_valid(player) and player.has_method("take_damage"):
		print("对", player, "造成了伤害数值是:", contact_damage)
		player.take_damage(contact_damage)


func _on_hurt_box_body_entered(body: Node2D) -> void:
	if body != player:
		return
	print("玩家进入攻击范围", player)
	_player_in_range = true
	_deal_contact_damage()
	_damage_timer.start()


func _on_hurt_box_body_exited(body: Node2D) -> void:
	if body != player:
		return
	print("玩家退出攻击范围", player)
	_player_in_range = false
	_damage_timer.stop()


func _on_damage_timer_timeout() -> void:
	if _player_in_range:
		_deal_contact_damage()
