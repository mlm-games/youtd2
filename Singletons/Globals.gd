extends Node


enum GameState {
	PREGAME,
	TUTORIAL,
	PLAYING,
	PAUSED,
}


const item_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/ItemButton.tscn")
const tower_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/TowerButton.tscn")
const floating_text_scene: PackedScene = preload("res://Scenes/HUD/FloatingText.tscn")
const explosion_scene: PackedScene = preload("res://Scenes/Effects/Explosion.tscn")
const projectile_scene: PackedScene = preload("res://Scenes/Unit/Projectile.tscn")
const aura_scene: PackedScene = preload("res://Scenes/Buffs/Aura.tscn")
const buff_range_area_scene: PackedScene = preload("res://Scenes/Buffs/BuffRangeArea.tscn")
const corpse_scene: PackedScene = preload("res://Scenes/Creeps/CreepCorpse.tscn")
const blood_pool_scene: PackedScene = preload("res://Scenes/Creeps/CreepBloodPool.tscn")
const flying_item_scene: PackedScene = preload("res://Scenes/HUD/FlyingItem.tscn")
const autocast_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/AutocastButton.tscn")
const autocast_scene: PackedScene = preload("res://Scenes/Towers/Autocast.tscn")
const placeholder_effect_scene: PackedScene = preload("res://Scenes/Effects/GenericMagic.tscn")
const tower_actions_scene: PackedScene = preload("res://Scenes/HUD/TowerActions.tscn")
const empty_slot_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/EmptyUnitButton.tscn")
const range_indicator_scene: PackedScene = preload("res://Scenes/Towers/RangeIndicator.tscn")
const button_with_rich_tooltip_scene: PackedScene = preload("res://Scenes/HUD/ButtonWithRichTooltip.tscn")
const outline_shader: Material = preload("res://Resources/Shaders/GlowingOutline.material")
const special_container: PackedScene = preload("res://Scenes/HUD/UnitMenu/SpecialContainer.tscn")
const player_scene: PackedScene = preload("res://Scenes/Player/Player.tscn")
const element_icons: Dictionary = {
	Element.enm.ICE: preload("res://Resources/Textures/UI/Icons/ice_icon.tres"),
	Element.enm.NATURE: preload("res://Resources/Textures/UI/Icons/nature_icon.tres"),
	Element.enm.ASTRAL: preload("res://Resources/Textures/UI/Icons/astral_icon.tres"),
	Element.enm.DARKNESS: preload("res://Resources/Textures/UI/Icons/darkness_icon.tres"),
	Element.enm.FIRE: preload("res://Resources/Textures/UI/Icons/fire_icon.tres"),
	Element.enm.IRON: preload("res://Resources/Textures/UI/Icons/iron_icon.tres"),
	Element.enm.STORM: preload("res://Resources/Textures/UI/Icons/storm_icon.tres"),
}


var game_over: bool
var room_code: String
var _game_state: GameState

# Game settings
var _wave_count: int
var _game_mode: GameMode.enm
var _player_mode: PlayerMode.enm
var _difficulty: Difficulty.enm
var _tutorial_enabled: bool

var _builder_id: int
var _builder_instance: Builder
var _builder_range_bonus: float
var _builder_tower_lvl_bonus: int
var _builder_item_slots_bonus: int
var _builder_allows_adjacent_towers: bool


func reset():
	game_over = false

	_wave_count = Config.default_wave_count()
	_game_mode = Config.default_game_mode()
	_player_mode = Config.default_player_mode()
	_difficulty = Config.default_difficulty()
	_tutorial_enabled = Config.default_tutorial_enabled()

	_builder_id = Config.default_builder_id()
	_builder_range_bonus = 0
	_builder_tower_lvl_bonus = 0
	_builder_item_slots_bonus = 0
	_builder_allows_adjacent_towers = true


func set_game_state(value: GameState):
	_game_state = value


func get_game_state() -> GameState:
	return _game_state


func get_builder() -> Builder:
	return _builder_instance


func get_builder_range_bonus() -> float:
	return _builder_range_bonus


func get_builder_tower_lvl_bonus() -> int:
	return _builder_tower_lvl_bonus


func get_builder_item_slots_bonus() -> int:
	return _builder_item_slots_bonus


func get_builder_allows_adjacent_towers() -> bool:
	return _builder_allows_adjacent_towers


func get_wave_count() -> int:
	return _wave_count


func get_game_mode() -> GameMode.enm:
	return _game_mode


func get_player_mode() -> PlayerMode.enm:
	return _player_mode


func get_difficulty() -> Difficulty.enm:
	return _difficulty


func get_builder_id() -> int:
	return _builder_id


func get_tutorial_enabled() -> bool:
	return _tutorial_enabled


func game_mode_is_random() -> bool:
	return Globals.get_game_mode() == GameMode.enm.RANDOM_WITH_UPGRADES || Globals.get_game_mode() == GameMode.enm.TOTALLY_RANDOM


func game_mode_allows_transform() -> bool:
	return Globals.get_game_mode() != GameMode.enm.BUILD || Config.allow_transform_in_build_mode()
