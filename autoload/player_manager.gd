extends Node
## 玩家数据中心（类似 Zustand Store）
## 只存数据 + 发信号，不含物理/渲染逻辑

# ─── 信号 ───
signal health_changed(current_hp: int, max_hp: int)
signal xp_changed(xp: int, xp_needed: int)
signal realm_changed(realm_index: int, realm_name: String)
signal lifespan_changed(months: int)
signal spirit_sense_changed(current: int, max_val: int)
signal died

# ─── 常量 ───
const REALM_NAMES = ["炼气", "筑基", "结丹", "元婴", "化神"]
const REALM_THRESHOLDS = [0, 100, 300, 700, 1500]

# ─── 数据 ───
var max_hp: int = 10
var current_hp: int = 10
var total_xp: int = 0
var realm_index: int = 0
var lifespan_months: int = 1200  # 100年
var max_spirit_sense: int = 100
var used_spirit_sense: int = 0
var pickup_range_mult: float = 1.0
var xp_mult: float = 1.0


## 重置所有数据（新一局）
func reset() -> void:
	max_hp = 10
	current_hp = 10
	total_xp = 0
	realm_index = 0
	lifespan_months = 1200
	max_spirit_sense = 100
	used_spirit_sense = 0
	pickup_range_mult = 1.0
	xp_mult = 1.0


# ─── 生命 ───
func take_damage(amount: int = 1) -> void:
	current_hp = maxi(current_hp - amount, 0)
	health_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		died.emit()


func heal(amount: int) -> void:
	current_hp = mini(current_hp + amount, max_hp)
	health_changed.emit(current_hp, max_hp)


# ─── 灵气 / 境界 ───
func add_xp(amount: int) -> void:
	var actual = int(amount * xp_mult)
	total_xp += actual
	_check_realm_up()
	xp_changed.emit(get_realm_xp(), get_realm_xp_needed())


func get_realm_xp() -> int:
	return total_xp - REALM_THRESHOLDS[realm_index]


func get_realm_xp_needed() -> int:
	if realm_index < REALM_THRESHOLDS.size() - 1:
		return REALM_THRESHOLDS[realm_index + 1] - REALM_THRESHOLDS[realm_index]
	return 1


func _check_realm_up() -> void:
	while realm_index < REALM_NAMES.size() - 1:
		if total_xp >= REALM_THRESHOLDS[realm_index + 1]:
			realm_index += 1
			realm_changed.emit(realm_index, REALM_NAMES[realm_index])
		else:
			break


# ─── 寿元 ───
func spend_lifespan(months: int) -> bool:
	if lifespan_months < months:
		return false
	lifespan_months -= months
	lifespan_changed.emit(lifespan_months)
	if lifespan_months <= 0:
		died.emit()
	return true


static func format_lifespan(months: int) -> String:
	@warning_ignore("integer_division")
	var years = months / 12
	var m = months % 12
	if m == 0:
		return "%d年" % years
	return "%d年%d月" % [years, m]


# ─── 神识 ───
func get_spirit_sense() -> int:
	return max_spirit_sense - used_spirit_sense


func occupy_spirit_sense(amount: int) -> void:
	used_spirit_sense += amount
	spirit_sense_changed.emit(get_spirit_sense(), max_spirit_sense)


func release_spirit_sense(amount: int) -> void:
	used_spirit_sense = maxi(used_spirit_sense - amount, 0)
	spirit_sense_changed.emit(get_spirit_sense(), max_spirit_sense)
