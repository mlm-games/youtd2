# Warsong Double Bass
extends ItemBehavior

var Neotopia_Drumspeed: BuffType

func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Warsong Double Bass - Aura[/color]\n"
	text += "The catchy Bass Line of the drums increases the attackspeed of towers in 200 range, by 7.5%.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.1% attack speed\n"

	return text


func item_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, 0.0001)
	Neotopia_Drumspeed = BuffType.create_aura_effect_type("Neotopia_Drumspeed", true, self)
	Neotopia_Drumspeed.set_buff_icon("angel_wings.tres")
	Neotopia_Drumspeed.set_buff_icon_color(Color.GREEN)
	Neotopia_Drumspeed.set_buff_modifier(m)
	Neotopia_Drumspeed.set_stacking_group("Neotopia_Drumspeed_Aura")
	Neotopia_Drumspeed.set_buff_tooltip("Warsong Double Bass Effect\nIncreased attack speed.")

	var aura: AuraType = AuraType.new()
	aura.aura_range = 200
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 10
	aura.power = 0
	aura.power_add = 10
	aura.aura_effect = Neotopia_Drumspeed
	item.add_aura(aura)
