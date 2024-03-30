# Orb of Souls
extends ItemBehavior


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Ethereal Knowledge[/color]\n"
	text += "Grants 50 flat experience to the holder. The experience is bound to the item and lost on drop. If the tower has less than 50 experience when the item is dropped, the item will drain experience from the next tower it is placed in, up to 50 experience.\n"

	return text


func on_create():
	item.user_real = 50


func on_drop():
	var tower: Tower = item.get_carrier()
	item.user_real = tower.remove_exp_flat(50)


func on_pickup():
	var tower: Unit = item.get_carrier()
	var r: float = item.user_real
	if r > 0:
		tower.add_exp_flat(r)
