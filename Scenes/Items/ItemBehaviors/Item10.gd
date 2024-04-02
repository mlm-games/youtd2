# Cursed Claw
extends ItemBehavior


var boekie_claw_slow: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Cripple[/color]\n"
	text += "This artifact slows the attacked creep by 10% for 5 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4% slow\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func item_init():
	var m: Modifier = Modifier.new() 

	m.add_modification(Modification.Type.MOD_MOVESPEED, 0.0, -0.001) 
	boekie_claw_slow = BuffType.new("boekie_claw_slow", 0, 0, false, self)
	boekie_claw_slow.set_buff_icon("foot.tres")
	boekie_claw_slow.set_buff_modifier(m) 
	boekie_claw_slow.set_stacking_group("boekie_claw_slow")

	boekie_claw_slow.set_buff_tooltip("Cripple\nReduces movement speed.")


func on_attack(event: Event):
	var tower: Tower = item.get_carrier()

	boekie_claw_slow.apply_custom_timed(tower, event.get_target(), 100 + tower.get_level() * 4, 5)
