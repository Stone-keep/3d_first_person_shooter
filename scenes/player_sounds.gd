extends Node3D

@onready var walk_player: AudioStreamPlayer = $Walk
@onready var run_player: AudioStreamPlayer = $Run
@onready var jump_player: AudioStreamPlayer = $Jump
@onready var change_weapon_player: AudioStreamPlayer = $ChangeWeapon

var jump_sounds := [preload("res://audio/jump_a.ogg"), preload("res://audio/jump_b.ogg")]

func play_jump_sound():
	var sound = jump_sounds.pick_random()
	jump_player.stream = sound
	jump_player.play()

func play_change_weapon_sound():
	change_weapon_player.play()

func play_walk_sound():
	if not walk_player.playing:
		stop_walk_and_run_sound()
		walk_player.play()

func play_run_sound():
	if not run_player.playing:
		stop_walk_and_run_sound()
		run_player.play()

func stop_walk_and_run_sound():
	walk_player.stop()
	run_player.stop()

func stop_all_sounds():
	for child in get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer2D or child is AudioStreamPlayer3D:
			child.stop()
