class_name UtilsStatic extends Node


func create_message_label(text: String) -> RichTextLabel:
	var label: RichTextLabel = RichTextLabel.new()
	label.append_text(text)
	label.fit_content = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_theme_type_variation("RichTextLabelLarge")

	return label


func get_wisdom_upgrade_count_for_player_level(player_level: int) -> int:
	var upgrade_id_list: Array = WisdomUpgradeProperties.get_id_list()
	var upgrade_count_max: int = upgrade_id_list.size()
	var upgrade_count: int = min(upgrade_count_max, floori(player_level * Constants.PLAYER_LEVEL_TO_WISDOM_UPGRADE_COUNT))

	return upgrade_count


func get_local_player_level() -> int:
	var exp_password: String = Settings.get_setting(Settings.EXP_PASSWORD)
	var player_exp: int = ExperiencePassword.decode(exp_password)
	var player_exp_is_valid: bool = player_exp != -1
	
	if !player_exp_is_valid:
		push_warning("Experience password is invalid, resetting level to 0.")
		
		return 0
	
	var player_lvl: int = PlayerExperience.get_level_at_exp(player_exp)
	
	return player_lvl


# Example: 93 -> "01:33"
func convert_time_to_string(time_total_seconds: float):
	var time_hours: int = floori(time_total_seconds / 3600)
	var time_minutes: int = floori((time_total_seconds - time_hours * 3600) / 60)
	var time_seconds: int = floori(time_total_seconds - time_hours * 3600 - time_minutes * 60)
	var time_string: String
	if time_hours > 0:
		time_string = "%02d:%02d:%02d" % [time_hours, time_minutes, time_seconds]
	else:
		time_string = "%02d:%02d" % [time_minutes, time_seconds]
	
	return time_string


# NOTE: you must use this instead of
# get_tree().create_timer() because timers created using
# get_tree().create_timer() do not handle game pause and
# game restart.
# 
# NOTE: you must not use this for things which are not part
# of the synchronized multiplayer client. If you
# create_timer() for one player but not the others, you will
# mess up the order of updating timers and cause desync.
func create_timer(duration: float, parent: Node) -> ManualTimer:
	var timer: ManualTimer = ManualTimer.new()

	var parent_is_active: bool = parent.is_inside_tree() && !parent.is_queued_for_deletion()
	if parent_is_active:
		add_child(timer)
		timer.one_shot = true
		timer.timeout.connect(timer.queue_free)
		timer.start(duration)
	else:
		timer.queue_free()

	return timer


func tower_exists_on_position(position: Vector2) -> bool:
	var tower_at_position: Tower = get_tower_at_position(position)
	var has_tower: bool = tower_at_position != null

	return has_tower


func get_tower_at_position(position_wc3: Vector2) -> Tower:
	var tower_node_list: Array = get_tree().get_nodes_in_group("towers")

	for tower_node in tower_node_list:
		var tower: Tower = tower_node as Tower
		var this_position: Vector2 = tower.get_position_wc3_2d()
		var position_match: bool = position_wc3.is_equal_approx(this_position)

		if position_match:
			return tower

	return null


# NOTE: Game.getGameTime() in JASS 
func get_time() -> float:
	var game_time: Node = get_tree().get_root().get_node_or_null("GameScene/Gameplay/GameTime")

	if game_time == null:
		push_warning("game_time is null. You can ignore this warning during game restart.")

		return 0.0
	
	var time: float = game_time.get_time()

	return time


# Returns current time of day in the game world, in hours.
# Between 0.0 and 24.0.
# NOTE: GetFloatGameState(GAME_STATE_TIME_OF_DAY) in JASS
func get_time_of_day() -> float:
	var irl_seconds: float = get_time()
	var game_world_hours: float = Constants.INITIAL_TIME_OF_DAY + irl_seconds * Constants.IRL_SECONDS_TO_GAME_WORLD_HOURS
	var time_of_day: float = fmod(game_world_hours, 24.0)

	return time_of_day


func filter_item_list(item_list: Array[Item], rarity_filter: Array = [], type_filter: Array = []) -> Array[Item]:
	var filtered_list: Array = item_list.filter(
		func(item: Item) -> bool:
			var rarity_ok: bool = rarity_filter.has(item.get_rarity()) || rarity_filter.is_empty()
			var type_ok: bool = type_filter.has(item.get_item_type()) || type_filter.is_empty()

			return rarity_ok && type_ok
	)

	return filtered_list


