extends Node


# NOTE: these settings are selected during game start. If
# they are accessed before that point, you will get these
# placeholders.
var _player_mode: PlayerMode.enm = PlayerMode.enm.SINGLE
var _wave_count: int = 0
var _game_mode: GameMode.enm = GameMode.enm.BUILD
var _difficulty: Difficulty.enm = Difficulty.enm.EASY
var _origin_seed: int = 0
var _update_ticks_per_physics_tick: int = 1

# NOTE: you must use random functions via one of the
# RandomNumberGenerator instances below. This is to prevent
# desyncs.
# 
# synced_rng => for deterministic code, which is executed in
# the same way on all multiplayer clients. Examples: picking
# a random damage value, picking a random item.
# 
# local_rng => for non-deterministic code, which is executed
# in a way which is particular to local client. Example:
# random offset for floating text which is visible only to
# local player.
# 
# NOTE: need to use RandomNumberGenerator instead of global
# random functions because it's impossible to keep global
# rng pure. This is because some Godot engine components
# (CPUParticles2D) use global rng and corrupt it.
var synced_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var local_rng: RandomNumberGenerator = RandomNumberGenerator.new()


# NOTE: current variables don't need to be reset. If you add
# some variable which needs to be reset, reset it here.
func reset():
	pass


func get_player_mode() -> PlayerMode.enm:
	return _player_mode


func get_wave_count() -> int:
	return _wave_count


func get_game_mode() -> GameMode.enm:
	return _game_mode


func get_difficulty() -> Difficulty.enm:
	return _difficulty


func get_origin_seed() -> int:
	return _origin_seed


func game_mode_is_random() -> bool:
	return Globals.get_game_mode() == GameMode.enm.RANDOM_WITH_UPGRADES || Globals.get_game_mode() == GameMode.enm.TOTALLY_RANDOM


func game_mode_allows_transform() -> bool:
	return Globals.get_game_mode() != GameMode.enm.BUILD || Config.allow_transform_in_build_mode()


func game_is_neverending() -> bool:
	return _wave_count == Constants.WAVE_COUNT_NEVERENDING


func get_update_ticks_per_physics_tick() -> int:
	return _update_ticks_per_physics_tick


func set_update_ticks_per_physics_tick(value: int):
	_update_ticks_per_physics_tick = value
