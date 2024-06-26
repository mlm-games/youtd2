extends ItemBehavior


var stun_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Stun[/color]\n"
	text += "Whenever the carrier hits the main target, it has a 15% attack speed adjusted chance to stun the target for 1 second. Has only a [color=GOLD]1/3[/color] of the normal chance to trigger on bosses!\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.25% chance\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func item_init():
	stun_bt = CbStun.new("stun_bt", 0, 0, false, self)


func on_damage(event: Event):
	var target: Creep = event.get_target()
	var size: int = target.get_size()
	var tower: Tower = item.get_carrier()
	var speed: float = tower.get_base_attack_speed()

	if !event.is_main_target():
		return

	if size < CreepSize.enm.BOSS:
		if tower.calc_chance((0.15 + tower.get_level() * 0.0025) * speed) && event.is_main_target() == true:
			CombatLog.log_item_ability(item, null, "Stun")
			stun_bt.apply_only_timed(tower, target, 1)
	else:
		if tower.calc_chance((0.15 + tower.get_level() * 0.0025) / 3 * speed) && event.is_main_target() == true:
			CombatLog.log_item_ability(item, null, "Stun")
			stun_bt.apply_only_timed(tower, target, 1)
