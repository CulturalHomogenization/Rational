extends Label

@export var show_duration: float = 1.0
@export var fade_duration: float = 0.5
@export var world_offset: Vector3 = Vector3(0, 2, 0)

var show_timer: Timer
var fade_tween: Tween
var target_node: Node3D
var camera: Camera3D

func _ready():
	modulate.a = 0.0
	visible = false
	z_index = 1000
	
	show_timer = Timer.new()
	add_child(show_timer)
	show_timer.wait_time = show_duration
	show_timer.one_shot = true
	show_timer.timeout.connect(_start_fade)
	
	camera = get_viewport().get_camera_3d()

func setup(station: Node3D):
	target_node = station

func show_message(message: String):
	text = message
	visible = true
	
	if target_node and camera:
		update_position()
	
	if fade_tween:
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.1)
	
	show_timer.start()

func _process(delta):
	if visible and target_node and camera:
		update_position()

func update_position():
	var world_pos = target_node.global_position + world_offset
	
	var camera_transform = camera.global_transform
	var to_point = world_pos - camera_transform.origin
	if to_point.dot(-camera_transform.basis.z) < 0:
		visible = false
		return
	
	visible = true
	
	var screen_pos = camera.unproject_position(world_pos)
	
	position = screen_pos - size / 2
	
	var screen_size = get_viewport().get_visible_rect().size
	position.x = clamp(position.x, 0, screen_size.x - size.x)
	position.y = clamp(position.y, 0, screen_size.y - size.y)

func _start_fade():
	if fade_tween:
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	fade_tween.tween_callback(func(): visible = false)
