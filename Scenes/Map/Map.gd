extends Node2D

var gridSize: int = 7
var gridRadius: int = (gridSize - 1) / 2
var gridArray: Array
var tileArray: Array
@export var hexSize := 100.0
var focusedTile := []

func _ready():
	var tileNode = load("res://Scenes/Tile/tile.gd")
	
# This is for creating rectangular map pointed
	for coordinateY in range(gridSize):
		var innerArray: Array[Vector2] = []
		for coordinateX in range(gridSize):
			innerArray.append(Vector2(coordinateX - floori(coordinateY/2), coordinateY))
		gridArray.append(innerArray)
	
## This is for creating rectangular map flat
	#for coordinateY in range(gridSize):
		#var innerArray: Array[Vector2] = []
		#for coordinateX in range(gridSize):
			#innerArray.append(Vector2(coordinateY, coordinateX - floori(coordinateY/2)))
		#gridArray.append(innerArray)
		#
	#
	
# This is for creating hexagonal map 
	#for coordinateY in range(gridSize):
		#var innerArray: Array[Vector2] = []
		#for coordinateX in range((2 * gridRadius + 1) - abs(gridRadius - coordinateY)):
			#innerArray.append(Vector2(coordinateX + max(0, (gridRadius - coordinateY)), coordinateY))
		#gridArray.append(innerArray)
#
	#print("Array: ",gridArray)
	
	for row in gridArray:
		for hex in row:
			var newTile = tileNode.new(hex, hexSize, false)
			tileArray.append(newTile)
			add_child(newTile)
	#for row in gridArray:
		#for column in gridArray:
			#add_child(tileNode.new(gridArray[row][column]))
	
	
	pass # Replace with function body.

func _process(delta):
	var mouseHex := pixel_to_pointy_hex(get_global_mouse_position())
	
	
	
	for hex in tileArray:
		if hex.axialPosition == Vector2(mouseHex.x, mouseHex.y):
			if focusedTile.is_empty() or hex not in focusedTile:
				if not focusedTile.is_empty():
					focusedTile[0].change_color()
				focusedTile.pop_front()
				focusedTile.append(hex)
				hex.change_color()
	
	


func get_tile(tileRow: int, tileColumn: int):
	for row in gridArray:
		for column in gridArray[row]:
			if (tileRow == row && tileColumn == column):
				return gridArray[row][column]
	return null

func pixel_to_pointy_hex(mousePosition: Vector2) -> Vector3:
	var x = (sqrt(3)/3.0 * mousePosition.x - 1.0/3.0 * mousePosition.y) / hexSize
	var y = (2.0/3.0 * mousePosition.y) / hexSize
	return cube_round(Vector3(x, y, -x-y))

func cube_round(fraction: Vector3):
	var roundX = roundi(fraction.x)
	var roundY = roundi(fraction.y)
	var roundZ = roundi(fraction.z)
	
	var xDiff = abs(roundX - fraction.x)
	var yDiff = abs(roundY - fraction.y)
	var zDiff = abs(roundZ - fraction.z)
	
	if xDiff > yDiff and xDiff > zDiff:
		roundX = -roundY-roundZ
	elif yDiff > zDiff:
		roundY = -roundX-roundZ
	else:
		roundZ = -roundX-roundY
	
	return Vector3(roundX, roundY, roundZ)

	
	
	
	
	
	
	
	




