extends Node

const MONSTER_SCENE = preload("res://entities/enemies/monster/monster.tscn")

# 基础刷怪间隔（秒）
@export var base_interval: float = 2.0
# 最小间隔
@export var min_interval: float = 0.3
# 每秒加速量（间隔缩短速度）
@export var acceleration: float = 0.02
# 屏幕外生成距离（离玩家多远）
@export var spawn_margin: float = 600.0
# 波次精英怪（可选，先做基础再加）
@export var _next_wave_time: float = 30.0

var _timer: Timer
var _elapsed: float = 0.0

@onready var player: Node2D = get_tree().get_first_node_in_group("player")


func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	_start_next()


func _process(delta: float) -> void:
	_elapsed += delta
	
	if _elapsed >= _next_wave_time:
		_spawn_wave()
		_next_wave_time += 30.0

func _spawn_wave() -> void:
	for i in 5:  # 一次刷 5 只
		_spawn_monster()

func _start_next() -> void:
	# 随时间缩短间隔
	var interval = max(base_interval - _elapsed * acceleration, min_interval)
	_timer.wait_time = interval
	_timer.start()


func _on_timer_timeout() -> void:
	_spawn_monster()
	_start_next()


func _spawn_monster() -> void:
	if not is_instance_valid(player):
		return

	var monster = MONSTER_SCENE.instantiate()
	monster.global_position = _random_offscreen_pos()
	get_tree().current_scene.add_child(monster)


func _random_offscreen_pos() -> Vector2:
	# 在玩家周围 spawn_margin 距离的圆环上随机一个角度
	var angle = randf() * TAU
	var offset = Vector2(cos(angle), sin(angle)) * spawn_margin
	var pos = player.global_position + offset
	# 限制在地图范围内（你的墙壁范围）
	pos.x = clampf(pos.x, -680, 680)
	pos.y = clampf(pos.y, -950, 950)
	return pos
