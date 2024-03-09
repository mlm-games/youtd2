# ItemStashMenu
extends PanelContainer


# This UI element displays items which are currently in the
# item stash.
@export var _rarity_filter_container: VBoxContainer
@export var _item_type_filter_container: VBoxContainer
@export var _item_buttons_container: UnitButtonsContainer

@export var _items_status_panel: ShortResourceStatusPanel
@export var _oils_status_panel: ShortResourceStatusPanel
@export var _commons_status_panel: ShortResourceStatusPanel
@export var _uncommons_status_panel: ShortResourceStatusPanel
@export var _rares_status_panel: ShortResourceStatusPanel
@export var _uniques_status_panel: ShortResourceStatusPanel
@export var _menu_card: ButtonStatusCard
@export var _backpacker_recipes: GridContainer

var _prev_item_list: Array[Item] = []
var _item_button_list: Array[ItemButton] = []


#########################
### Code starts here  ###
#########################

func _ready():
	HighlightUI.register_target("item_stash", _item_buttons_container)
	HighlightUI.register_target("item_placed_inside_tower", _item_buttons_container)
	_item_buttons_container.mouse_entered.connect(func(): HighlightUI.highlight_target_ack.emit("item_stash"))

	EventBus.selected_backpacker_builder.connect(_on_selected_backpacker_builder)
	
	var recipe_buttons: Array[Node] = get_tree().get_nodes_in_group("recipe_buttons")
	for node in recipe_buttons:
		var recipe_button: RecipeButton = node as RecipeButton
		var recipe: HoradricCube.Recipe = recipe_button.recipe
		recipe_button.pressed.connect(_on_recipe_button_pressed.bind(recipe))


#########################
###       Public      ###
#########################

func close():
	if _menu_card.get_main_button().is_pressed():
		_menu_card.get_main_button().set_pressed(false)


#########################
###      Private      ###
#########################

func _add_item_button(item: Item, index: int):
	var item_button: ItemButton = ItemButton.make(item)
	item_button.add_to_group("item_button")

	_item_button_list.append(item_button)
	_item_buttons_container.add_child(item_button)
	_item_buttons_container.move_child(item_button, index)

	item_button.pressed.connect(_on_item_button_pressed.bind(item_button))


func _update_resource_status_panels(all_item_list: Array[Item]):
	var items_count: int = Utils.filter_item_list(all_item_list, [], [ItemType.enm.REGULAR]).size()
	var oils_count: int = Utils.filter_item_list(all_item_list, [], [ItemType.enm.CONSUMABLE, ItemType.enm.OIL]).size()
	var commons_count: int = Utils.filter_item_list(all_item_list, [Rarity.enm.COMMON], []).size()
	var uncommons_count: int = Utils.filter_item_list(all_item_list, [Rarity.enm.UNCOMMON], []).size()
	var rares_count: int = Utils.filter_item_list(all_item_list, [Rarity.enm.RARE], []).size()
	var uniques_count: int = Utils.filter_item_list(all_item_list, [Rarity.enm.UNIQUE], []).size()
	
	_items_status_panel.set_count(items_count)
	_oils_status_panel.set_count(oils_count)
	_commons_status_panel.set_count(commons_count)
	_uncommons_status_panel.set_count(uncommons_count)
	_rares_status_panel.set_count(rares_count)
	_uniques_status_panel.set_count(uniques_count)


func _update_horadric_cube_recipes(item_list: Array[Item]):
	var recipe_buttons: Array[Node] = get_tree().get_nodes_in_group("recipe_buttons")
	
	for node in recipe_buttons:
		var recipe_button: RecipeButton = node as RecipeButton
		var recipe: HoradricCube.Recipe = recipe_button.recipe
		var autofill_is_possible: bool = HoradricCube.has_recipe_ingredients(recipe, item_list)
		
		recipe_button.disabled = !autofill_is_possible


func _update_button_visibility():
	var rarity_filter: Array = _rarity_filter_container.get_filter()
	var item_type_filter: Array = _item_type_filter_container.get_filter()

	for item_button in _item_button_list:
		var item: Item = item_button.get_item()
		var rarity: Rarity.enm = item.get_rarity()
		var item_type: ItemType.enm = item.get_item_type()
		var rarity_match: bool = rarity_filter.has(rarity) || rarity_filter.is_empty()
		var item_type_match: bool = item_type_filter.has(item_type) || item_type_filter.is_empty()
		
		item_button.visible = rarity_match && item_type_match

	var visible_count: int = 0
	for item_button in _item_button_list:
		if item_button.visible:
			visible_count += 1

	_item_buttons_container.update_empty_slots(visible_count)


#########################
###     Callbacks     ###
#########################

# NOTE: need to update buttons selectively to minimuze the
# amount of times buttons are created/destroyed and avoid
# perfomance issues for large item counts. A simpler
# approach would be to remove all buttons and then go
# through the item list and add new buttons but that causes
# perfomance issues.
func set_items(item_list: Array[Item]):
# 	Remove buttons for items which were removed from stash
	var removed_button_list: Array[ItemButton] = []

	for button in _item_button_list:
		var item: Item = button.get_item()
		var item_was_removed: bool = !item_list.has(item)

		if item_was_removed:
			removed_button_list.append(button)

	for button in removed_button_list:
		_item_buttons_container.remove_child(button)
		button.queue_free()
		_item_button_list.erase(button)

# 	Add buttons for items which were added to stash
#	NOTE: preserve the same order as in the stash
	for i in range(0, item_list.size()):
		var item: Item = item_list[i]
		var item_was_added: bool = !_prev_item_list.has(item)

		if item_was_added:
			_add_item_button(item, i)

	_prev_item_list = item_list.duplicate()
	
	_update_resource_status_panels(item_list)
	_update_horadric_cube_recipes(item_list)
	_update_button_visibility()


func _on_item_buttons_container_gui_input(event):
	var left_click: bool = event.is_action_released("left_click")

	if left_click:
		ItemMovement.item_stash_was_clicked()


func _on_transmute_button_pressed():
	HoradricCube.transmute()


func _on_item_button_pressed(item_button: ItemButton):
	var item: Item = item_button.get_item()
	ItemMovement.item_was_clicked_in_item_stash(item)


func _on_recipe_button_pressed(recipe: HoradricCube.Recipe):
	var rarity_filter: Array = _rarity_filter_container.get_filter()
	HoradricCube.autofill_recipe(recipe, rarity_filter)


func _on_selected_backpacker_builder():
	_backpacker_recipes.show()


func _on_close_button_pressed():
	close()


func _on_rarity_filter_container_filter_changed():
	_update_button_visibility()


func _on_item_type_filter_container_filter_changed():
	_update_button_visibility()


#########################
### Setters / Getters ###
#########################
