extends Node2D

const ROTATION_SPEED = 3.0  # 旋转速度（弧度/秒）
const ORBIT_RADIUS = 200.0  # 旋转半径
 

func _ready() -> void:
	$Sword.position = Vector2(ORBIT_RADIUS, 0)
	pass

func _process(delta: float) -> void:
	rotation += ROTATION_SPEED * delta
