class_name AuraType

# AuraType stores information about an aura. Should be used
# to create Aura instances. Create an AuraType and set it's
# properties, then pass AuraType to Tower.add_aura() or
# BuffType.add_aura().


var aura_range: float = 10.0
var target_type: TargetType = null
var target_self: bool = false
var level: int = 0
var level_add: int = 0
var power: int = 0
var power_add: int = 0
var aura_effect: BuffType = null

var _include_invisible: bool = false


func make(caster: Unit) -> Aura:
	var aura: Aura = preload("res://Scenes/Buffs/Aura.tscn").instantiate()
	aura._aura_range = get_range()
	aura._target_type = target_type
	aura._target_self = target_self
	aura._level = level
	aura._level_add = level_add
	aura._power = power
	aura._power_add = power_add
	aura._aura_effect = aura_effect
	aura._include_invisible = _include_invisible

	aura._caster = caster

	return aura


# NOTE: need to apply bonus from Farseer builder here and
# not anywhere later like in Aura.gd. If we apply this bonus
# later, it will not be correctly displayed by aura range
# indicator.
func get_range() -> float:
	var builder_range_bonus: float = Globals.get_builder_range_bonus()
	var total_range: float = aura_range + builder_range_bonus

	return total_range
