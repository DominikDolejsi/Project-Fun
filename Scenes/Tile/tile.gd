extends Polygon2D

var gridPosition: Vector3
var axialPosition: Vector2:
	set(new_axialPosition):
		axialPosition = new_axialPosition
	get:
		return axialPosition

var canvasPosition: Vector2
var isFlat: bool
var size := 100.0
var width := sqrt(3) * size
var height := 2.0 * size
var horizontalSpacing: float = sqrt(3) * size
var verticalSpacing: float = (3.0/2.0) * size
var gridStep: float
var hexagonCorners: PackedVector2Array:
	set(newHexagonCorners):
		hexagonCorners = newHexagonCorners
	get:
		return hexagonCorners

	
signal mouseEntered

func _ready():
	if isFlat:
		adjust_for_orientation()
	
	gridPosition = Vector3(axialPosition.x, axialPosition.y, -axialPosition.x - axialPosition.y)
	
	canvasPosition = Vector2(horizontalSpacing * axialPosition.x, verticalSpacing * axialPosition.y)
	if isFlat:
		canvasPosition.y += gridStep
	else:
		canvasPosition.x += gridStep
	
	position = canvasPosition
	
	draw_hexagon()
	
	$TileArea/TileCollision.handle_collision_polygon(hexagonCorners)
	
	pass


func _init(initialPosition: Vector2, initialSize: float, initialFlatnes: bool):
	isFlat = initialFlatnes
	size = initialSize
	axialPosition = Vector2(initialPosition.x, initialPosition.y)
	gridStep = sqrt(3) * size/2.0 * axialPosition.y
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func draw_hexagon():
	var corners := PackedVector2Array([])
	var offsetDegree := 0 if isFlat else 30
	
	for x in range(6):
		corners.append(Vector2(size, 0).rotated(deg_to_rad(60 * x + offsetDegree)))
	
	hexagonCorners = corners

	set_polygon(hexagonCorners)
	
	set_color(Color("Olive Drab"))

func change_color():
	if get_color() == Color("Olive Drab"):
		set_color(Color("Bisque"))
	else:
		set_color(Color("Olive Drab"))

func set_isFlat(flatnes: bool):
	self.isFlat = flatnes

func adjust_for_orientation():
	width =  2 * size
	height = sqrt(3) * size
	horizontalSpacing = 3.0/2.0 * size
	verticalSpacing = sqrt(3) * size
	gridStep = sqrt(3) * size/2.0 * axialPosition.x
