extends CanvasLayer

@export var player_hp_green: CompressedTexture2D
@export var player_hp_red: CompressedTexture2D

@onready var player_hp_bar: TextureProgressBar = $Control/PlayerInfo/PlayerHealthBar

func update_player_current_hp(current_health: int, max_health: int):
	player_hp_bar.max_value = max_health
	player_hp_bar.value = current_health

	var value := player_hp_bar.value
	var max_value := player_hp_bar.max_value
	var red_bar_threshold = 0.3 * max_value
	
	if value <= red_bar_threshold:
		player_hp_bar.texture_progress = player_hp_red
	else:
		player_hp_bar.texture_progress = player_hp_green