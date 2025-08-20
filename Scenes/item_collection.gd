extends StaticBody3D
class_name ItemCollectionArea

@export var pickup_type: String = "coal"
@onready var area_3d: Area3D = $CollectionArea

func _ready():
	area_3d.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D):
	if not body.is_in_group("pickup"):
		return
	# Check if body's id matches our pickup type
	if body.id != pickup_type:
		return
	await get_tree().create_timer(3.0).timeout
	
	if not area_3d.has_overlapping_bodies() or body not in area_3d.get_overlapping_bodies():
		return
	body.queue_free()
