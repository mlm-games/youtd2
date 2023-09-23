extends Unit


# Corpse visual created after creep dies. Fades away slowly
# then disappears. Note that creep corpses are used by some
# towers, for example the Undistrubed Crypt tower deals aoe
# damage centered on corpse positions.


const FADE_DURATION: float = 10

@export var _sprite: Sprite2D


func _ready():
	super()

	add_to_group("corpses")
	_set_visual_node(_sprite)

#	NOTE: hide the corpse sprite because it currently uses a
#	placeholder asset
	_sprite.visible = false

	var fade_tween = create_tween()
	fade_tween.tween_property(_sprite, "modulate",
		Color(_sprite.modulate.r, _sprite.modulate.g, _sprite.modulate.b, 0),
		FADE_DURATION).set_trans(Tween.TRANS_LINEAR)
	fade_tween.finished.connect(on_fade_finished)


func on_fade_finished():
	queue_free()
