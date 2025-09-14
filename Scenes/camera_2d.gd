extends Camera2D

# Drag settings
var is_dragging = false
var drag_start_position = Vector2()

# Zoom settings
var zoom_min = Vector2(0.5, 0.5)
var zoom_max = Vector2(1.0, 1.0)
var zoom_speed = 0.1

# Boundary settings
@export var camera_bounds: Rect2 = Rect2(-800, -1300, 3200, 2500)
@export var show_bounds_in_editor: bool = true

func _ready():
	zoom = Vector2(1.0, 1.0)
	clamp_camera_to_bounds()

func _input(event):
	# Handle mouse wheel for zooming
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_drag(event.position)
			else:
				stop_drag()
	
	# Handle mouse motion for dragging
	elif event is InputEventMouseMotion:
		if is_dragging:
			drag_camera(event.position)

func start_drag(mouse_pos: Vector2):
	is_dragging = true
	drag_start_position = mouse_pos

func stop_drag():
	is_dragging = false

func drag_camera(mouse_pos: Vector2):
	# Calculate the difference and move camera
	var delta = (drag_start_position - mouse_pos) / zoom
	global_position += delta
	drag_start_position = mouse_pos
	
	# Clamp camera position to bounds
	clamp_camera_to_bounds()

func zoom_in():
	var new_zoom = zoom + Vector2(zoom_speed, zoom_speed)
	zoom = new_zoom.clamp(zoom_min, zoom_max)
	clamp_camera_to_bounds()

func zoom_out():
	var new_zoom = zoom - Vector2(zoom_speed, zoom_speed)
	zoom = new_zoom.clamp(zoom_min, zoom_max)
	clamp_camera_to_bounds()

func clamp_camera_to_bounds():
	# Get the camera's visible area in world space
	var viewport_size = get_viewport_rect().size
	var camera_half_size = viewport_size / (2.0 * zoom)
	
	# Calculate the allowed position range
	var min_pos = camera_bounds.position + camera_half_size
	var max_pos = camera_bounds.position + camera_bounds.size - camera_half_size
	
	# Clamp the camera position
	global_position.x = clamp(global_position.x, min_pos.x, max_pos.x)
	global_position.y = clamp(global_position.y, min_pos.y, max_pos.y)

# Optional: Reset camera to center of bounds
func reset_camera():
	global_position = camera_bounds.get_center()
	zoom = Vector2(1.0, 1.0)
	clamp_camera_to_bounds()

# Draw bounds in editor for visualization
func _draw():
	if Engine.is_editor_hint() and show_bounds_in_editor:
		draw_rect(camera_bounds, Color.RED, false, 2.0)
