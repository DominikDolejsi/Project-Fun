extends TileMap

@export var width: int = 10
@export var height: int = 10
@export var plate_generating_repetitions: int = 2
@export var min_edge_neighbors: int = 5
@export_range(1, 10) var distance_between_starting_tiles: int = 3
@export_range(1, 10) var pregrow_turns: int = 3


var map_tiles = {}
var map_tectonics = null

class PlateTectonics:
	var ids: Array
	var plates: Dictionary
	var initial_tile_set: Array
	var available_tiles: Array
	
	func _init(tile_set_tiles: Array):
		self.initial_tile_set = tile_set_tiles.duplicate()
		self.available_tiles = tile_set_tiles.duplicate()
		self.ids = []
		self.plates = {}
	
# This should be redesigned to account for size ? make it Array and popBack() 
	func generate_unique_id() -> int:
		var id = randi_range(1, 300)
		while ids.has(id):
			id = randi_range(1, 300)
		return id
	
	func create_plate():
		var id = generate_unique_id()
		if available_tiles.is_empty():
			push_error("Map tecotnics has no available tiles")
		var tile = available_tiles.pop_back()
		var plate = Plate.new(id, tile)
		ids.append(id)
		plates[id] = plate
		return id
	
	func get_plate(id: int):
		return plates.get(id)
	
	func delete_plate(plate_id: int, map_tiles: Dictionary):
		var plate: Plate = plates.get(plate_id)
		available_tiles.append(plate.tile_type)
		for tile in plate.tiles:
			map_tiles[tile].id = 0
		ids.erase(plate_id)
		plates.erase(plate_id)
	
	func reset():
		self.available_tiles = initial_tile_set.duplicate()
		self.ids = []
		self.plates = {}
	
	func get_biggest_plate_id() -> int:
		var id := 0
		var amount := 0
		for plate_id in plates.keys():
			if plates[plate_id].tiles.size() > amount:
				id = plate_id
				amount = plates[plate_id].tiles.size()
		return id

class MapTile:
	var plate_id: int
	
	func _init(id: int = 0):
		self.plate_id = id

class Plate:
	var id: int
	var tile_type: Vector2i
	var start_tile: Vector2i
	var tiles: Dictionary

	func _init(new_id: int, tile_atlas_coords: Vector2i):
		self.id = new_id
		self.tile_type = tile_atlas_coords
	
	func assign_start_tile(tile: Vector2i):
		self.start_tile = tile
		self.tiles[tile] = true
	
	func reset_growth():
		self.tiles.clear()
		self.tiles[self.start_tile] = true

func iterator():
	for x in range(100):
		simulate_plate_tectonics()
		await get_tree().create_timer(0.7).timeout
		reset_map()


func simulate_plate_tectonics():
	var base_layer_id = 0
	for x in range(plate_generating_repetitions):
		var split_succesfully = split_plate(base_layer_id)
		if not split_succesfully:
			print_rich("[font_size=30]Simulation failed[/font_size]")
			break
		base_layer_id = map_tectonics.get_biggest_plate_id()

func _ready():
	#initialize_map()
	#iterator()
	#simulate_plate_tectonics()
	var main_vec = Vector2(1,2)
	var second_vec = Vector2(1,1)
	print(main_vec)
	print(second_vec)
	print(second_vec.normalized())
	print(main_vec.normalized())
	print(main_vec.dot(second_vec))
	print(main_vec.normalized().dot(second_vec.normalized()))

func split_plate(base_layer_id: int):
	var plate_ids = initialize_plates(base_layer_id)
	var did_grow = grow_plates_by_spliting(plate_ids, base_layer_id)
	visualize_plates()
	return did_grow

func initialize_map_tectonics():
	var tiles := []
	var tiles_source = tile_set.get_source(0)
	if tiles_source.get_tiles_count() == 0:
		push_error("[map init]: no tiles defined")
		return 
	for tile_index in range(tiles_source.get_tiles_count()):
		tiles.append(tiles_source.get_tile_id(tile_index))
	map_tectonics = PlateTectonics.new(tiles)

func initialize_map():
	for x in range(width):
		for y in range(height):
			map_tiles[Vector2i(x, y)] = MapTile.new()
	initialize_map_tectonics()
	#for tile in map_tiles:
		#paint_tile(tile, Vector2i(0, 0))

func initialize_plates(base_layer_id: int) -> Array[int]:
	var plate_one_id: int = map_tectonics.create_plate()
	var plate_two_id: int = map_tectonics.create_plate()
	
	var base_layer_tiles: Array = []
	for tile in map_tiles.keys():
		if map_tiles[tile].plate_id == base_layer_id: base_layer_tiles.append(tile)
	
	initialize_starting_tiles([plate_one_id, plate_two_id], base_layer_tiles)
	return [plate_one_id, plate_two_id]

