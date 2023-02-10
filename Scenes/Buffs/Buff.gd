class_name Buff
extends Node2D


# Buff stores buff parameters and applies them to target
# while it is active. Define custom buffs by creating a
# subclass.
# 
# Buffs can have event handlers. To add an event handler,
# define a handler function in your subclass and call the
# appropriate add_event_handler function. All handler
# functions are called with one parameter Event which passes
# information about the event.

# TODO: what is friendly used for? It's not used as sign
# multiplier on value (confirmed by original tower scripts).
# Maybe used for stacking behavior?

# TODO: EventType.CLEANUP is currently fired when buff is
# overriden. Need to figure out how cleanup works together
# with REFRESH and UPGRADED event types. If a buff is
# refreshed, should both CLEANUP and REFRESH fire or just
# REFRESH? If so, then refresh needs to reuse current buff
# instance instead of current behavior which is replacing
# with new instance.

# TODO: implement the following event types
# SPELL_CAST
# SPELL_TARGET
# UPGRADE
# REFRESH
# PURGED

# NOTE: this signal is separate from the EXPIRE event type
# and used by Unit to undo buff modifiers. Do not use this
# in Tower scripts. Use EXPIRE event handler.
signal removed()

enum ModifierLevelType {
	TOWER,
	BUFF,
}

enum EventType {
	CLEANUP,
	CREATE,
	DEATH,
	KILL,
	LEVEL_UP,
	ATTACK,
	ATTACKED,
	DAMAGE,
	DAMAGED,
	EXPIRE,
}

enum TargetType {
	TOWER,
	MOB,
	ALL,
}

class EventHandler:
	var object: Node
	var handler_function: String
	var has_chance: bool
	var chance: float
	var chance_level_add: float


var _caster: Unit
var _target: Unit
var _modifier: Modifier = Modifier.new() setget set_modifier, get_modifier
var _level: int
var _modifier_level_type: int = ModifierLevelType.TOWER
var _friendly: bool
var _id: String
# Map of EventType -> list of EventHandler's
var event_handler_map: Dictionary = {}


func _init(id: String):
	_id = id



# Call this after creating the buff and before applying
func apply_to_unit(caster: Unit, target: Unit, time: float, time_level_add: float, level: int, friendly: bool):
	_caster = caster
	_level = level
	_friendly = friendly

#	TODO: implement using tower level as modifier level
	_modifier.level = level

	var apply_success: bool = target._apply_buff(self)

	if !apply_success:
		return

	_target = target
	_target.connect("death", self, "_on_target_death")
	_target.connect("kill", self, "_on_target_kill")
	_target.connect("level_up", self, "_on_target_level_up")
	_target.connect("attack", self, "_on_target_attack")
	_target.connect("attacked", self, "_on_target_attacked")
	_target.connect("damage", self, "_on_target_damage")
	_target.connect("damaged", self, "_on_target_damaged")

	if time > 0.0:
		var timer: Timer = Timer.new()
		add_child(timer)
		timer.connect("timeout", self, "_on_timer_timeout")
		var total_time: float = time + time_level_add * _level
		timer.start(total_time)

	var create_event: Event = Event.new()
	create_event.buff = self
	_call_event_handler_list(EventType.CREATE, create_event)


func apply_to_unit_permanent(caster: Unit, target: Unit, level: int, friendly: bool):
	apply_to_unit(caster, target, -1.0, 0.0, level, friendly)


func set_modifier(modifier: Modifier):
	_modifier = modifier


func get_modifier() -> Modifier:
	return _modifier


func get_level() -> int:
	return _level


func get_id() -> String:
	return _id


func get_target() -> Unit:
	return get_parent() as Unit


func stop():
	_on_timer_timeout()


func add_event_handler(event_type: int, handler_object: Node, handler_function: String):
	if !_check_handler_exists(handler_object, handler_function):
		return

	var handler: EventHandler = EventHandler.new()
	handler.object = handler_object
	handler.handler_function = handler_function
	handler.has_chance = false
	handler.chance = 0.0
	handler.chance_level_add = 0.0

	_add_event_handler_internal(event_type, handler)


