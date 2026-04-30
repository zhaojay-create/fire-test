extends Node2D

const SWORD_SCENE = preload("res://systems/skills/sword_orbit/sword.tscn")
const ROTATION_SPEED = 3.0  # 旋转速度（弧度/秒）
const ORBIT_RADIUS = 200.0  # 旋转半径

var swords: Array[Node2D] = []


func _ready() -> void:
	# 默认 1 把剑
	set_sword_count(1)


## 设置环绕剑数量（1~3），由 SkillManager 在升级时调用
func set_sword_count(count: int) -> void:
	if count <= swords.size():
		return

	# 先清掉旧剑，重新均匀分布
	for sword in swords:
		sword.queue_free()
	swords.clear()

	for i in count:
		var sword = SWORD_SCENE.instantiate()
		add_child(sword)
		var angle = TAU / count * i
		sword.position = Vector2(cos(angle), sin(angle)) * ORBIT_RADIUS
		swords.append(sword)


func _process(delta: float) -> void:
	rotation += ROTATION_SPEED * delta
