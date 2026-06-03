extends Area3D

@onready var heart_model: Node3D = $Model

var heal_amount := 20

func _ready() -> void:
	animate()

func _process(delta: float) -> void:
	rotate_y(0.3 * delta)

func animate():
	var tween = create_tween()
	tween.set_loops()

	tween.tween_property(heart_model, "position:y", 0.15, 3.0)
	tween.tween_property(heart_model, "position:y", -0.15, 3.0)

func _on_body_entered(player: Node3D) -> void:
	if player.is_in_group("player"):
		if player.current_health < player.max_health:
			player.heal_up(heal_amount)
			call_deferred("queue_free")