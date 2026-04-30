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

# 玩家当前拥有的技能等级 { skill_id: int }
var owned_skills: Dictionary = {}
# 技能开关状态 { skill_id: bool }
var skill_enabled: Dictionary = {}


func _ready() -> void:
	pass


## 随机抽取 count 个技能选项（新技能 或 已有技能强化）
func get_random_picks(count: int = 3) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []

	for def in skill_defs:
		var level = owned_skills.get(def["id"], 0)
		if level >= def["max_level"]:
			continue # 已满级，跳过
		pool.append(def)

	pool.shuffle()
	var picks: Array[Dictionary] = []
	for i in mini(count, pool.size()):
		var def = pool[i]
		var level = owned_skills.get(def["id"], 0)
		var is_new = level == 0
		var cost = def["lifespan_cost"] as int
		var spirit_cost = def.get("spirit_sense_cost", 0) as int
		picks.append({
			"id": def["id"],
			"name": def["name"],
			"description": def["description"],
			"scene_path": def["scene_path"],
			"current_level": level,
			"is_new": is_new,
			"lifespan_cost": cost,
			"spirit_sense_cost": spirit_cost,
			"label": ("新技能: " + def["name"] + " [神识%d]" % spirit_cost) if is_new else (def["name"] + " Lv.%d → Lv.%d [神识+%d]" % [level, level + 1, spirit_cost]),
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


func _get_def(skill_id: String) -> Dictionary:
	for def in skill_defs:
		if def["id"] == skill_id:
			return def
	return {}
