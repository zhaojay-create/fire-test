extends Node

signal skill_selected(skill_id: String)
signal skill_toggled(skill_id: String, enabled: bool)

# 技能定义表
var skill_defs: Array[Dictionary] = [
	{
		"id": "sword_auto",
		"name": "自动飞剑",
		"description": "自动索敌的飞剑",
		"scene_path": "res://systems/skills/sword_auto/sword_auto.tscn",
		"max_level": 3,
		"lifespan_cost": 120, # 10年 = 120月
		"spirit_sense_cost": 20, # 每把剑占用 20 神识
	},
	{
		"id": "sword_orbit",
		"name": "环绕剑",
		"description": "围绕玩家旋转的护体剑",
		"scene_path": "res://systems/skills/sword_orbit/sword_orbit.tscn",
		"max_level": 3,
		"lifespan_cost": 60, # 5年 = 60月
		"spirit_sense_cost": 20, # 占用 20 神识
	},
]

# 被动增益定义表
var passive_defs: Array[Dictionary] = [
	{
		"id": "spirit_expand",
		"name": "神识扩展",
		"description": "神识上限 +20",
		"max_level": 5,
		"lifespan_cost": 60, # 5年
		"type": "passive",
	},
	{
		"id": "pickup_range",
		"name": "灵气吸附",
		"description": "灵气拾取范围 +50%",
		"max_level": 3,
		"lifespan_cost": 60, # 5年
		"type": "passive",
	},
	{
		"id": "max_hp_up",
		"name": "金身术",
		"description": "最大生命 +2",
		"max_level": 5,
		"lifespan_cost": 120, # 10年
		"type": "passive",
	},
	{
		"id": "lifespan_restore",
		"name": "固本培元",
		"description": "恢复 10 年寿元",
		"max_level": 99,
		"lifespan_cost": 0,
		"type": "passive",
	},
	{
		"id": "xp_boost",
		"name": "灵气增幅",
		"description": "灵气获取 +30%",
		"max_level": 3,
		"lifespan_cost": 60, # 5年
		"type": "passive",
	},
]

# 玩家当前拥有的技能等级 { skill_id: int }
var owned_skills: Dictionary = {}
# 技能开关状态 { skill_id: bool }
var skill_enabled: Dictionary = {}


func _ready() -> void:
	pass


## 随机抽取 count 个选项（技能 + 被动混合池）
func get_random_picks(count: int = 3) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []

	for def in skill_defs:
		var level = owned_skills.get(def["id"], 0)
		if level >= def["max_level"]:
			continue
		pool.append(def)

	for def in passive_defs:
		var level = owned_skills.get(def["id"], 0)
		if level >= def["max_level"]:
			continue
		pool.append(def)

	pool.shuffle()
	var picks: Array[Dictionary] = []
	for i in mini(count, pool.size()):
		var def = pool[i]
		var level = owned_skills.get(def["id"], 0)
		var is_new = level == 0
		var cost = def.get("lifespan_cost", 0) as int
		var is_passive = def.get("type", "") == "passive"
		var spirit_cost = def.get("spirit_sense_cost", 0) as int

		var label_text: String
		if is_passive:
			label_text = def["name"] + ": " + def["description"]
		elif is_new:
			label_text = "新技能: " + def["name"] + " [神识%d]" % spirit_cost
		else:
			label_text = def["name"] + " Lv.%d → Lv.%d [神识+%d]" % [level, level + 1, spirit_cost]

		picks.append({
			"id": def["id"],
			"name": def["name"],
			"description": def["description"],
			"current_level": level,
			"is_new": is_new,
			"is_passive": is_passive,
			"lifespan_cost": cost,
			"spirit_sense_cost": spirit_cost,
			"label": label_text,
		})
	return picks


## 技能 ID → 场景节点名 的映射
const SKILL_NODE_NAMES: Dictionary = {
	"sword_auto": "SwordAuto",
	"sword_orbit": "SwordOrbit",
}


## 玩家选择了一个技能
func apply_skill(skill_id: String) -> void:
	var level = owned_skills.get(skill_id, 0)
	var new_level = level + 1
	owned_skills[skill_id] = new_level

	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	# 占用新增等级的神识
	var def = _get_def(skill_id)
	if def.is_empty():
		return
	var cost = def.get("spirit_sense_cost", 0) as int
	player.occupy_spirit_sense(cost)
	skill_enabled[skill_id] = true

	if level == 0:
		# 新技能 → 实例化场景挂到玩家身上
		var scene = load(def["scene_path"]) as PackedScene
		if scene:
			var instance = scene.instantiate()
			player.add_child(instance)
	else:
		# 已有技能 → 找到节点，增加剑的数量
		var node_name = SKILL_NODE_NAMES.get(skill_id, "")
		if node_name.is_empty():
			return
		var skill_node = player.find_child(node_name, false, false)
		if skill_node and skill_node.has_method("set_sword_count"):
			skill_node.set_sword_count(new_level)

	skill_selected.emit(skill_id)


## 切换技能开关（占用/释放神识）
func toggle_skill(skill_id: String) -> void:
	var level = owned_skills.get(skill_id, 0)
	if level == 0:
		return # 未拥有

	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	var def = _get_def(skill_id)
	if def.is_empty():
		return

	var cost = def.get("spirit_sense_cost", 0) as int
	var total_cost = cost * level
	var enabled = skill_enabled.get(skill_id, true)

	if enabled:
		# 关闭技能 → 释放神识
		player.release_spirit_sense(total_cost)
		skill_enabled[skill_id] = false
		_set_skill_active(player, skill_id, false)
	else:
		# 开启技能 → 占用神识（允许透支）
		player.occupy_spirit_sense(total_cost)
		skill_enabled[skill_id] = true
		_set_skill_active(player, skill_id, true)

	skill_toggled.emit(skill_id, skill_enabled[skill_id])


## 检查技能是否开启
func is_skill_enabled(skill_id: String) -> bool:
	return skill_enabled.get(skill_id, true)


## 显示/隐藏技能节点
func _set_skill_active(player: Node, skill_id: String, active: bool) -> void:
	var node_name = SKILL_NODE_NAMES.get(skill_id, "")
	if node_name.is_empty():
		return
	var skill_node = player.find_child(node_name, false, false)
	if skill_node:
		skill_node.visible = active
		skill_node.set_process(active)
		skill_node.set_physics_process(active)


## 应用被动增益
func apply_passive(passive_id: String) -> void:
	var level = owned_skills.get(passive_id, 0)
	owned_skills[passive_id] = level + 1

	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	match passive_id:
		"spirit_expand":
			player.max_spirit_sense += 20
			player.spirit_sense_changed.emit(player.get_spirit_sense(), player.max_spirit_sense)
		"pickup_range":
			player.pickup_range_mult += 0.5
		"max_hp_up":
			player.max_hp += 2
			player.current_hp = mini(player.current_hp + 2, player.max_hp)
			player.health_changed.emit(player.current_hp, player.max_hp)
		"lifespan_restore":
			player.lifespan_months += 120 # +10年
			player.lifespan_changed.emit(player.lifespan_months)
		"xp_boost":
			player.xp_mult += 0.3

	skill_selected.emit(passive_id)


func _get_def(skill_id: String) -> Dictionary:
	for def in skill_defs:
		if def["id"] == skill_id:
			return def
	return {}


func _get_passive_def(passive_id: String) -> Dictionary:
	for def in passive_defs:
		if def["id"] == passive_id:
			return def
	return {}
