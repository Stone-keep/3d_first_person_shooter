extends Node3D

@export var morning_color := Color(0.722, 1.0, 0.604)
@export var daylight_color := Color(0.918, 1.0, 0.839)
@export var sunset_color := Color(1.0, 0.604, 0.388)
@export var half_day_time := 300.0

@onready var player: CharacterBody3D = $Characters/Player
@onready var hud: CanvasLayer = $HUD
@onready var enviornement: WorldEnvironment = $Enviornement
@onready var sun: DirectionalLight3D = $Sun
@onready var sky_material: ProceduralSkyMaterial = enviornement.environment.sky.sky_material

func _ready() -> void:
	player.health_changed.connect(_on_player_health_changed)
	hud.update_player_current_hp(player.current_health, player.max_health)
	enviornement_animation()

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

func _on_player_health_changed(hp_current: int, hp_max: int):
	hud.update_player_current_hp(hp_current, hp_max)