func initialize_starting_tiles(plate_ids: Array, tiles: Array):
	for attempt in range(51):
		var first_tile: Vector2i = tiles.pick_random()
		var second_tile: Vector2i = tiles.pick_random()
		if not tiles_in_range(distance_between_starting_tiles, first_tile, second_tile):
			var first_plate = map_tectonics.get_plate(plate_ids[0])
			var second_plate = map_tectonics.get_plate(plate_ids[1])
			first_plate.assign_start_tile(first_tile)
			second_plate.assign_start_tile(second_tile)
			assign_tiles_to_plate([first_tile], first_plate)
			assign_tiles_to_plate([second_tile], second_plate)
			return
	push_error("Could not find tile that are not in range")

func tiles_in_range(distance: int, first_tile: Vector2i, second_tile: Vector2i):
	if first_tile == second_tile: return true
	var tiles_to_check = [first_tile]
	for step in range(distance):
		var tile_acc = []
		for tile in tiles_to_check:
			for cell in get_surrounding_cells(tile):
				if cell == second_tile: return true
				if tiles_to_check.has(cell): continue
				tile_acc.append(cell)
		tiles_to_check.append_array(tile_acc.duplicate())
	if tiles_to_check.has(second_tile): return true
	return false

func assign_tiles_to_plate(hexes: Array, plate: Plate) -> void:
	for hex in hexes:
		var tile = map_tiles.get(hex)
		if tile == null: continue
		if tile.plate_id != 0:
			var original_plate = map_tectonics.get_plate(tile.plate_id)
			if original_plate: original_plate.tiles.erase(hex)
		plate.tiles[hex] = true
		map_tiles[hex].plate_id = plate.id

func grow_plates_by_spliting(plate_ids: Array, base_layer_id: int):
	for attempt in range(50):
		var grown_ok = true
		var plates: Array = []
		for id in plate_ids:
			plates.append(map_tectonics.get_plate(id))
	
		for amount in range(pregrow_turns):
			for plate in plates:
				var did_grow = grow_plate_flood(plate, base_layer_id)
				if not did_grow: 
					grown_ok = false
					#print_rich("[font_size=large]Could not grow[/font_size]")
				
		var growth_line = plates.duplicate()
		while !growth_line.is_empty():
			var plate = growth_line.pick_random()
			growth_line.erase(plate)
			var did_grow = grow_plate_flood(plate, base_layer_id)
			if did_grow: growth_line.append(plate)
		
		var is_either_plate_engulfed = (
			is_plate_engulfed(plates[0], plates[1].id) or 
			is_plate_engulfed(plates[1], plates[0].id))
		if is_either_plate_engulfed:
			grown_ok = false
			#print_rich("[font_size=20][color=#e60026]Was engulfed[/color][/font_size]")
		
		if grown_ok:
			if base_layer_id != 0:
				map_tectonics.delete_plate(base_layer_id, map_tiles)
			erase_one_tile_protrusions()
			return true
		reset_plate_growth(plates, base_layer_id)
	return false

func reset_plate_growth(plates: Array, base_layer_id: int):
	for plate in plates:
		for tile in plate.tiles:
			if tile != plate.start_tile:
				map_tiles[tile].plate_id = base_layer_id
		plate.reset_growth()

func grow_plate_flood(plate: Plate, base_id: int):
	var tiles = get_tiles_for_growth(plate, base_id)
	if tiles.is_empty(): return false
	assign_tiles_to_plate(tiles, plate)
	return true

func get_tiles_for_growth(plate: Plate, base_id: int) -> Array[Vector2i]:
	var eligible_tiles: Array[Vector2i] = []
	for hex in plate.tiles.keys():
		for cell in get_surrounding_cells(hex):
			if is_eligible_for_growth(cell, base_id) and not eligible_tiles.has(cell):
				eligible_tiles.append(cell)
	return eligible_tiles

func is_eligible_for_growth(hex: Vector2i, base_id: int) -> bool:
	if !map_tiles.has(hex): return false
	if map_tiles[hex].plate_id == base_id: return true
	return false

func paint_tile(hex: Vector2i, tile_type: Vector2i):
	set_cell(0, hex, 0, tile_type)

func is_plate_engulfed(plate: Plate, second_plate_id: int):
	var neighbours = get_plate_neighbours(plate)
	if neighbours.size() < 2: return true
	neighbours.erase(second_plate_id)
	var total_edge_size = 0
	for neighbouring_edge_size in neighbours.values():
		total_edge_size += neighbouring_edge_size.size()
	if total_edge_size < min_edge_neighbors: 
		return true
	return false

func get_plate_neighbours(plate: Plate):
	var neighbours = {}
	for tile in plate.tiles.keys():
		for cell in get_surrounding_cells(tile):
			var neighbour_id = -1
			if map_tiles.has(cell): 
				if map_tiles[cell].plate_id == plate.id:
					continue
				neighbour_id = map_tiles[cell].plate_id
			if neighbours.has(neighbour_id):
				if !neighbours[neighbour_id].has(cell):
					neighbours[neighbour_id].append(cell)
			else:
				neighbours[neighbour_id] = [cell]
	return neighbours

