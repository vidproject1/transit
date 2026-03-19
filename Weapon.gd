extends Node3D

## Simple Weapon controller to handle the "G" cocking animation.

@onready var slide_animator: Node3D = $Slide

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cock_weapon"):
		_cock_weapon()

func _cock_weapon() -> void:
	# Use the LocalAnimator's points
	# Point 0 is neutral, Point 1 is back
	if slide_animator.has_method("play_sequence"):
		# Play sequence 0 -> 1 -> 0
		var sequence: Array[int] = [1, 0]
		await slide_animator.play_sequence(sequence, 0.5)
	else:
		# Direct index manipulation if play_sequence isn't ready
		slide_animator.current_point_index = 1
		await get_tree().create_timer(0.1).timeout
		slide_animator.current_point_index = 0
