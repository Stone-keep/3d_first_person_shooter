extends Node

@onready var bgm_player: AudioStreamPlayer = $BackgroundMusic

var current_track := 0

const GAMEPLAY_MUSIC := [
	preload("res://audio/music/5. Beyond the Star Gate.ogg"),
	preload("res://audio/music/10. Edge of the Galaxy.ogg"),
	preload("res://audio/music/15. Collapse of the Core.ogg")
]

const GAME_OVER_MUSIC := preload("res://audio/music/25. Signals Across.ogg")

func _ready() -> void:
	current_track = randi_range(0, GAMEPLAY_MUSIC.size()-1)
	bgm_player.stream = GAMEPLAY_MUSIC[current_track]
	play_gameplay_music()

func play_gameplay_music():
	bgm_player.stream = GAMEPLAY_MUSIC[current_track]
	bgm_player.play()

func _on_background_music_finished() -> void:
	current_track = posmod(current_track + 1, GAMEPLAY_MUSIC.size()-1)
	bgm_player.stream = GAMEPLAY_MUSIC[current_track]
	bgm_player.play()