# NOTE: in original, only events of type
# attack/attacked/damage/damaged could have chance, but for
# convenience allow setting chance to all types of events
func add_event_handler_with_chance(event_type: int, handler_object, handler_function: String, chance: float, chance_level_add: float):
	var handler: EventHandler = EventHandler.new()
	handler.object = handler_object
	handler.handler_function = handler_function
	handler.has_chance = true
	handler.chance = chance
	handler.chance_level_add = chance_level_add

	_add_event_handler_internal(event_type, handler)


func add_event_handler_periodic(handler_object: Node, handler_function: String, period: float):
	if !_check_handler_exists(handler_object, handler_function):
		return

	var timer: Timer = Timer.new()
	add_child(timer)
	timer.wait_time = period
	timer.one_shot = false
	timer.autostart = true
	timer.connect("timeout", self, "_on_periodic_event_timer_timeout", [handler_object, handler_function])


func add_event_handler_unit_comes_in_range(handler_object: Node, handler_function: String, radius: float, target_type: int):
	if !_check_handler_exists(handler_object, handler_function):
		return

	var buff_range_area_scene: PackedScene = load("res://Scenes/Buffs/BuffRangeArea.tscn")
	var buff_range_area = buff_range_area_scene.instance()
#	NOTE: use call_deferred() adding child immediately causes an error about
# 	setting shape during query flushing
	call_deferred("add_child", buff_range_area)
	buff_range_area.init(radius, target_type, handler_object, handler_function)

	buff_range_area.connect("unit_came_in_range", self, "_on_unit_came_in_range")


func _on_unit_came_in_range(handler_object: Node, handler_function: String, unit: Unit):
	var event = Event.new()
	event.buff = self
	event.target = unit

	handler_object.call(handler_function, event)


func _add_event_handler_internal(event_type: int, handler: EventHandler):
	if !event_handler_map.has(event_type):
		event_handler_map[event_type] = []

	event_handler_map[event_type].append(handler)


func _call_event_handler_list(event_type: int, event: Event):
	if !event_handler_map.has(event_type):
		return

	var handler_list: Array = event_handler_map[event_type]

	for handler in handler_list:
		if handler.has_chance:
			var chance: float = min(1.0, handler.chance + handler.chance_level_add * _level)	
			var chance_success: bool = Utils.rand_chance(chance)

			if !chance_success:
				continue

		handler.object.call(handler.handler_function, event)


func _on_timer_timeout():
	var cleanup_event: Event = Event.new()
	cleanup_event.buff = self
	_call_event_handler_list(EventType.CLEANUP, cleanup_event)

	emit_signal("removed")

	var event: Event = Event.new()
	event.buff = self
	_call_event_handler_list(EventType.EXPIRE, event)


func _on_target_dead(event: Event):
	_call_event_handler_list(EventType.DEATH, event)
	_call_event_handler_list(EventType.CLEANUP, event)


func _on_target_kill(event: Event):
	_call_event_handler_list(EventType.KILL, event)


func _on_target_level_up():
	var event: Event = Event.new()
	event.buff = self
	_call_event_handler_list(EventType.LEVEL_UP, event)


func _on_target_attack(event: Event):
	_call_event_handler_list(EventType.ATTACK, event)


func _on_target_attacked(event: Event):
	_call_event_handler_list(EventType.ATTACKED, event)


func _on_target_damage(event: Event):
	_call_event_handler_list(EventType.DAMAGE, event)


func _on_target_damaged(event: Event):
	_call_event_handler_list(EventType.DAMAGED, event)


func _on_periodic_event_timer_timeout(handler_object: Node, handler_function: String):
	var event: Event = Event.new()
	event.buff = self
	handler_object.call(handler_function, event)


func _check_handler_exists(handler_object: Node, handler_function: String) -> bool:
	var exists: bool = handler_object.has_method(handler_function)

	if !exists:
		print_debug("Attempted to register an event handler that doesn't exist: ", handler_function)

	return exists
