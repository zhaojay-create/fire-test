extends CanvasLayer

signal skill_chosen(skill_id: String)
signal skipped

var _picks: Array[Dictionary] = []

@onready var _btn_container: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func setup(picks: Array[Dictionary]) -> void:
	_picks = picks


func _enter_tree() -> void:
	# 等一帧确保节点就绪
	await get_tree().process_frame
	_build_buttons()


func _build_buttons() -> void:
	if not is_instance_valid(_btn_container):
		return

	for child in _btn_container.get_children():
		child.queue_free()

	for pick in _picks:
		var cost = pick["lifespan_cost"] as int
		var is_passive = pick.get("is_passive", false) as bool
		var btn = Button.new()

		if cost > 0:
			var cost_text = PlayerManager.format_lifespan(cost)
			btn.text = "%s（寿元 -%s）" % [pick["label"], cost_text]
		else:
			btn.text = pick["label"]

		btn.tooltip_text = pick["description"]
		btn.custom_minimum_size = Vector2(400, 60)
		btn.add_theme_font_size_override("font_size", 22)
		# 寿元不足时禁用按钮
		if cost > 0 and PlayerManager.lifespan_months < cost:
			btn.disabled = true
			btn.tooltip_text = "寿元不足"
		var sid = pick["id"] as String
		btn.pressed.connect(_on_btn_pressed.bind(sid, is_passive))
		_btn_container.add_child(btn)

	# 跳过按钮
	var skip_btn = Button.new()
	skip_btn.text = "跳过"
	skip_btn.custom_minimum_size = Vector2(400, 50)
	skip_btn.add_theme_font_size_override("font_size", 20)
	skip_btn.pressed.connect(_on_skip_pressed)
	_btn_container.add_child(skip_btn)


func _on_btn_pressed(skill_id: String, is_passive: bool = false) -> void:
	if is_passive:
		SkillManager.apply_passive(skill_id)
	else:
		SkillManager.apply_skill(skill_id)
	skill_chosen.emit(skill_id)
	queue_free()


func _on_skip_pressed() -> void:
	skipped.emit()
	queue_free()
