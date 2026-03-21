extends Node3D

@export var enemy_scene: PackedScene = preload("res://Enemy.tscn")
@export var spawn_delay: float = 2.0
@export var auto_spawn: bool = true

var current_enemy: Node3D = null

func _ready():
	if auto_spawn:
		spawn_enemy()

func spawn_enemy():
	if current_enemy:
		return
		
	var new_enemy = enemy_scene.instantiate()
	# Add to the world, not as child of spawner to keep transforms clean if spawner moves
	get_tree().root.add_child.call_deferred(new_enemy)
	new_enemy.global_position = global_position
	current_enemy = new_enemy
	
	# Connect to the health signal
	var health = new_enemy.get_node_or_null("Health")
	if health:
		health.died.connect(_on_enemy_death)
	else:
		# Fallback if no health node
		new_enemy.tree_exited.connect(_on_enemy_death)

func _on_enemy_death():
	current_enemy = null
	await get_tree().create_timer(spawn_delay).timeout
	spawn_enemy()
