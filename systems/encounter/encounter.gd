extends Area2D
# 遭遇、遇敌、战斗场次
const GLOW_COLOR = Color(1, 0.85, 0.2, 0.7)
const RADIUS = 80.0

var _triggered: bool = false
var _alpha: float = 1.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# 闪烁动画提示玩家
	var tween = create_tween().set_loops()
	tween.tween_property(self, "_alpha", 0.3, 0.8)
	tween.tween_property(self, "_alpha", 1.0, 0.8)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var color = GLOW_COLOR
	color.a *= _alpha
	draw_circle(Vector2.ZERO, RADIUS, color)
	# 外圈描边
	var outline = Color(1, 0.95, 0.5, 0.9 * _alpha)
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 64, outline, 2.0)


func _on_body_entered(body: Node2D) -> void:
	if _triggered:
		return
	if not body.is_in_group("player"):
		return

	_triggered = true
	_show_skill_panel()


func _show_skill_panel() -> void:
	get_tree().paused = true

	var picks = SkillManager.get_random_picks(3)
	if picks.is_empty():
		# 所有技能已满级，直接恢复
		get_tree().paused = false
		queue_free()
		return

	var panel_scene = load("res://ui/skill_panel/skill_panel.tscn") as PackedScene
	var panel = panel_scene.instantiate()
	panel.setup(picks)
	panel.skill_chosen.connect(_on_skill_chosen)
	panel.skipped.connect(_on_skipped)
	# 添加到 HUD 层（CanvasLayer），保证在最上层
	get_tree().current_scene.add_child(panel)


func _on_skill_chosen(skill_id: String) -> void:
	# skill_panel 已经调用了 apply_skill / apply_passive
	# 这里只负责扣寿元和恢复游戏
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# 从两个池中查找定义
		var def = SkillManager._get_def(skill_id)
		if def.is_empty():
			def = SkillManager._get_passive_def(skill_id)
		if not def.is_empty():
			var cost = def.get("lifespan_cost", 0) as int
			if cost > 0:
				player.spend_lifespan(cost)

	get_tree().paused = false
	queue_free()


func _on_skipped() -> void:
	get_tree().paused = false
	queue_free()
