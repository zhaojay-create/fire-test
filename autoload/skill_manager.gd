extends Node

signal skill_selected(skill_id: String)

# 技能定义表
var skill_defs: Array[Dictionary] = [
	{
		"id": "sword_auto",
		"name": "自动飞剑",
		"description": "自动索敌的飞剑",
		"scene_path": "res://systems/skills/sword_auto/sword_auto.tscn",
		"max_level": 3,
	},
	{
		"id": "sword_orbit",
		"name": "环绕剑",
		"description": "围绕玩家旋转的护体剑",
		"scene_path": "res://systems/skills/sword_orbit/sword_orbit.tscn",
		"max_level": 3,
	},
]

# 玩家当前拥有的技能等级 { skill_id: int }
var owned_skills: Dictionary = {}


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
		picks.append({
			"id": def["id"],
			"name": def["name"],
			"description": def["description"],
			"scene_path": def["scene_path"],
			"current_level": level,
			"is_new": is_new,
			"label": ("新技能: " + def["name"]) if is_new else (def["name"] + " Lv.%d → Lv.%d" % [level, level + 1]),
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

	if level == 0:
		# 新技能 → 实例化场景挂到玩家身上
		var def = _get_def(skill_id)
		if def.is_empty():
			return
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


func _get_def(skill_id: String) -> Dictionary:
	for def in skill_defs:
		if def["id"] == skill_id:
			return def
	return {}
