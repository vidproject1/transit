extends Node
class_name Health

## Health System: Manages HP and death logic for NPCs.

@export var max_health: float = 30.0
@export var headshot_multiplier: float = 3.0

var current_health: float

signal health_changed(new_health)
signal died

func _ready():
	current_health = max_health

func take_damage(amount: float, is_headshot: bool = false):
	var damage = amount
	if is_headshot:
		damage *= headshot_multiplier
		print("HEADSHOT! Dealing ", damage, " damage.")
	
	current_health -= damage
	health_changed.emit(current_health)
	print("NPC took ", damage, " damage. HP left: ", current_health)
	
	if current_health <= 0:
		_die()

func _die():
	print("NPC Died!")
	died.emit()
	# The parent script (like NpcPathfollower) should handle the actual cleanup/ragdoll
	if get_parent().has_method("die"):
		get_parent().die()
	else:
		get_parent().queue_free()