func add_object_to_world(object: Node):
	var object_container: Node = get_tree().get_root().get_node_or_null("GameScene/World/ObjectContainer")
	
	if object_container == null:
		push_warning("object_container is null. You can ignore this warning during game restart.")
		
		return

	object_container.add_child(object, true)


# NOTE: currently, we assure that text fits inside the
# richtextlabel tooltip by setting the minimum size. If all
# lines in the text are shorter than the minimum size, there
# will be extra empty space to the right of the text. It
# looks bad. Would like the tooltip width to automatically
# shrink in such cases so that tooltip size fits text size
# without any empty space. Couldn't figure out how to do
# that. There also seems to be a bug with RichTextLabel,
# fit_content and embedding a RichTextLabel in tooltip which
# stands in the way of implementing such behavior.
func make_rich_text_tooltip(for_text: String) -> RichTextLabel:
	var label: RichTextLabel = RichTextLabel.new()
	label.custom_minimum_size = Vector2(500, 50)
	label.fit_content  = true
	label.append_text(for_text)

	return label


func find_creep_path(player: Player, for_air_creeps: bool) -> Path2D:
	var wave_path_list: Array = get_tree().get_nodes_in_group("wave_paths")

	for path in wave_path_list:
		var player_match: bool = path.player_id == player.get_id()
		var type_match: bool = (path.is_air && for_air_creeps) || (!path.is_air && !for_air_creeps)

		if player_match && type_match:
			return path

	return null


func is_point_on_creep_path(point_wc3: Vector2, player: Player) -> bool:
	var point_wc3_3d: Vector3 = Vector3(point_wc3.x, point_wc3.y, 0)
	var point: Vector2 = VectorUtils.wc3_to_canvas(point_wc3_3d)
	var creep_path_ground: Path2D = Utils.find_creep_path(player, false)

	if creep_path_ground == null:
		push_error("Failed to find creep path.")

		return false

	var curve: Curve2D = creep_path_ground.curve

	var min_distance: float = 10000.0
	var prev: Vector2 = curve.get_point_position(0)

	for i in range(1, curve.point_count):
		var curr: Vector2 = curve.get_point_position(i)

		var closest_point: Vector2 = Geometry2D.get_closest_point_to_segment(point, prev, curr)
		var distance: float = closest_point.distance_to(point)

		min_distance = min(min_distance, distance)

		prev = curr

	return min_distance < 100


# Returns a list of lines, each line is a list of strings.
# It's assumed that the first row is title row and it is
# skipped.
static func load_csv(path: String) -> Array[PackedStringArray]:
	var file_exists: bool = FileAccess.file_exists(path)

	if !file_exists:
		print_debug("Failed to load CSV because file doesn't exist. Path: %s", path)

		return []

	var list: Array[PackedStringArray] = []

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)

	var skip_title_row: bool = true
	while !file.eof_reached():
		var csv_line: PackedStringArray = file.get_csv_line()

		if skip_title_row:
			skip_title_row = false
			continue

		var is_last_line: bool = csv_line.size() == 0 || (csv_line.size() == 1 && csv_line[0].is_empty())
		if is_last_line:
			continue

		list.append(csv_line)

	file.close()

	return list


# Loads properties from a csv file.
# Transforms rows of "id1, prop1, prop2..."
# Into a list of maps of [id1: {prop1: "prop1 value", prop2: "prop2 value"...
static func load_csv_properties(properties_path: String, properties_dict: Dictionary, id_column: int):
	var csv: Array[PackedStringArray] = UtilsStatic.load_csv(properties_path)

	for csv_line in csv:
		var properties: Dictionary = UtilsStatic.load_csv_line(csv_line)
		var id: int = properties[id_column].to_int()
		properties_dict[id] = properties


static func load_csv_line(csv_line) -> Dictionary:
	var out: Dictionary = {}

	for property in range(csv_line.size()):
		var csv_string: String = csv_line[property]
		out[property] = csv_string

	return out


func get_sprite_dimensions(sprite: Sprite2D) -> Vector2:
	var texture: Texture2D = sprite.texture
	var image: Image = texture.get_image()
	var used_rect: Rect2i = image.get_used_rect()
	var sprite_dimensions: Vector2 = Vector2(used_rect.size) * sprite.scale

	return sprite_dimensions


# NOTE: can't use get_used_rect() here because creep atlases
# are compressed.
func get_animated_sprite_dimensions(sprite: AnimatedSprite2D, animation_name: String) -> Vector2:
	var sprite_frames: SpriteFrames = sprite.sprite_frames
	var texture: Texture2D = sprite_frames.get_frame_texture(animation_name, 0)
	var sprite_dimensions: Vector2 = texture.get_size()

	return sprite_dimensions


