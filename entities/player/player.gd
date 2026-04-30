extends CharacterBody2D
## 玩家实体：只负责物理移动、碰撞、受伤动画
## 所有数据存储在 PlayerManager（autoload）

const SPEED = 600.0
const INVINCIBILITY_DURATION = 0.5 # 无敌帧

var _invincible: bool = false
var _spirit_overdraft_acc: float = 0.0

var _invincibility_timer: Timer
var _flash_tween: Tween

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("player")
	PlayerManager.current_hp = PlayerManager.max_hp

	_invincibility_timer = Timer.new()
	_invincibility_timer.wait_time = INVINCIBILITY_DURATION
	_invincibility_timer.one_shot = true
	_invincibility_timer.timeout.connect(_on_invincibility_timeout)
	add_child(_invincibility_timer)


func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED
	move_and_slide()
	_process_spirit_overdraft(delta)


func take_damage(amount: int = 1) -> void:
	if _invincible or PlayerManager.current_hp <= 0:
		return

	PlayerManager.take_damage(amount)

	if PlayerManager.current_hp <= 0:
		_die()
		return

	_invincible = true
	_invincibility_timer.start()
	_start_flash()


func add_xp(amount: int) -> void:
	PlayerManager.add_xp(amount)


## 神识透支 → 每秒按比例扣寿元
func _process_spirit_overdraft(delta: float) -> void:
	var current = PlayerManager.get_spirit_sense()
	if current >= 0:
		_spirit_overdraft_acc = 0.0
		return
	# 透支比例：|负值| / 上限，例如 -50/100 = 0.5
	var ratio = absf(float(current)) / float(PlayerManager.max_spirit_sense)
	# 每秒扣 months = ratio * 12（即每秒最多扣 1 年，ratio=1 时）
	var drain_per_sec = ratio * 12.0
	_spirit_overdraft_acc += drain_per_sec * delta
	if _spirit_overdraft_acc >= 1.0:
		var months_to_drain = int(_spirit_overdraft_acc)
		_spirit_overdraft_acc -= float(months_to_drain)
		PlayerManager.lifespan_months -= months_to_drain
		PlayerManager.lifespan_changed.emit(PlayerManager.lifespan_months)
		if PlayerManager.lifespan_months <= 0:
			_die()


func _die() -> void:
	PlayerManager.died.emit()
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
