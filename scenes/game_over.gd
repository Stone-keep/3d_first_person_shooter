extends Control

@onready var game_over_label: Label = $GameOverLabel
@onready var game_over_cause_label: Label = $GameOverCauseLabel
@onready var ek_score_label: Label = $ScoreContainer/EnemiesKilledScore
@onready var hl_score_label: Label = $ScoreContainer/HealthLeftScore
@onready var tl_score_label: Label = $ScoreContainer/TimeLeftScore
@onready var lp_score_label: Label = $ScoreContainer/LevelPassedScore
@onready var fs_text_label: Label = $FinalScoreDropContainer/FinalScoreLabel
@onready var fs_score_label: Label = $FinalScoreDropContainer/FinalScoreScore

@onready var restart_button: Button = $ButtonContainer/RestartButton


# Score
var enemies_killed_score: int
var health_left_score: int
var time_left_score: int
var level_passed_score: int
var final_score: int
var fs_text_landing_position: Vector2
var fs_score_landing_position: Vector2

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	restart_button.grab_focus()
	Global.play_game_over_music()

	await get_tree().process_frame
	count_score()
	update_game_over_label()
	setup_final_score_labels()
	update_score_animation()

func count_score() -> void:
	enemies_killed_score = Global.final_enemies_killed * 1000
	health_left_score = Global.final_health_left * 150
	time_left_score = floori(Global.final_time_left) * 50
	level_passed_score = 5000 if Global.last_level_won else 0
	final_score = enemies_killed_score + health_left_score + time_left_score + level_passed_score

func update_game_over_label():
	match Global.last_loss_cause:
		Global.LossCause.VICTORY:
			game_over_label.text = "Level Passed"
			game_over_cause_label.text = "Congratulations!"
		Global.LossCause.HEALTH:
			game_over_label.text = "Level Failed"
			game_over_cause_label.text = "You Got Killed By The Enemy"
		Global.LossCause.FALL:
			game_over_label.text = "Level Failed"
			game_over_cause_label.text = "You Fell To Your Death"
		Global.LossCause.TIMEOUT:
			game_over_label.text = "Level Failed"
			game_over_cause_label.text = "You Ran Out Of Time"

func update_score_animation():
	await wait(1.5)

	await count_score_animation(ek_score_label, 0, enemies_killed_score, 2.0)

	await wait(0.5)
	
	await count_score_animation(hl_score_label, 0, health_left_score, 2.0)

	await wait(0.5)

	await count_score_animation(tl_score_label, 0, time_left_score, 2.0)

	await wait(0.5)

	await count_score_animation(lp_score_label, 0, level_passed_score, 2.0)

	await wait(1.0)
	await final_score_slam()

func setup_final_score_labels() -> void:
	fs_text_landing_position = fs_text_label.position
	fs_score_landing_position = fs_score_label.position
	fs_score_label.text = format_score(final_score)
	setup_drop_label(fs_text_label, fs_text_landing_position)
	setup_drop_label(fs_score_label, fs_score_landing_position)

func setup_drop_label(label: Label, landing_position: Vector2) -> void:
	label.pivot_offset = label.size / 2.0
	label.position = landing_position + Vector2(0, -450)
	label.scale = Vector2(1.8, 1.8)
	label.hide()

func final_score_slam() -> void:
	drop_label(fs_text_label, fs_text_landing_position)
	await wait(0.5)
	var score_tween := drop_label(fs_score_label, fs_score_landing_position)
	shake_screen(0.5, 15.0)
	await score_tween.finished

func drop_label(label: Label, landing_position: Vector2) -> Tween:
	label.show()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", landing_position, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween

func shake_screen(duration: float, strength: float) -> void:
	var original_position := position
	var tween := create_tween()
	var shake_count := 12
	var step_time := duration / shake_count

	for i in range(shake_count):
		var offset := Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		tween.tween_property(self, "position", original_position + offset, step_time)

	tween.tween_property(self, "position", original_position, step_time)

func count_score_animation(label: Label, from_value: int, to_value: int, duration: float) -> void:
	var tween := create_tween()
	tween.tween_method(
		func(value: float):
			label.text = format_score(roundi(value)),
		float(from_value),
		float(to_value),
		duration
	)
	await tween.finished

func format_score(value: int) -> String:
	return "%d" % value

func wait(time: float) -> void:
	await get_tree().create_timer(time).timeout

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return

	if event.is_action_pressed("jump"):
		var viewport := get_viewport()
		var focused_control := viewport.gui_get_focus_owner()
		if focused_control is Button:
			viewport.set_input_as_handled()
			focused_control.pressed.emit()

func _on_restart_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().quit()