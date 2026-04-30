extends Area2D

const ATTRACT_RADIUS = 300.0 # 吸附触发距离
const ATTRACT_ACCEL = 600.0 # 吸附加速度
const ATTRACT_MAX_SPEED = 500.0 # 吸附最大速度

@export var xp_value: int = 100

var _speed: float = 0.0  # 当前速度
var _attracted: bool = false # 是否开始被吸引
var _player: Node2D = null


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if not is_instance_valid(_player):
			return

	if not _attracted:
		var dist = global_position.distance_to(_player.global_position)
		if dist < ATTRACT_RADIUS:
			_attracted = true

	if _attracted:
		_speed = minf(_speed + ATTRACT_ACCEL * delta, ATTRACT_MAX_SPEED)
		var dir = global_position.direction_to(_player.global_position)
		global_position += dir * _speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("add_xp"):
		body.add_xp(xp_value)
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 8.0, Color.GREEN)
