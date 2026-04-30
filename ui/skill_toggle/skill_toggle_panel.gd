extends PanelContainer

## 技能开关面板：按 Tab 打开/关闭，显示已拥有的技能，可以开启/关闭

var _visible_panel: bool = false


func _ready() -> void:
	visible = false
	SkillManager.skill_selected.connect(_on_skill_changed)
	SkillManager.skill_toggled.connect(_on_skill_toggled)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_skill_panel"):
		_visible_panel = not _visible_panel
		visible = _visible_panel
		if _visible_panel:
			_rebuild()


func _on_skill_changed(_skill_id: String) -> void:
	if _visible_panel:
		_rebuild()


func _on_skill_toggled(_skill_id: String, _enabled: bool) -> void:
	if _visible_panel:
		_rebuild()


func _rebuild() -> void:
	var container = $MarginContainer/VBoxContainer/SkillList
	for child in container.get_children():
		child.queue_free()

	var owned = SkillManager.owned_skills
	if owned.is_empty():
		var lbl = Label.new()
		lbl.text = "暂无技能"
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		container.add_child(lbl)
		return

	for skill_id in owned:
		var level = owned[skill_id] as int
		if level <= 0:
			continue
		var def = SkillManager._get_def(skill_id)
		if def.is_empty():
			continue

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)

		var enabled = SkillManager.is_skill_enabled(skill_id)
		var cost = def.get("spirit_sense_cost", 0) as int
		var total_cost = cost * level

		# 技能名称 + 等级
		var name_label = Label.new()
		name_label.text = "%s Lv.%d" % [def["name"], level]
		name_label.custom_minimum_size = Vector2(160, 0)
		name_label.add_theme_font_size_override("font_size", 18)
		if enabled:
			name_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
		else:
			name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		hbox.add_child(name_label)

		# 神识占用
		var cost_label = Label.new()
		cost_label.text = "神识: %d" % total_cost
		cost_label.custom_minimum_size = Vector2(80, 0)
		cost_label.add_theme_font_size_override("font_size", 16)
		cost_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.2))
		hbox.add_child(cost_label)

		# 开关按钮
		var btn = Button.new()
		btn.text = "关闭" if enabled else "开启"
		btn.custom_minimum_size = Vector2(70, 30)
		btn.add_theme_font_size_override("font_size", 16)
		var sid = skill_id
		btn.pressed.connect(func(): SkillManager.toggle_skill(sid))
		hbox.add_child(btn)

		container.add_child(hbox)
