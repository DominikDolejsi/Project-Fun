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
	grow_plates()

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

#here is new comment

func assign_tile_to_plate(hexes: Array[Vector2i], plate: Plate):
	for hex in hexes:
		var tile = map_tiles[hex]
		if (tile != null):
			var original_plate = find_plate_by_id(tile.plate_id)
			original_plate.hexagons.erase(hex)
		plate.hexagons[hex] = true
		map_tiles[hex] = Tile.new(plate.id)

func find_plate_by_id(id: int):
	for plate in plates:
		if plate.id == id: return plate
	return null

func grow_plates():
	var active_plates = create_active_plates_queue()
	
	while active_plates:
		var plate = active_plates.pop_front()
		if grow_plate(plate):
			active_plates.push_back(plate)
		visualize_plates()
	
	await get_tree().create_timer(1.0).timeout
	print("Consolidating")
	consolidate_plates()
	visualize_plates()
	generate_smaller_plates()
	visualize_plates()

func generate_smaller_plates():
	for i in range(num_smaller_plates):
		var main_plate = plates[randi() % plates.size()]
		var edge_hexes = get_plate_edge_hexes(main_plate)
		if edge_hexes.is_empty():
			continue
		
		var start = edge_hexes[randi() % edge_hexes.size()]
		var growth_speed = clamp(randi() % 5, 1, 5)
		var speed = randf()
		var direction = Vector2(randf() * 2 - 1, randf() * 2 - 1).normalized()
		var steps = randi() % (max_small_plate_steps - min_small_plate_steps + 1) + min_small_plate_steps
		
		var smaller_plate = Plate.new(i + num_plates, Vector2i(i, 1), start, growth_speed, speed, direction, true, steps)
		change_hex_owner(start, main_plate, smaller_plate)
		smaller_plates.append(smaller_plate)
		
		grow_smaller_plate(smaller_plate)

func change_hex_owner(hex: Vector2i, old_owner: Plate, new_owner: Plate):
	if old_owner:
		old_owner.locked_hexagons.erase(hex)
		old_owner.free_hexagons.erase(hex)
	new_owner.locked_hexagons[hex] = true
	hex_tiles[hex] = Tile.new(new_owner.id, new_owner.tile)

func grow_smaller_plate(plate: Plate):
	while plate.remaining_steps > 0:
		if not grow_plate_step(plate, true):
			break
		plate.remaining_steps -= 1
	visualize_plates()

func grow_plate_step(plate: Plate, is_smaller: bool = false) -> bool:
	var free_hexagons = plate.free_hexagons.keys()
	if free_hexagons.is_empty():
		return false
	
	var random_hex = free_hexagons[randi() % free_hexagons.size()]
	var neighbors = get_available_neighbors(random_hex, is_smaller)
	
	if neighbors.is_empty():
		plate.free_hexagons.erase(random_hex)
		plate.locked_hexagons[random_hex] = true
		return plate.free_hexagons.size() > 0
	
	for neighbor in neighbors:
		var old_owner = get_hex_owner(neighbor)
		change_hex_owner(neighbor, old_owner, plate)
		plate.free_hexagons[neighbor] = true
	return true

func get_hex_owner(hex: Vector2i) -> Plate:
	var tile = hex_tiles[hex]
	if tile != null:
		if tile.plate_tile_type.y > 0:
			return smaller_plates[tile.plate_id - num_plates]
		else:
			return plates[tile.plate_id]
	return null

func create_active_plates_queue():
	var queue = []
	for plate in plates:
		for _i in range(plate.growth_speed):
			queue.append(plate)
	return queue

func grow_plate(plate: Plate) -> bool:
	var free_hexagons = plate.free_hexagons.keys()
	var attempts = free_hexagons.size()
	
	while attempts > 0:
		var random_hex = free_hexagons[randi() % free_hexagons.size()]
		var neighbors = get_available_neighbors(random_hex)
		
		if not neighbors.is_empty():
			for neighbor in neighbors:
				plate.free_hexagons[neighbor] = true
				hex_tiles[neighbor] = Tile.new(plate.id, plate.tile)
			return true
		
		plate.free_hexagons.erase(random_hex)
		plate.locked_hexagons[random_hex] = true
		attempts = plate.free_hexagons.size()
	
	return false

