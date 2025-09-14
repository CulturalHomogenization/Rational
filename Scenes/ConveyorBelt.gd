extends Area3D

@export var conveyor_direction := Vector3(1, 0, 0)
@export var conveyor_speed := 1.0          # Target conveyor speed (units/s)
@onready var timer: Timer = $"../Timer"
@onready var marker_3d: Marker3D = $"../Marker3D"
const COAL = preload("res://Scenes/coal.tscn")
const IRON = preload("res://Scenes/iron.tscn")
const JUNK = preload("res://Scenes/junk.tscn")
var resources = [
		{ "scene": JUNK, "weight": 90 },
		{ "scene": COAL, "weight": 5 },
		{ "scene": IRON, "weight": 5 },
	]

func _ready() -> void:
	print("hello")
	timer.start()

func _physics_process(delta):
	for body in get_overlapping_bodies():
		if body is RigidBody3D:
			var conveyor_velocity = conveyor_direction.normalized() * conveyor_speed
			var current_velocity = body.linear_velocity
			# Keep other velocity components (e.g., vertical) intact if needed
			body.linear_velocity = conveyor_velocity + current_velocity - current_velocity.project(conveyor_direction)

func _on_timer_timeout() -> void:
	timer.start(randi_range(2, 8))
	var total_weight = 0
	for res in resources:
		total_weight += res.weight
	var roll = randf() * total_weight
	var cumulative = 0

	var selected_scene = JUNK # fallback

	for res in resources:
		cumulative += res.weight
		if roll < cumulative:
			selected_scene = res.scene
			break
	var instance = selected_scene.instantiate()
	instance.global_position = marker_3d.global_position
	get_tree().get_root().add_child(instance)
	


func _on_delete_item_body_entered(body: Node3D) -> void:
	if body is Interactable:
		body.queue_free()
