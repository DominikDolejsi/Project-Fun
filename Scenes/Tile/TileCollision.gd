extends CollisionPolygon2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func handle_collision_polygon(parentPolygon: PackedVector2Array):
	set_polygon(parentPolygon)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
