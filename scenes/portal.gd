extends Area3D

@onready var opening_sound: AudioStreamPlayer3D = $OpeningSound

signal player_entered()

func _ready() -> void:
	spawn_animation()

func spawn_animation():
	var tween = create_tween()
	tween.tween_property (self, "scale", Vector3(1.0, 1.0, 1.0), 1.0).from(Vector3(0.01, 0.01, 0.01))
	opening_sound.play()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_entered.emit()