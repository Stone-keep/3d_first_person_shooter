extends Node

@onready var bgm_player: AudioStreamPlayer = $BackgroundMusic

const SAVE_PATH := "user://save_data.dat"
const SAVE_VERSION := 1

var current_track := 0

# Score

var last_level_won: bool
var last_loss_cause: LossCause
var final_enemies_killed: int
var final_health_left: int
var final_time_left: float
var high_score := 0

enum LossCause {
	VICTORY,
	HEALTH,
	FALL,
	TIMEOUT
}

const GAMEPLAY_MUSIC := [
	preload("res://audio/music/5. Beyond the Star Gate.ogg"),
	preload("res://audio/music/10. Edge of the Galaxy.ogg"),
	preload("res://audio/music/15. Collapse of the Core.ogg")
]

const GAME_OVER_MUSIC := preload("res://audio/music/22. Abandoned Mining Zone.ogg")

var bgm_volume_normal := -10
var bgm_volume_muted := -60

func _ready() -> void:
	load_save_data()
	current_track = randi_range(0, GAMEPLAY_MUSIC.size()-1)
	play_gameplay_music()

func submit_high_score(score: int) -> bool:
	if score <= high_score:
		return false

	high_score = score
	save_data()
	return true

func save_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_warning("Could not open high score save file for writing.")
		return

	var data := {
		"save_version": SAVE_VERSION,
		"high_score": high_score
	}
	file.store_var(data)

func load_save_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_warning("Could not open high score save file for reading.")
		return

	var data = file.get_var()
	if data is not Dictionary:
		push_warning("High score save data is invalid.")
		return

	var save_version := int(data.get("save_version", 0))
	if save_version > SAVE_VERSION:
		push_warning("High score save data is from a newer version.")
		return

	high_score = maxi(int(data.get("high_score", 0)), 0)

func play_gameplay_music():
	bgm_player.stop()
	bgm_player.volume_db = bgm_volume_normal
	bgm_player.stream = GAMEPLAY_MUSIC[current_track]
	bgm_player.play()

func play_game_over_music():
	bgm_player.stop()
	bgm_player.volume_db = bgm_volume_normal
	bgm_player.stream = GAME_OVER_MUSIC
	bgm_player.play()

func fade_out_music(time: float):
	var tween = create_tween()
	tween.tween_property(bgm_player, "volume_db", bgm_volume_muted, time)

func _on_background_music_finished() -> void:
	if not bgm_player.stream == GAME_OVER_MUSIC:
		current_track = posmod(current_track + 1, GAMEPLAY_MUSIC.size()-1)
		bgm_player.stream = GAMEPLAY_MUSIC[current_track]
		bgm_player.play()
