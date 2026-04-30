extends CharacterBody2D

signal health_changed(current_hp: int, max_hp: int)
signal died

const SPEED = 600.0
const INVINCIBILITY_DURATION = 0.5 # 无敌帧

@export var max_hp: int = 10

var current_hp: int
var _invincible: bool = false # 是否处于无敌状态

var _invincibility_timer: Timer # 无敌计时器
var _flash_tween: Tween # 闪烁动画

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("player")
	current_hp = max_hp

	_invincibility_timer = Timer.new()
	_invincibility_timer.wait_time = INVINCIBILITY_DURATION
	_invincibility_timer.one_shot = true
	_invincibility_timer.timeout.connect(_on_invincibility_timeout)
	add_child(_invincibility_timer)


func _physics_process(_delta: float) -> void:
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED
	move_and_slide()


func take_damage(amount: int = 1) -> void:
	if _invincible or current_hp <= 0:
		return

	current_hp = maxi(current_hp - amount, 0)
	health_changed.emit(current_hp, max_hp)
	print("player 受到了伤害 current_hp:", current_hp, "max_hp:", max_hp)

	if current_hp <= 0:
		_die()
		return

	_invincible = true
	_invincibility_timer.start()
	_start_flash()


func _die() -> void:
	died.emit()
	# 暂时直接移除，后续可改为暂停游戏 / 结算画面
	queue_free()


func _on_invincibility_timeout() -> void:
	_invincible = false
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_sprite.modulate.a = 1.0


func _start_flash() -> void:
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = create_tween()
	var loops = int(INVINCIBILITY_DURATION / 0.1)
	_flash_tween.set_loops(loops)
	_flash_tween.tween_property(_sprite, "modulate:a", 0.3, 0.05)
	_flash_tween.tween_property(_sprite, "modulate:a", 1.0, 0.05)
