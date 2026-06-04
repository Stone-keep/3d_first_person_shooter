extends Node3D

@export var portal_scene: PackedScene
@export var morning_color := Color(0.722, 1.0, 0.604)
@export var daylight_color := Color(0.918, 1.0, 0.839)
@export var sunset_color := Color(1.0, 0.604, 0.388)
@export var half_day_time := 300.0

@onready var player: CharacterBody3D = $Characters/Player
@onready var hud: CanvasLayer = $HUD
@onready var game_timer: Timer = $GameTimer
@onready var enviornement: WorldEnvironment = $Enviornement
@onready var sun: DirectionalLight3D = $Sun
@onready var sky_material: ProceduralSkyMaterial = enviornement.environment.sky.sky_material

var portal_position := Vector3(-45.3, 0.7, 8.73)

func _ready() -> void:
	player.health_changed.connect(_on_player_health_changed)
	player.ammo_changed.connect(_on_player_ammo_changed)
	player.weapon_reload.connect(_on_player_weapon_reload)
	player.targeted_enemy_updated.connect(_on_player_targeted_enemy_updated)
	player.targeted_enemy_lost.connect(_on_player_targeted_enemy_lost)
	hud.update_player_current_hp(player.current_health, player.max_health)
	enviornement_animation()

func _process(_delta: float) -> void:
	hud.update_timer_label(game_timer.time_left)

func enviornement_animation():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sun, "light_energy", 1.0, half_day_time)
	tween.tween_property(sun, "light_color", daylight_color, half_day_time)
	tween.tween_property(sun, "rotation_degrees", Vector3(-90, 100, 0), half_day_time)
	tween.tween_property(sky_material, "sky_top_color", Color(0.16, 0.24, 0.18), half_day_time)
	tween.tween_property(sky_material, "sky_horizon_color", Color(0.70, 0.78, 0.48), half_day_time)
	tween.tween_property(sky_material, "ground_horizon_color", Color(0.70, 0.78, 0.48), half_day_time)
	tween.tween_property(sky_material, "ground_bottom_color", Color(0.08, 0.10, 0.055), half_day_time)
	tween.tween_property(enviornement.environment, "ambient_light_color", Color(0.42, 0.50, 0.30), half_day_time)
	tween.tween_property(enviornement.environment, "fog_light_color", Color(0.70, 0.78, 0.48), half_day_time)
	tween.tween_property(enviornement.environment, "volumetric_fog_albedo", Color(0.70, 0.78, 0.48), half_day_time)
	tween.tween_property(enviornement.environment, "volumetric_fog_density", 0, half_day_time)
	tween.chain()
	tween.tween_property(sun, "light_energy", 0.8, half_day_time)
	tween.tween_property(sun, "light_color", sunset_color, half_day_time)
	tween.tween_property(sun, "rotation_degrees", Vector3(-170, 100, 0), half_day_time)
	tween.tween_property(sky_material, "sky_top_color", Color(0.11, 0.055, 0.10), half_day_time)
	tween.tween_property(sky_material, "sky_horizon_color", Color(0.82, 0.36, 0.26), half_day_time)
	tween.tween_property(sky_material, "ground_horizon_color", Color(0.82, 0.36, 0.26), half_day_time)
	tween.tween_property(sky_material, "ground_bottom_color", Color(0.055, 0.035, 0.035), half_day_time)
	tween.tween_property(enviornement.environment, "ambient_light_color", Color(0.45, 0.26, 0.20), half_day_time)
	tween.tween_property(enviornement.environment, "fog_light_color", Color(0.82, 0.36, 0.26), half_day_time)
	tween.tween_property(enviornement.environment, "volumetric_fog_albedo", Color(0.82, 0.36, 0.26), half_day_time)
	tween.tween_property(enviornement.environment, "volumetric_fog_density", 0.014, half_day_time)

func spawn_portal(location: Vector3) -> void:
	var portal = portal_scene.instantiate()
	add_child(portal)
	portal.global_position = location
	portal.player_entered.connect(_on_portal_player_entered)

func lose_game(cause: String) -> void:
	var final_time := game_timer.time_left
	game_timer.stop()
	update_stats(false, player.enemies_killed, player.current_health, final_time, cause)
	

func win_game() -> void:
	var final_time := game_timer.time_left
	game_timer.stop()
	update_stats(true, player.enemies_killed, player.current_health, final_time)

func update_stats(won: bool, enemies_killed: int, health_left: int, time_left: float, loss_cause: String = ""):
	Global.last_level_won = won
	Global.final_enemies_killed = enemies_killed
	Global.final_health_left = health_left
	Global.final_time_left = time_left
	Global.last_loss_cause = loss_cause


func _on_player_health_changed(hp_current: int, hp_max: int):
	hud.update_player_current_hp(hp_current, hp_max)
	if hp_current <= 0:
		lose_game("health")

func _on_player_ammo_changed(current_ammo: int, max_ammo: int):
	hud.update_ammo(current_ammo, max_ammo)

func _on_player_weapon_reload(max_ammo: int, time: float):
	await hud.reload_progress(max_ammo, time)

func _on_player_targeted_enemy_updated(enemy_name: String, current_health: int, max_health: int):
	hud.update_enemy_info(enemy_name, current_health, max_health)

func _on_player_targeted_enemy_lost():
	hud.hide_enemy_info()

func _on_death_zone_body_entered(body: Node3D) -> void:
	if body == player:
		lose_game("fall")

func _on_game_timer_timeout() -> void:
	lose_game("timeout")

func _on_portal_player_entered() -> void:
	win_game()

func _on_portal_test_timeout() -> void:
	spawn_portal(Vector3(-0.127, 0.813, 0.343))
