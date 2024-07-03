extends TileMap

@export var width: int = 10
@export var height: int = 10
@export var tectonic_plates_amount: int = 5
@export var min_edge_neighbors: int = 5

var map_tiles = {}
var plates = []

class Tile:
	var plate_id: int
	
	func _init(plate_id: int):
		self.plate_id = plate_id

class Plate:
	var id: int
	var tile_type: Vector2i
	var starting_tile: Vector2i
	var growth_speed: int
	var hexagons: Dictionary
	var free_hexagons: Dictionary
	var locked_hexagons: Dictionary

	func _init(id: int, tile_type: Vector2i, starting_tile: Vector2i, growth_speed: int):
		self.id = id
		self.tile_type = tile_type
		self.starting_tile = starting_tile
		self.growth_speed = growth_speed
		self.hexagons = {starting_tile: true}
		self.free_hexagons = {starting_tile: true}
		self.locked_hexagons = {}

func _ready():
	pass

func generate_tectonic_plates():
	initialize_map()
	create_initial_plates()
	build_plates_by_flood_2()
	visualize_plates()

func initialize_map():
	for x in range(width):
		for y in range(height):
			map_tiles[Vector2i(x, y)] = null

func create_initial_plates():
	for i in range(tectonic_plates_amount):
		var start = Vector2i(randi() % width, randi() % height)
		var tile_type = Vector2i(i, 0)
		var growth_speed = 1
		var plate = Plate.new(i, tile_type, start, growth_speed)
		plates.append(plate)
		map_tiles[start] = Tile.new(plate.id)

func assign_tiles_to_plate(hexes: Array[Vector2i], plate: Plate) -> void:
	for hex in hexes:
		var tile = map_tiles[hex]
		if (tile != null):
			var original_plate = get_plate_by_id(tile.plate_id)
			if original_plate: original_plate.hexagons.erase(hex)
		plate.hexagons[hex] = true
		map_tiles[hex] = Tile.new(plate.id)

func grow_plate_by_flood(plate: Plate):
	var boardering_hexagons = get_plate_boardering_hexagons(plate)
	if boardering_hexagons.is_empty(): return false
	assign_tiles_to_plate(boardering_hexagons, plate)
	return true

func build_plates_by_flood():
	var growth_line = plates.duplicate()
	while !growth_line.is_empty():
		var plate = growth_line.pop_front()
		if (plate == null): break
		var did_grow = grow_plate_by_flood(plate)
		visualize_plates()
		if (did_grow): growth_line.append(plate)
		await get_tree().create_timer(0.001).timeout

func build_plates_by_flood_2():
	var growth_line = plates.duplicate()
	
	while !growth_line.is_empty():
		var plate = growth_line.pick_random()
		growth_line.erase(plate)
		if (plate == null): break
		var did_grow = grow_plate_by_flood(plate)
		visualize_plates()
		if (did_grow): growth_line.append(plate)
		await get_tree().create_timer(0.001).timeout

#func consolidate_inner_plates():
	#for plate in plates:
		#
#
#
#func is_inner_plate(plate: Plate):
	#for hex in get_plates_edge_hexagons(plate):
		#var neigbours = []
		#
		#

#func get_cell_neigbours(hex: Vector2i, original_plate_id: int):
	#neighbours
	#for cell in get_surrounding_cells(hex):
		#if not map_tiles.has(cell) or map_tiles[cell] == null: continue
		#if original_plate_id != map_tiles[cell].plate_id: 
		#

func get_plate_boardering_hexagons(plate: Plate) -> Array[Vector2i]:
	var boardering_hexagons: Array[Vector2i] = []
	for hex in plate.hexagons.keys():
		for cell in get_surrounding_cells(hex):
			if is_boardering_hex(cell) and not boardering_hexagons.has(cell):
				boardering_hexagons.append(cell)
	return boardering_hexagons

func is_boardering_hex(hex: Vector2i) -> bool:
	if !map_tiles.has(hex): return false
	if map_tiles[hex] == null: return true
	return false


func get_plates_edge_hexagons(plate: Plate) -> Array[Vector2i]:
	var edge_hexagons: Array[Vector2i] = []
	for hex in plate.hexagons.keys():
		if is_edge_hex(hex):
			edge_hexagons.append(hex)
	return edge_hexagons

#edge hexagon is bordering atleast 1 another plate
func is_edge_hex(hex: Vector2i) -> bool:
	if !map_tiles.has(hex) or map_tiles.get(hex) == null: return false
	var plate_id = map_tiles.get(hex).plate_id
	for cell in get_surrounding_cells(hex):
		if !map_tiles.has(cell): continue
		if map_tiles[cell] == null: continue
		if plate_id != map_tiles[cell].plate_id:
			return true
	return false

func get_plate_by_id(id: int):
	for plate in plates:
		if plate.id == id: return plate
	return null

func visualize_plates():
	for plate in plates:
		for hex in plate.hexagons.keys():
			set_cell(0, hex, 0, plate.tile_type, 0)

func visualize_plate_edges():
	clear()
	for plate in plates:
		for hex in get_plates_edge_hexagons(plate):
			set_cell(0, hex, 0, plate.tile_type, 0)


func _unhandled_input(event):
	if event.is_action_pressed("leftMouse"):
		handle_left_mouse_click(event)
	elif event.is_action_pressed("space_bar"):
		generate_tectonic_plates()
	elif event.is_action_pressed("R"):
		reset_map()
	elif event.is_action_pressed("H"):
		visualize_plate_edges()

func handle_left_mouse_click(event):
	var coordinates = local_to_map(get_global_mouse_position())
	print("Clicked on ", coordinates)
	if map_tiles.has(coordinates):
		var tile = map_tiles[coordinates]
		if tile != null:
			var plate = get_plate_by_id(tile.plate_id)
			if (plate != null): print_plate_info(plate)

func print_plate_info(plate: Plate):
	print("Plate info: id: ", plate.id,
		", starting_tile: ", plate.starting_tile,
		", growth_speed: ", plate.growth_speed,
		", number of hexagons ", plate.hexagons.size(),
	)

func reset_map():
	map_tiles.clear()
	plates.clear()
	clear()