# NOTE: Game.getMaxLevel() in JASS
func get_max_level() -> int:
	return Globals.get_wave_count()


func get_colored_string(string: String, color: Color) -> String:
	var out: String = "[color=%s]%s[/color]" % [color.to_html(), string]

	return out


# Divides two floats. In case of division by 0, returns
# "result_when_divide_by_zero" arg, 0 by default.
# NOTE: this function must be used instead of "/" whenever
# there's division by variable which has any chance of
# being 0.
func divide_safe(a: float, b: float, result_when_divide_by_zero: float = 0.0) -> float:
	if b != 0.0:
		var ratio: float = a / b

		return ratio
	else:
		return result_when_divide_by_zero


func pick_random(rng: RandomNumberGenerator, array: Array) -> Variant:
	if array.is_empty():
		return null
		
	var random_element: Variant = array[rng.randi() % array.size()]
	
	return random_element


func shuffle(rng: RandomNumberGenerator, array: Array):
	for i in array.size():
		var random_index: int = rng.randi_range(0, array.size() - 1)

		if random_index == i:
			continue
		else:
			var temp = array[random_index]
			array[random_index] = array[i]
			array[i] = temp


# Accepts a map of elements to weights and returns a random
# element. For example:
# { "a": 10, "b": 20, "c": 70 }
# will result in 10% a, 20% b, 70% c.
# Note that weights don't have to add up to 100!
# { "a": 1, "b": 2}
# Will result in 1/3 a, 2/3 b.
func random_weighted_pick(rng: RandomNumberGenerator, element_to_weight_map: Dictionary) -> Variant:
	if element_to_weight_map.is_empty():
		push_error("Argument is empty")

		return null

	var pair_list: Array = []

	for element in element_to_weight_map.keys():
		var weight: float = element_to_weight_map[element]
		var pair: Array = [element, weight]

		pair_list.append(pair)

	var weight_total: float = 0

	for pair in pair_list:
		var weight: float = pair[1]
		weight_total += weight

	for i in range(1, pair_list.size()):
		pair_list[i][1] += pair_list[i - 1][1]

	var k: float = rng.randf_range(0, weight_total)

	for pair in pair_list:
		var element: Variant = pair[0]
		var weight: float = pair[1]

		if k <= weight:
			return element

	push_error("Failed to generate random element")

	return element_to_weight_map.keys()[0]


# Use this in cases where script stores references to units
# over a long time. Units may become invalid if they are
# killed or sold or upgraded. Note that calling any methods,
# including is_queued_for_deletion(), on an invalid unit
# will result in an error. Didn't define type for argument
# on purpose because argument can be an invalid instance
# without type.
func unit_is_valid(unit) -> bool:
	var is_valid: bool = is_instance_valid(unit) && unit.is_inside_tree() && !unit.is_queued_for_deletion()

	return is_valid


# Chance should be in range [0.0, 1.0]
# To get chance for event with 10% occurence, call rand_chance(0.1)
func rand_chance(rng: RandomNumberGenerator, chance: float) -> bool:
	var clamped_chance: float = clampf(chance, 0.0, 1.0)
	var random_float: float = rng.randf()
	var chance_success = random_float <= clamped_chance

	return chance_success


func get_units_in_range(type: TargetType, center: Vector2, radius: float, include_invisible: bool = false) -> Array[Unit]:
	var radius_PIXELS: float = to_pixels(radius)

	return get_units_in_range_PIXELS(type, center, radius_PIXELS, include_invisible)


func get_units_in_range_PIXELS(type: TargetType, center: Vector2, radius: float, include_invisible: bool = false) -> Array[Unit]:
	if type == null:
		return []

	var group_name: String
	match type.get_unit_type():
		TargetType.UnitType.TOWERS: group_name = "towers"
		TargetType.UnitType.PLAYER_TOWERS: group_name = "towers"
		TargetType.UnitType.CREEPS: group_name = "creeps"
		TargetType.UnitType.CORPSES: group_name = "corpses"

	var node_list: Array[Node] = get_tree().get_nodes_in_group(group_name)