func get_available_neighbors(hex: Vector2i, is_smaller: bool = false) -> Array:
	return get_surrounding_cells(hex).filter(func(neighbor): 
		if not hex_tiles.has(neighbor):
			return false
		if is_smaller:
			return hex_tiles[neighbor] == null or (hex_tiles[neighbor] != null and hex_tiles[neighbor].plate_tile_type.y == 0)
		return hex_tiles[neighbor] == null
	)

func consolidate_plates():
	var plates_to_remove = []
	for plate in plates:
		if should_consolidate_plate(plate):
			merge_plate(plate)
			plates_to_remove.append(plate)
	for plate in plates_to_remove:
		plates.erase(plate)

func should_consolidate_plate(plate: Plate) -> bool:
	var neighbours = {}
	var edge_count = 0
	
	for hex in plate.locked_hexagons:
		for cell in get_surrounding_cells(hex):
			if hex_tiles.has(cell):
				var neighbour_tile = hex_tiles[cell]
				if neighbour_tile != null and neighbour_tile.plate_id != plate.id:
					if not neighbours.has(neighbour_tile.plate_id):
						neighbours[neighbour_tile.plate_id] = 0
					neighbours[neighbour_tile.plate_id] += 1
			else:
				edge_count += 1
	
	# Case 1: Fully enclosed inside only 1 plate
	if neighbours.size() == 1 and edge_count == 0:
		return true
	
	# Case 2: Neighbours only 1 plate and touches less than min_edge_neighbors edge hexes
	if neighbours.size() == 1 and edge_count < min_edge_neighbors:
		return true
	
	return false

func merge_plate(plate: Plate):
	var neighbour_index = get_main_neighbour_index(plate)
	if neighbour_index != -1:
		for hex in plate.locked_hexagons:
			hex_tiles[hex] = Tile.new(neighbour_index, plates[neighbour_index].tile)
		plates[neighbour_index].locked_hexagons.merge(plate.locked_hexagons)
		print("Merged plate with start ", plate.start, " into plate ", neighbour_index)

func get_main_neighbour_index(plate: Plate) -> int:
	var neighbours = {}
	
	for hex in plate.locked_hexagons:
		for cell in get_surrounding_cells(hex):
			if hex_tiles.has(cell):
				var neighbour_tile = hex_tiles[cell]
				if neighbour_tile != null and neighbour_tile.plate_id != plate.id:
					if not neighbours.has(neighbour_tile.plate_id):
						neighbours[neighbour_tile.plate_id] = 0
					neighbours[neighbour_tile.plate_id] += 1
	
	if neighbours.is_empty():
		return -1
	
	# Return the index of the plate with the most shared edges
	return neighbours.keys().max()

func get_plate_edge_hexes(plate: Plate) -> Array:
	var edge_hexes = []
	for hex in plate.locked_hexagons:
		for neighbor in get_surrounding_cells(hex):
			if not plate.locked_hexagons.has(neighbor) and hex_tiles.has(neighbor):
				edge_hexes.append(hex)
				break
	return edge_hexes

func visualize_plates():
	for hex in hex_tiles.keys():
		var tile = hex_tiles[hex]
		if tile != null:
			set_cell(0, hex, 0, tile.plate_tile_type, 0)

func _unhandled_input(event):
	if event.is_action_pressed("leftMouse"):
		handle_left_mouse_click(event)
	elif event.is_action_pressed("space_bar"):
		generate_tectonic_plates()
	elif event.is_action_pressed("R"):
		reset_map()

func handle_left_mouse_click(event):
	var coordinates = local_to_map(get_global_mouse_position())
	print("Clicked on ", coordinates)
	if hex_tiles.has(coordinates):
		var tile = hex_tiles[coordinates]
		if tile != null:
			var plate = get_hex_owner(coordinates)
			print_plate_info(plate)

func print_plate_info(plate: Plate):
	print("Plate info: start hex: ", plate.start,
		", growth_speed: ", plate.growth_speed,
		", speed: ", plate.speed,
		", direction: ", plate.direction,
		", locked hexes: ", plate.locked_hexagons.size(),
		", free hexes: ", plate.free_hexagons.size(),
		", is smaller plate: ", plate.is_smaller_plate,
		", remaining steps: ", plate.remaining_steps,
		", plate index: ", smaller_plates.find(plate) if plate.is_smaller_plate else plates.find(plate)
	)

func reset_map():
	hex_tiles.clear()
	plates.clear()
	smaller_plates.clear()
	clear()
