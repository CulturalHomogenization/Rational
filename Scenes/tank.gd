extends VehicleBody3D

const ENGINE_POWER = 3000

@onready var left_wheels = [$RearLeft, $FrontLeft]
@onready var right_wheels = [$RearRight, $FrontRight]


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta: float) -> void:
	var steer = Input.get_axis("right", "left")
	var move_dir = Input.get_axis("down", "up")
	if steer != 0 and move_dir != 0:
		for wheel in left_wheels:
			wheel.engine_force = ENGINE_POWER * (move_dir-steer) * 2
		for wheel in right_wheels:
			wheel.engine_force = ENGINE_POWER * (move_dir+steer) * 2
	elif steer != 0:
		for wheel in left_wheels:
			wheel.engine_force = ENGINE_POWER * -steer * 2
		for wheel in right_wheels:
			wheel.engine_force = ENGINE_POWER * steer * 2
	else:
		for wheel in left_wheels:
			wheel.engine_force = ENGINE_POWER * move_dir
		for wheel in right_wheels:
			wheel.engine_force = ENGINE_POWER * move_dir