#	NOTE: in original youtd, auras and abilities which
#	affect towers in range are extended by half a tile so
#	that the aura affects a tower if the range reaches the
#	tile of the tower, not the center.
# 
#	If we don't extend the range, then towers like Skink
# 	will affect less towers than in the original.
# 
#	Note that this doesn't apply to creeps - in that case,
#	the default distance to unit position is used.
	var target_is_tower: bool = type.get_unit_type() == TargetType.UnitType.TOWERS
	if target_is_tower:
		radius += Constants.TILE_SIZE_PIXELS / 2

#	NOTE: not using Array.filter() here because it takes
#	more time than for loop
	var filtered_unit_list: Array[Unit] = []
	
	for node in node_list:
		var unit: Unit = node as Unit

		if unit.is_queued_for_deletion():
			continue

		var type_match: bool = type.match(unit)

		if !type_match:
			continue

		var unit_is_in_range = VectorUtils.in_range(center, unit.get_position_wc3_2d(), radius)

		if !unit_is_in_range:
			continue

		if unit is Creep:
			var creep: Creep = unit as Creep

			if creep.is_invisible() && !include_invisible:
				continue

		filtered_unit_list.append(unit)

	return filtered_unit_list


# NOTE: use squared distances to get better perfomance. Also
# don't convert from WC3 to pixel units because it doesn't
# matter for sorting purposes.
class DistanceSorter:
	var origin = Vector2.ZERO

	func sort(a: Unit, b: Unit):
		var a_pos: Vector2 = a.get_position_wc3_2d()
		var distance_a: float = a_pos.distance_squared_to(origin)
		var b_pos: Vector2 = b.get_position_wc3_2d()
		var distance_b: float = b_pos.distance_squared_to(origin)
		var less_than: bool = distance_a < distance_b

		return less_than


func sort_unit_list_by_distance(unit_list: Array, position: Vector2):
	var sorter: DistanceSorter = DistanceSorter.new()
	sorter.origin = position
	unit_list.sort_custom(Callable(sorter,"sort"))


# This sort implements "smart" targeting for towers. It
# ensures that towers will try to finish an older wave
# before switching to a new wave. The sort works like this:
# 
# 1. If one wave is active, then towers will pick nearest
#    targets.
# 
# 2. If multiple waves are active, then towers will pick
#    nearest target in the oldest wave nearby.
class AttackTargetSorter:
	var origin = Vector2.ZERO

	func sort(a: Unit, b: Unit):
		var level_a: float = a.get_spawn_level()
		var level_b: float = b.get_spawn_level()

		var less_than: bool
		if level_a == level_b:
			var a_pos: Vector2 = a.get_position_wc3_2d()
			var distance_a: float = a_pos.distance_to(origin)
			var b_pos: Vector2 = b.get_position_wc3_2d()
			var distance_b: float = b_pos.distance_to(origin)

			less_than = distance_a < distance_b
		else:
			less_than = level_a < level_b

		return less_than

func sort_creep_list_for_targeting(unit_list: Array, position: Vector2):
	var sorter: AttackTargetSorter = AttackTargetSorter.new()
	sorter.origin = position
	unit_list.sort_custom(sorter.sort)


# Converts CamelCaseSTR_Name to camel_case_str_name
func camel_to_snake(camel_string: String) -> String:
	var snake_string = ""
	var previous_char = ""
	
	for c in camel_string:
		if c.to_upper() == c and previous_char != "" and previous_char.to_upper() != previous_char:
			snake_string += "_"
		snake_string += c.to_lower()
		previous_char = c
	
	return snake_string


func screaming_snake_case_to_camel_case(screaming_snake_case: String) -> String:
	var words = screaming_snake_case.split("_")
	var camel_case = ""
	
	for i in range(words.size()):
		camel_case += words[i].capitalize()
	
	return camel_case


func bit_is_set(mask: int, bit: int) -> bool:
	var is_set: bool = (mask & bit) != 0x0

	return is_set


# formatFloat() in JASS
func format_float(x: float, digits: int) -> String:
	var out: String = String.num(x, digits)

	return out


# formatPercent() in JASS
func format_percent(x: float, digits: int) -> String:
	var x_percent: float = x * 100
	var out: String = "%s%%" % String.num(x_percent, digits)

	return out


# formatPercentAddColor() in JASS
func format_percent_add_color(x: float, digits: int) -> String:
	var uncolored: String = format_percent(x, digits)
	var color: Color
	if x < 0:
		color = Color.RED
	else:
		color = Color.GREEN
	var out: String = get_colored_string(uncolored, color)

	return out


func to_pixels(distance_wc3: float) -> float:
	var distance_pixels: float = distance_wc3 * Constants.WC3_DISTANCE_TO_PIXELS

	return distance_pixels


