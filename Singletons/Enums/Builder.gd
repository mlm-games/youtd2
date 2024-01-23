extends Node


enum enm {
	NONE = 0,
	BLADEMASTER,
	QUEEN,
}


const PROPERTIES_PATH: String = "res://Data/builder_properties.csv"

enum CsvProperty {
	ID,
	DISPLAY_NAME,
	SHORT_NAME,
	DESCRIPTION,
}

var _string_map: Dictionary = {}

var _tower_buff_map: Dictionary = {
	Builder.enm.NONE: null,
	Builder.enm.BLADEMASTER: _make_blademaster_tower_bt(),
	Builder.enm.QUEEN: _make_queen_tower_bt(),
}

var _creep_buff_map: Dictionary = {
	Builder.enm.NONE: null,
	Builder.enm.BLADEMASTER: null,
	Builder.enm.QUEEN: _make_queen_creep_bt(),
}

var _selected_builder: Builder.enm = Builder.enm.NONE
var _properties: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
	Properties._load_csv_properties(PROPERTIES_PATH, _properties, Builder.CsvProperty.ID)

	for builder_id in _properties.keys():
		var builder: Builder.enm = builder_id as Builder.enm
		var short_name: String = get_short_name(builder)

		_string_map[builder] = short_name

	for builder in _tower_buff_map.keys():
		var bt: BuffType = _tower_buff_map[builder]

		if bt == null:
			continue

		var builder_name: String = Builder.get_display_name(builder)
		bt.set_buff_tooltip("Buff from builder %s" % builder_name)

		bt.set_hidden()

	for builder in _creep_buff_map.keys():
		var bt: BuffType = _creep_buff_map[builder]

		if bt == null:
			continue

		var builder_name: String = Builder.get_display_name(builder)
		bt.set_buff_tooltip("Buff from builder %s" % builder_name)

		bt.set_hidden()


#########################
###       Public      ###
#########################

# This function should be called once at the start of the
# game. It will also apply any global effects of selected
# builder.
func set_selected_builder(builder: Builder.enm):
	_selected_builder = builder


func from_string(string: String) -> Builder.enm:
	var key = _string_map.find_key(string)
	
	if key != null:
		return key
	else:
		push_error("Invalid string: \"%s\". Possible values: %s" % [string, _string_map.values()])

		return Builder.enm.NONE


func get_display_name(builder: int) -> String:
	var string: String = _get_property(builder, Builder.CsvProperty.DISPLAY_NAME)

	return string


func get_short_name(builder: int) -> String:
	var string: String = _get_property(builder, Builder.CsvProperty.SHORT_NAME)

	return string


func get_buff_for_unit(unit: Unit) -> BuffType:
	var buff: BuffType

	if unit is Tower:
		buff = _tower_buff_map.get(_selected_builder, null)
	elif unit is Creep:
		buff = _creep_buff_map.get(_selected_builder, null)
	else:
		buff = null

	return buff


#########################
###      Private      ###
#########################

func _get_property(builder: int, property: Builder.CsvProperty) -> String:
	if !_properties.has(builder):
		push_error("No properties for builder: ", builder)

		return ""

	var map: Dictionary = _properties[builder]
	var property_value: String = map[property]

	return property_value


func _make_blademaster_tower_bt() -> BuffType:
	var bt: BuffType = BuffType.new("", 0, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.08, 0.0)
	mod.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.40, 0.0)
	mod.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, 1.0, 0.0)
	bt.set_buff_modifier(mod)

	return bt


func _make_queen_tower_bt() -> BuffType:
	var bt: BuffType = BuffType.new("", 0, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.10, 0.0)
	mod.add_modification(Modification.Type.MOD_DMG_TO_AIR, 0.30, 0.02)
	bt.set_buff_modifier(mod)

	return bt


func _make_queen_creep_bt() -> BuffType:
	var bt: BuffType = BuffType.new("", 0, 0, false, self)
	bt.add_event_on_create(_queen_creep_bt_on_create)

	return bt


func _queen_creep_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_unit: Unit = buff.get_buffed_unit()
	var creep: Creep = buffed_unit as Creep

	if creep == null:
		return

	var creep_size: CreepSize.enm = creep.get_size()

	if creep_size == CreepSize.enm.AIR:
		creep.modify_property(Modification.Type.MOD_MOVESPEED_ABSOLUTE, -60)
