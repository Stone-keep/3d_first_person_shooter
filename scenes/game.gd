extends Node3D

@onready var player: CharacterBody3D = $Characters/Player
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	player.health_changed.connect(_on_player_health_changed)
	hud.update_player_current_hp(player.current_health, player.max_health)


func _on_player_health_changed(hp_current: int, hp_max: int):
	hud.update_player_current_hp(hp_current, hp_max)