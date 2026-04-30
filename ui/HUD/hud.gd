extends CanvasLayer

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var kill_label: Label = $MarginContainer/VBoxContainer/KillLabel
@onready var xp_bar: ProgressBar = $XpBarContainer/XpBar

var kill_count: int = 0


func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		health_bar.max_value = player.max_hp
		health_bar.value = player.current_hp
		player.health_changed.connect(_on_player_health_changed)
		player.xp_gained.connect(_on_player_xp_gained)

	get_tree().node_removed.connect(_on_node_removed)
	_update_kill_label()


func _on_player_health_changed(current_hp: int, max_hp: int) -> void:
	health_bar.max_value = max_hp
	health_bar.value = current_hp


func _on_node_removed(node: Node) -> void:
	if node.is_in_group("enemy"):
		kill_count += 1
		_update_kill_label()


func _on_player_xp_gained(current_xp: int) -> void:
	xp_bar.value = current_xp


func _update_kill_label() -> void:
	kill_label.text = "击杀: %d" % kill_count
