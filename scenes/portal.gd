extends Area3D

@onready var opening_sound: AudioStreamPlayer3D = $OpeningSound
@onready var buzz_sound: AudioStreamPlayer3D = $BuzzSound

signal player_entered()

func _ready() -> void:
	spawn_animation()

func spawn_animation():
	var tween = create_tween()
	opening_sound.play()
	tween.tween_property(self, "scale", Vector3(1.0, 1.0, 2.0), 1.0).from(Vector3(0.01, 0.01, 0.01))
	await tween.finished
	opening_sound.stop()
	buzz_sound.play()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_entered.emit()