extends VehicleBody3D

signal get_reinforcements

enum State { PASSIVE, AGGRO, RUNNING }

@export var wheel_engine_force: float = 500.0
@export var wheel_brake_force: float = 50.0
@export var steer_angle: float = 0.5
@export var detection_range: float = 40.0
@export var fire_range: float = 25.0
@export var health: float = 100.0
@export var low_health_threshold: float = 30.0
@export var run_duration: float = 5.0

@onready var turret: Node3D = $Turret
@onready var muzzle_point: Node3D = $Turret/MuzzlePoint
@onready var detection_area: Area3D = $DetectionArea
@onready var patrol_timer: Timer = $PatrolTimer
@onready var shoot_timer: Timer = $ShootTimer

# Wheels
@onready var left_wheels := [
	$LeftWheel1, $LeftWheel2, $LeftWheel3, $LeftWheel4, $LeftWheel5
]
@onready var right_wheels := [
	$RightWheel1, $RightWheel2, $RightWheel3, $RightWheel4, $RightWheel5
]

var state: State = State.PASSIVE
var player: Node3D
var run_timer: float = 0.0
var patrol_direction: Vector3 = Vector3.ZERO

func _ready():
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	patrol_timer.timeout.connect(_on_patrol_timeout)
	shoot_timer.timeout.connect(_shoot)
	_set_random_patrol_direction()

func _physics_process(delta):
	match state:
		State.PASSIVE:
			_patrol(delta)
		State.AGGRO:
			_chase_and_attack(delta)
		State.RUNNING:
			_run_away(delta)

	if health <= low_health_threshold and state != State.RUNNING:
		state = State.RUNNING
		run_timer = run_duration

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player = body
		state = State.AGGRO

func _on_body_exited(body):
	if body == player:
		player = null
		state = State.PASSIVE

# ------------------
# PATROL STATE
# ------------------
func _patrol(delta):
	_drive_towards(patrol_direction)
	if patrol_timer.is_stopped():
		patrol_timer.start()

func _set_random_patrol_direction():
	var angle = randf_range(0, TAU)
	patrol_direction = Vector3(cos(angle), 0, sin(angle)).normalized()

func _on_patrol_timeout():
	_set_random_patrol_direction()

# ------------------
# AGGRO STATE
# ------------------
func _chase_and_attack(delta):
	if not player: return
	var direction = (player.global_transform.origin - global_transform.origin).normalized()
	_drive_towards(direction)
	_aim_turret(direction)

	if global_transform.origin.distance_to(player.global_transform.origin) <= fire_range and shoot_timer.is_stopped():
		shoot_timer.start()

func _aim_turret(direction):
	turret.look_at(global_transform.origin + direction, Vector3.UP)

func _shoot():
	if player:
		print("Bang!") # Replace with bullet or raycast fire

# ------------------
# RUNNING STATE
# ------------------
func _run_away(delta):
	if not player: return
	var direction = (global_transform.origin - player.global_transform.origin).normalized()
	_drive_towards(direction)
	run_timer -= delta
	if run_timer <= 0:
		emit_signal("get_reinforcements")
		state = State.PASSIVE

# ------------------
# VEHICLE CONTROL - WHEEL FORCES
# ------------------
# Drive using differential tracks (left/right) toward a WORLD-SPACE direction
func _drive_towards(direction: Vector3):
	var dir := direction
	dir.y = 0
	if dir.length() < 0.001:
		# stop if no intent
		for wheel in left_wheels: wheel.engine_force = 0; wheel.brake = wheel_brake_force
		for wheel in right_wheels: wheel.engine_force = 0; wheel.brake = wheel_brake_force
		return

	dir = dir.normalized()
	var b := global_transform.basis

	# Forward: + when target is in front of the tank (−Z is forward in Godot)
	var forward = clamp(-b.z.dot(dir), -1.0, 1.0)
	# Turn: + when target is to the tank's right (basis.x is right)
	var turn = clamp(b.x.dot(dir), -1.0, 1.0)

	# Differential mixing (RHR): right+ turns right, left− turns right
	var left_power = forward + turn
	var right_power = forward - turn

	# Normalize so diagonals aren't stronger
	var m = max(abs(left_power), abs(right_power))
	if m > 1.0:
		left_power /= m
		right_power /= m

	# Apply to wheels with a small deadzone -> brake when near zero
	for wheel in left_wheels:
		wheel.engine_force = wheel_engine_force * left_power
		wheel.brake = 0 if abs(left_power) > 0.05 else wheel_brake_force

	for wheel in right_wheels:
		wheel.engine_force = wheel_engine_force * right_power
		wheel.brake = 0 if abs(right_power) > 0.05 else wheel_brake_force
