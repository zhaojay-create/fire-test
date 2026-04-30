extends CanvasLayer

signal skill_chosen(skill_id: String)

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
		var btn = Button.new()
		btn.text = pick["label"]
		btn.tooltip_text = pick["description"]
		btn.custom_minimum_size = Vector2(400, 60)
		btn.add_theme_font_size_override("font_size", 22)
		var sid = pick["id"] as String
		btn.pressed.connect(_on_btn_pressed.bind(sid))
		_btn_container.add_child(btn)


func _on_btn_pressed(skill_id: String) -> void:
	skill_chosen.emit(skill_id)
	queue_free()
