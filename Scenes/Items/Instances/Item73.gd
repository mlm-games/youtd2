# Wooden Leg
extends ItemBehavior


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.03, 0.0)
