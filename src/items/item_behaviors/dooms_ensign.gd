extends ItemBehavior


var ensign_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Ensign's Touch[/color]\n"
	text += "Whenever the carrier hits the main target, it decreases the armor of the target by 10% for 5 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.6% armor decrease\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func item_init():
	ensign_bt = BuffType.new("ensign_bt", 5, 0, false, self)
	ensign_bt.set_buff_icon("res://resources/icons/generic_icons/open_wound.tres")
	ensign_bt.set_buff_tooltip("Ensign's Touch\nReduces armor.")
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ARMOR_PERC, -0.10, -0.006)
	ensign_bt.set_buff_modifier(mod)


func on_damage(event: Event):
	if event.is_main_target():
		ensign_bt.apply(item.get_carrier(), event.get_target(), item.get_carrier().get_level())
