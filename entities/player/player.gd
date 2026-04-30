extends CharacterBody2D

signal health_changed(current_hp: int, max_hp: int)
signal xp_changed(xp: int, xp_needed: int)
signal realm_changed(realm_index: int, realm_name: String)
signal lifespan_changed(months: int)
signal spirit_sense_changed(current: int, max_val: int)
signal died

const SPEED = 600.0
const INVINCIBILITY_DURATION = 0.5 # 无敌帧

const REALM_NAMES = ["炼气", "筑基", "结丹", "元婴", "化神"]
const REALM_THRESHOLDS = [0, 100, 300, 700, 1500] # 每个境界的起始累计灵气

@export var max_hp: int = 10

var current_hp: int
var total_xp: int = 0       # 累计灵气
var realm_index: int = 0    # 当前境界（0=炼气）
var lifespan_months: int = 1200  # 寿元（月），初始 100 年
var max_spirit_sense: int = 100  # 神识上限
var used_spirit_sense: int = 0   # 已占用神识
var _invincible: bool = false # 是否处于无敌状态
var _spirit_overdraft_acc: float = 0.0 # 神识透支寿元累计器

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
	_process_spirit_overdraft(_delta)


func take_damage(amount: int = 1) -> void:
	if _invincible or current_hp <= 0:
		return

	current_hp = maxi(current_hp - amount, 0)
	health_changed.emit(current_hp, max_hp)

	if current_hp <= 0:
		_die()
		return

	_invincible = true
	_invincibility_timer.start()
	_start_flash()


## 获取当前剩余神识（可为负值）
func get_spirit_sense() -> int:
	return max_spirit_sense - used_spirit_sense


## 占用神识
func occupy_spirit_sense(amount: int) -> void:
	used_spirit_sense += amount
	spirit_sense_changed.emit(get_spirit_sense(), max_spirit_sense)


## 释放神识
func release_spirit_sense(amount: int) -> void:
	used_spirit_sense = maxi(used_spirit_sense - amount, 0)
	spirit_sense_changed.emit(get_spirit_sense(), max_spirit_sense)


## 神识透支 → 每秒按比例扣寿元
func _process_spirit_overdraft(delta: float) -> void:
	var current = get_spirit_sense()
	if current >= 0:
		_spirit_overdraft_acc = 0.0
		return
	# 透支比例：|负值| / 上限，例如 -50/100 = 0.5
	var ratio = absf(float(current)) / float(max_spirit_sense)
	# 每秒扣 months = ratio * 12（即每秒最多扣 1 年，ratio=1 时）
	var drain_per_sec = ratio * 12.0
	_spirit_overdraft_acc += drain_per_sec * delta
	if _spirit_overdraft_acc >= 1.0:
		var months_to_drain = int(_spirit_overdraft_acc)
		_spirit_overdraft_acc -= float(months_to_drain)
		lifespan_months -= months_to_drain
		lifespan_changed.emit(lifespan_months)
		if lifespan_months <= 0:
			_die()


func add_xp(amount: int) -> void:
	total_xp += amount
	_check_realm_up()
	xp_changed.emit(get_realm_xp(), get_realm_xp_needed())


## 当前境界内已累积的灵气
func get_realm_xp() -> int:
	return total_xp - REALM_THRESHOLDS[realm_index]


## 当前境界需要的总灵气
func get_realm_xp_needed() -> int:
	if realm_index < REALM_THRESHOLDS.size() - 1:
		return REALM_THRESHOLDS[realm_index + 1] - REALM_THRESHOLDS[realm_index]
	return 1 # 最高境界，避免除零


func _check_realm_up() -> void:
	while realm_index < REALM_NAMES.size() - 1:
		var next_threshold = REALM_THRESHOLDS[realm_index + 1]
		if total_xp >= next_threshold:
			realm_index += 1
			realm_changed.emit(realm_index, REALM_NAMES[realm_index])
		else:
			break


## 花费寿元（月），返回是否足够
func spend_lifespan(months: int) -> bool:
	if lifespan_months < months:
		return false
	lifespan_months -= months
	lifespan_changed.emit(lifespan_months)
	if lifespan_months <= 0:
		_die()
	return true


## 将月份格式化为 "年+月" 字符串
func format_lifespan(months: int) -> String:
	@warning_ignore("integer_division")
	var years = months / 12
	var m = months % 12
	if m == 0:
		return "%d年" % years
	return "%d年%d月" % [years, m]


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
