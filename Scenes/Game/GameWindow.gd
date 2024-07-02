extends Camera2D

@export_group("Camera Options")
@export var scrollSpeed := 1000
@export_subgroup("Zoom")
@export var max_zoom_out := 0.5
@export var max_zoom_in := 5
@export var zoomStep := 0.01
@export_exp_easing("inout") var zoomEase := ease(0.25, 2)

var dragStartPosition: Vector2
var dragging: bool
var zoomTarget: Vector2
enum ZoomDirection {IN, OUT}

func _ready():
	zoomTarget = zoom


func _process(delta: float):
	if not dragging:
		position += handle_movement(Input.get_vector("leftKey", "rightKey", "upKey", "downKey"), delta)
	if Input.is_action_pressed("middleMouse") and dragging:
		position += (dragStartPosition - get_global_mouse_position())
	if zoom != zoomTarget:
		zoom = zoom.lerp(zoomTarget, zoomEase)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoomTarget *= 1.1
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoomTarget /= 1.1
	elif event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_MIDDLE:
		position -= event.relative / zoom

func handle_zoom(direction: ZoomDirection):
	return clamp(zoomTarget + Vector2(zoomStep, zoomStep)
		if direction == ZoomDirection.IN 
		else zoomTarget - Vector2(zoomStep,zoomStep),
		Vector2(max_zoom_out, max_zoom_out),
		Vector2(max_zoom_in, max_zoom_in)
		)

func handle_movement(direction: Vector2, delta: float):
	return direction * scrollSpeed * delta