func from_pixels(distance_pixels: float) -> float:
	var distance: float = distance_pixels / Constants.WC3_DISTANCE_TO_PIXELS

	return distance


func reset_scroll_container(scroll_container: ScrollContainer):
	var h_scroll_bar: HScrollBar = scroll_container.get_h_scroll_bar()
	h_scroll_bar.set_value(0.0)

	var v_scroll_bar: VScrollBar = scroll_container.get_v_scroll_bar()
	v_scroll_bar.set_value(0.0)


func get_tower_list() -> Array[Tower]:
	var tower_node_list: Array[Node] = get_tree().get_nodes_in_group("towers")
	var tower_list: Array[Tower] = []

	for tower_node in tower_node_list:
		var tower: Tower = tower_node as Tower
		tower_list.append(tower)

	return tower_list


func get_creep_list() -> Array[Creep]:
	var tower_node_list: Array[Node] = get_tree().get_nodes_in_group("creeps")
	var creep_list: Array[Creep] = []

	for creep_node in tower_node_list:
		var creep: Creep = creep_node as Creep
		creep_list.append(creep)

	return creep_list


# Setup range indicators for tower attack, auras and extra
# abilities.
# NOTE: tower stats must be initialized before calling this
func setup_range_indicators(range_data_list: Array[RangeData], parent: Node2D, player: Player) -> Array[RangeIndicator]:
	var indicator_list: Array[RangeIndicator] = []

	var occupied_radius_list: Array = []

	for i in range(0, range_data_list.size()):
		var range_data: RangeData = range_data_list[i]

#		NOTE: if there are multiple ranges with same radius,
#		shift them slightly so that they don't get drawn on
#		top of each other.
		var indicator_radius: float = range_data.get_radius_with_builder_bonus(player)

		while occupied_radius_list.has(indicator_radius):
			indicator_radius -= 10

#			It's theoretically possible for there to be no
#			available radius, in that case - give up
			if indicator_radius == 10:
				break

		occupied_radius_list.append(indicator_radius)

		var range_indicator: RangeIndicator = RangeIndicator.make()
#		NOTE: enable floor collisions only for range
#		indicators intended for creeps. For other range
#		indicators, like tower auras, we should not do
#		floor collisions because the range indicator may be
#		fully located on the second floor.
		range_indicator.enable_floor_collisions = range_data.targets_creeps
		range_indicator.set_radius(indicator_radius)
		var range_color: Color = RangeData.get_color_for_index(i)
		range_indicator.color = range_color
		range_indicator.visible = false

#		NOTE: range indicators which affect towers will be
#		drawn at same height as tower.
#		 
#		Range indicators which affect creeps will be drawn
#		one level lower, so that the indicator is "on the
#		ground".
		var y_offset: float
		if range_data.targets_creeps:
			y_offset = Constants.TILE_SIZE.y
		else:
			y_offset = 0

		range_indicator.y_offset = y_offset

		parent.add_child(range_indicator)
		indicator_list.append(range_indicator)

	return indicator_list


# Returns AoE damage dealt to unit, taking into account how
# far the unit is from the AoE center. Normally, all units
# inside the AoE range will receive the same damage but if
# the "sides_ratio" arg is not 0, units far away from center
# will receive less damage. For example, if sides_ratio is
# 0.10, then units far away from the center of aoe will
# receive 10% less damage.
func get_aoe_damage(aoe_center: Vector2, target: Unit, radius: float, damage: float, sides_ratio: float) -> float:
	var target_pos: Vector2 = target.get_position_wc3_2d()
	var distance: float = aoe_center.distance_to(target_pos)
	var distance_ratio: float = Utils.divide_safe(distance, radius)
	var target_is_on_the_sides: bool = distance_ratio > 0.5

	if target_is_on_the_sides:
		return damage * (1.0 - sides_ratio)
	else:
		return damage


func item_id_list_to_item_list(item_id_list: Array[int], player: Player) -> Array[Item]:
	var item_list: Array[Item] = []

	for item_id in item_id_list:
		var item: Item = Item.make(item_id, player)
		item_list.append(item)

	return item_list


func item_list_to_item_id_list(item_list: Array[Item]) -> Array[int]:
	var item_id_list: Array[int] = []

	for item in item_list:
		var item_id: int = item.get_id()
		item_id_list.append(item_id)

#	NOTE: sort so that item lists can be compared
	item_id_list.sort()

	return item_id_list
