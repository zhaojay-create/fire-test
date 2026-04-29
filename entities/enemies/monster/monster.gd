extends CharacterBody2D


const SPEED = 200.0 # 怪物速度
const STOP_DISTANCE = 250.0  # 停止距离
var health: int = 3 # 怪物血量

# 找到玩家 node
@onready var player = get_tree().get_first_node_in_group("player")

func _ready() -> void:
	add_to_group("enemy")

func _physics_process(_delta: float) -> void:

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
	
	if(health == 0):
		queue_free()
