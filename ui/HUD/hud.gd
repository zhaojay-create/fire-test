extends CanvasLayer

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var kill_label: Label = $MarginContainer/VBoxContainer/KillLabel
@onready var lifespan_label: Label = $MarginContainer/VBoxContainer/LifespanLabel
@onready var spirit_sense_label: Label = $MarginContainer/VBoxContainer/SpiritSenseLabel
@onready var spirit_sense_bar: ProgressBar = $MarginContainer/VBoxContainer/SpiritSenseBar
@onready var spirit_overdraft_label: Label = $MarginContainer/VBoxContainer/SpiritOverdraftLabel
@onready var xp_bar: ProgressBar = $XpBarContainer/VBoxContainer/XpBar
@onready var realm_label: Label = $XpBarContainer/VBoxContainer/RealmLabel

var kill_count: int = 0


func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		health_bar.max_value = player.max_hp
		health_bar.value = player.current_hp
		player.health_changed.connect(_on_player_health_changed)
		player.xp_changed.connect(_on_player_xp_changed)
		player.realm_changed.connect(_on_player_realm_changed)
		player.lifespan_changed.connect(_on_player_lifespan_changed)
		player.spirit_sense_changed.connect(_on_spirit_sense_changed)
		# 初始化境界 UI
		realm_label.text = "【%s】" % player.REALM_NAMES[player.realm_index]
		_update_lifespan(player.lifespan_months)
		xp_bar.max_value = player.get_realm_xp_needed()
		xp_bar.value = player.get_realm_xp()
		# 初始化神识 UI
		_update_spirit_sense(player.get_spirit_sense(), player.max_spirit_sense)

	get_tree().node_removed.connect(_on_node_removed)
	_update_kill_label()


func _on_player_health_changed(current_hp: int, max_hp: int) -> void:
	health_bar.max_value = max_hp
	health_bar.value = current_hp


func _on_node_removed(node: Node) -> void:
	if node.is_in_group("enemy"): 
		kill_count += 1
		_update_kill_label()


func _on_player_xp_changed(xp: int, xp_needed: int) -> void:
	xp_bar.max_value = xp_needed
	xp_bar.value = xp


func _on_player_realm_changed(_realm_index: int, realm_name: String) -> void:
	realm_label.text = "【%s】" % realm_name
	# 简单的突破提示：闪烁一下境界名
	var tw = create_tween()
	tw.tween_property(realm_label, "modulate", Color.YELLOW, 0.15)
	tw.tween_property(realm_label, "modulate", Color.WHITE, 0.3)


func _on_player_lifespan_changed(months: int) -> void:
	_update_lifespan(months)


func _update_lifespan(months: int) -> void:
	@warning_ignore("integer_division")
	var years = months / 12
	var m = months % 12
	var time_str = "%d年%d月" % [years, m] if m > 0 else "%d年" % years
	lifespan_label.text = "寿元: " + time_str
	# 寿元低于 50 年变红
	if months < 600:
		lifespan_label.add_theme_color_override("font_color", Color(1, 0.3, 0.2))
	else:
		lifespan_label.add_theme_color_override("font_color", Color(0.7, 1, 0.7))


func _on_spirit_sense_changed(current: int, max_val: int) -> void:
	_update_spirit_sense(current, max_val)


func _update_spirit_sense(current: int, max_val: int) -> void:
	spirit_sense_bar.max_value = max_val
	spirit_sense_bar.value = clampi(current, 0, max_val)
	spirit_sense_label.text = "神识: %d / %d" % [current, max_val]

	if current < 0:
		# 透支状态：显示警告，栏变红
		spirit_sense_label.add_theme_color_override("font_color", Color(1, 0.3, 0.2))
		var ratio = absf(float(current)) / float(max_val)
		spirit_overdraft_label.text = "⚠ 神识透支! 每秒消耗寿元 (%.0f%%)" % (ratio * 100)
		spirit_overdraft_label.visible = true
	else:
		spirit_sense_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.2))
		spirit_overdraft_label.visible = false


func _update_kill_label() -> void:
	kill_label.text = "击杀: %d" % kill_count
