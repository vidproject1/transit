extends Node3D

@export var spawn_delay: float = 2.0
var enemy_scene = load("res://Enemy.tscn")

func _ready():
	var health = get_parent().get_node_or_null("Health")
	if health:
		health.died.connect(_on_death)

func _on_death():
	var spawn_pos = global_position
	# Wait for cleanup
	await get_tree().create_timer(spawn_delay).timeout
	var new_enemy = enemy_scene.instantiate()
	get_tree().root.add_child(new_enemy)
	new_enemy.global_position = spawn_pos
