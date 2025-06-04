extends Node3D

@onready var path := $Path3D
@export var road_segment_scene: PackedScene
@export var segment_spacing: float = 2.0
@export var number_of_points: int = 30
@export var point_spacing: float = 5.0
@export var wiggle_amount: float = 3.0

func _ready():
	generate_curve()
	generate_road()

func generate_curve():
	var curve = path.curve
	curve.clear_points()

	var x := 0.0
	for i in range(number_of_points):
		var y := sin(i * 0.4) * wiggle_amount
		var z := randf_range(-wiggle_amount, wiggle_amount)
		var point := Vector3(x, y, z)
		curve.add_point(point)
		x += point_spacing

func generate_road():
	var curve = path.curve
	if curve.get_point_count() < 2:
		push_error("Not enough points in path.")
		return

	var distance := 0.0
	var total_length = curve.get_baked_length()

	while distance < total_length:
		var position = curve.sample_baked(distance)
		var next_pos = curve.sample_baked(min(distance + 1.0, total_length))
		var forward = (next_pos - position).normalized()

		var transform := Transform3D().looking_at(position + forward, Vector3.UP)
		transform.origin = position

		var segment = road_segment_scene.instantiate()
		segment.transform = transform
		add_child(segment)

		distance += segment_spacing
