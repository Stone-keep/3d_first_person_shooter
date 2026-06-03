extends CanvasLayer

@export var player_hp_green: CompressedTexture2D
@export var player_hp_red: CompressedTexture2D

@onready var player_hp_bar: TextureProgressBar = $Control/PlayerInfo/PlayerHealthBackground/PlayerHealthBar
@onready var ammo_label: Label = $Control/PlayerInfo/AmmoLabel
@onready var reload_container: VBoxContainer = $Control/Reload
@onready var reload_progress_bar: ProgressBar = $Control/Reload/ReloadProgress
@onready var enemy_info: VBoxContainer = $Control/EnemyInfo
@onready var enemy_name_label: Label = $Control/EnemyInfo/EnemyNameLabel
@onready var enemy_health_bar: ProgressBar = $Control/EnemyInfo/EnemyHealthBar
@onready var timer_label: Label = $Control/TimerLabel

func update_player_current_hp(current_health: int, max_health: int):
	player_hp_bar.max_value = max_health
	
	var tween = create_tween()
	tween.tween_property(player_hp_bar, "value", current_health, 0.3)

	var value := player_hp_bar.value
	var max_value := player_hp_bar.max_value
	var red_bar_threshold = 0.3 * max_value

	if value <= red_bar_threshold:
		player_hp_bar.texture_progress = player_hp_red
	else:
		player_hp_bar.texture_progress = player_hp_green

func update_ammo(current_ammo: int, max_ammo: int):
	ammo_label.text = "Ammo: %s/%s" % [current_ammo, max_ammo]

func update_enemy_info(enemy_name: String, current_health: int, max_health: int) -> void:
	enemy_info.show()
	enemy_name_label.text = enemy_name
	enemy_health_bar.max_value = max_health
	enemy_health_bar.value = current_health

func hide_enemy_info() -> void:
	enemy_info.hide()

func reload_progress(max_ammo: int, time: float):
	reload_progress_bar.value = 0
	reload_container.show()

	var tween = create_tween()
	tween.tween_property(reload_progress_bar, "value", 100, time)
	await tween.finished

	update_ammo(max_ammo, max_ammo)
	reload_container.hide()

func update_timer_label(time_left: float):
	var total_seconds = ceili(time_left)
	var minutes = total_seconds / 60
	var seconds = total_seconds % 60
	timer_label.text = "Time Left: %02d:%02d" % [minutes, seconds]
	if total_seconds <= 10:
		timer_label.add_theme_color_override("font_color", Color.DARK_RED)
	elif total_seconds <= 30:
		timer_label.add_theme_color_override("font_color", Color.RED)
	elif total_seconds <= 60:
		timer_label.add_theme_color_override("font_color", Color.ORANGE)
	else:
		timer_label.add_theme_color_override("font_color", Color.WHITE)
