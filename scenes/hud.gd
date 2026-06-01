extends CanvasLayer

@export var player_hp_green: CompressedTexture2D
@export var player_hp_red: CompressedTexture2D

@onready var player_hp_bar: TextureProgressBar = $Control/PlayerInfo/PlayerHealthBackground/PlayerHealthBar

func update_player_current_hp(current_health: int, max_health: int):
	player_hp_bar.max_value = max_health
	
	var tween = create_tween()
	tween.tween_property(player_hp_bar, "value", current_health, 0.2)

	var value := player_hp_bar.value
	var max_value := player_hp_bar.max_value
	var red_bar_threshold = 0.3 * max_value

	if value <= red_bar_threshold:
		player_hp_bar.texture_progress = player_hp_red
	else:
		player_hp_bar.texture_progress = player_hp_green