func erase_one_tile_protrusions():
	for plate in map_tectonics.plates.values():
		var single_neighbour_tiles = []
		for tile in plate.tiles.keys():
			var own_hex_neighbours = []
			for cell in get_surrounding_cells(tile):
				if !map_tiles.has(cell): continue
				if map_tiles[cell].plate_id == plate.id: own_hex_neighbours.append(cell)
			if own_hex_neighbours.size() == 1:
				single_neighbour_tiles.append(tile)
		for tile in single_neighbour_tiles:
			remove_protrusion(tile, plate.id)

func remove_protrusion(tile: Vector2i, plate_id: int, hexes_to_remove: Array = [], other_neighbours: Dictionary = {}):
	var neighbours = get_hex_plate_neighbours(tile)
	if neighbours.is_empty(): return
	for remove_hex in hexes_to_remove:
		neighbours.erase(remove_hex)
	var own_plate_neighbours = neighbours.values().filter(func(value): return value == plate_id)
	var other_plate_neighbours = neighbours.values().filter(func(value): return value != plate_id)
	for neighbour in other_plate_neighbours:
			if neighbour in other_neighbours.keys():
				other_neighbours[neighbour] += 1
			else:
				other_neighbours[neighbour] = 1
	if own_plate_neighbours.size() > 1:
		var most_used_neighbour = other_neighbours.keys()
		most_used_neighbour.sort_custom(func(a, b): return other_neighbours[a] > other_neighbours[b])
		var plate_to_assign = map_tectonics.get_plate(most_used_neighbour[0])
		assign_tiles_to_plate(hexes_to_remove, plate_to_assign)
		return
	else:
		var next_hex = neighbours.keys().filter(func(value): return neighbours[value] == plate_id)[0]
		hexes_to_remove.append(tile)
		remove_protrusion(next_hex, plate_id, hexes_to_remove, other_neighbours)

func get_hex_plate_neighbours(tile: Vector2i):
	var tile_neighbours = {}
	for cell in get_surrounding_cells(tile):
		if !map_tiles.has(cell): continue
		tile_neighbours[cell] = map_tiles[cell].plate_id
	return tile_neighbours
# old code ------------------------------------------------------------------------------
func get_plates_edge_hexagons(plate: Plate) -> Array[Vector2i]:
	var edge_hexagons: Array[Vector2i] = []
	for tile in plate.tiles.keys():
		if is_edge_hex(tile, plate.id):
			edge_hexagons.append(tile)
	return edge_hexagons

#edge hexagon is bordering atleast 1 another plate
func is_edge_hex(tile: Vector2i, plate_id: int) -> bool:
	if !map_tiles.has(tile): return false
	for cell in get_surrounding_cells(tile):
		if !map_tiles.has(cell): continue
		if plate_id != map_tiles[cell].plate_id:
			return true
	return false

func visualize_plates():
	for plate in map_tectonics.plates.values():
		for hex in plate.tiles.keys():
			set_cell(0, hex, 0, plate.tile_type, 0)

func visualize_plate_edges():
	clear()
	for plate in map_tectonics.plates.values():
		for tile in get_plates_edge_hexagons(plate):
			set_cell(0, tile, 0, plate.tile_type, 0)

func _unhandled_input(event):
	if event.is_action_pressed("leftMouse"):
		handle_left_mouse_click(event)
	elif event.is_action_pressed("space_bar"):
		pass
	elif event.is_action_pressed("R"):
		reset_map()
		simulate_plate_tectonics()
	elif event.is_action_pressed("C"):
		erase_one_tile_protrusions()
		visualize_plates()
	elif event.is_action_pressed("H"):
		print_plate_tectonics()
		visualize_plates()
	elif event.is_action_pressed("P"):
		visualize_plate_edges()

func print_plate_tectonics():
	print_rich("[b]Plate tectonics[/b] ",
	map_tectonics.ids,
	)
	for plate in map_tectonics.plates.values():
		print_rich(plate.id, " id ", plate.start_tile, " start tile ", plate.tiles.size(), " tiles amount ")

func handle_left_mouse_click(_event):
	var coordinates = local_to_map(get_global_mouse_position())
	print("Clicked on ", coordinates)
	if map_tiles.has(coordinates):
		var tile = map_tiles[coordinates]
		if tile != null:
			var plate = map_tectonics.get_plate(tile.plate_id)
			if (plate != null):
				print_plate_info(plate)

func print_plate_info(plate: Plate):
	print("Plate info: id: ", plate.id,
		", starting_tile: ", plate.start_tile,
		", number of hexagons ", plate.tiles.size(),
	)

# Generation fine tuning - removing one tile plates, maybe even up to 4 tiles ??
# So the tile on the edge has 1 - 4 neighbours/sides active
# There are 3 types of boundaries -
# 1. Divergent - ocean to ocean - sligtly rises the tile it occurs on, small volcanism and earthquakes
# continent to continent - starting rift valleys, slightly lowers the tile it is on, can lsightly higher the tiles around and causes earthquakes

func reset_map():
	for tile in map_tiles.keys():
		map_tiles[tile].plate_id = 0
	map_tectonics.reset()
	clear()
