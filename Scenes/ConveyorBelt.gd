extends Area3D

@export var conveyor_direction := Vector3(1, 0, 0)
@export var conveyor_speed := 5.0          # Target conveyor speed (units/s)
@export var max_force := 100.0             # Maximum force magnitude to apply

func _physics_process(delta):
	for body in get_overlapping_bodies():
		if body is RigidBody3D:
			var conveyor_dir_norm = conveyor_direction.normalized()
			var velocity_along_conveyor = body.linear_velocity.dot(conveyor_dir_norm)

			if velocity_along_conveyor < conveyor_speed:
				var velocity_diff = conveyor_speed - velocity_along_conveyor
				# Calculate needed force: F = m * a = m * (Δv / Δt)
				var force = conveyor_dir_norm * velocity_diff * body.mass / delta
				
				# Clamp force magnitude to max_force
				if force.length() > max_force:
					force = force.normalized() * max_force
				
				body.apply_central_force(force)
			else:
				# Slow down if too fast (drag)
				var excess_velocity = velocity_along_conveyor - conveyor_speed
				var drag_force = -conveyor_dir_norm * excess_velocity * body.mass / delta
				
				# Clamp drag force magnitude
				if drag_force.length() > max_force:
					drag_force = drag_force.normalized() * max_force
				
				body.apply_central_force(drag_force)
