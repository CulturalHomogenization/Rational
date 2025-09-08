extends Label3D

@export var show_duration: float = 1.0
@export var fade_duration: float = 0.5

var show_timer: Timer
var fade_tween: Tween

func _ready():
	modulate.a = 0.0
	visible = false
	
	show_timer = Timer.new()
	add_child(show_timer)
	show_timer.wait_time = show_duration
	show_timer.one_shot = true
	show_timer.timeout.connect(_start_fade)

func show_message(message: String):
	text = message
	visible = true
	
	if fade_tween:
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.1)
	
	show_timer.start()

func _start_fade():
	if fade_tween:
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	fade_tween.tween_callback(func(): visible = false)
