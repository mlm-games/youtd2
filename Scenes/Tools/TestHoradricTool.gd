class_name TestHoradricTool extends Node


# Enable by adding "config/run_test_horadric_tool=true" to
# override.cfg


static func run():
	test_get_current_recipe()
	test_get_item_list_for_autofill()
	TestTool.print_totals()


class TestCase_get_current_recipe extends TestTool.TestCase_base:
	var item_id_list: Array[int] = []
	var expected_recipe: HoradricCube.Recipe

	func _init(item_id_list_arg: Array[int], expected_recipe_arg: HoradricCube.Recipe, description_arg: String):
		item_id_list = item_id_list_arg
		expected_recipe = expected_recipe_arg
		description = description_arg


static func test_get_current_recipe():
	var test_case_list: Array[TestCase_get_current_recipe] = [
		TestCase_get_current_recipe.new([], HoradricCube.Recipe.NONE, "0 items."),
		TestCase_get_current_recipe.new([1, 1001], HoradricCube.Recipe.NONE, "1 permanent item, 1 oil."),
		TestCase_get_current_recipe.new([1, 2001], HoradricCube.Recipe.NONE, "1 permanent item, 1 consumable."),

		TestCase_get_current_recipe.new([1001, 1001], HoradricCube.Recipe.REBREW, "2 oils of same rarity."),
		TestCase_get_current_recipe.new([1001, 2001], HoradricCube.Recipe.REBREW, "1 oil, 1 consumable."),
		TestCase_get_current_recipe.new([2001, 2001], HoradricCube.Recipe.REBREW, "2 consumables."),
		TestCase_get_current_recipe.new([1001], HoradricCube.Recipe.NONE, "1 oil. Invalid recipe because not enough oils."),
		TestCase_get_current_recipe.new([1001, 1002], HoradricCube.Recipe.NONE, "2 oils with different rarities. Invalid recipe because different rarities."),

		TestCase_get_current_recipe.new([1001, 1001, 1001, 1001], HoradricCube.Recipe.DISTILL, "4 oils."),

		TestCase_get_current_recipe.new([3, 4, 5], HoradricCube.Recipe.REASSEMBLE, "3 permanent items with same rarity. OK."),
		TestCase_get_current_recipe.new([3, 4, 8], HoradricCube.Recipe.NONE, "3 permanent items with different rarities. Invalid recipe because Item3 and Item4 are UNCOMMON while Item8 is UNIQUE."),
		TestCase_get_current_recipe.new([3], HoradricCube.Recipe.NONE, "1 permanent items. Invalid recipe because not enough items."),
		TestCase_get_current_recipe.new([3, 4], HoradricCube.Recipe.NONE, "2 permanent items. Invalid recipe because not enough items."),
		TestCase_get_current_recipe.new([3, 4, 5, 6], HoradricCube.Recipe.NONE, "4 permanent items. Invalid recipe because too many items."),

		TestCase_get_current_recipe.new([3, 4, 5, 6, 7], HoradricCube.Recipe.PERFECT, "5 permanent items with same rarity."),
		TestCase_get_current_recipe.new([3, 4, 5, 6, 8], HoradricCube.Recipe.NONE, "5 permanent items with different rarities. Invalid recipe because Item8 is UNIQUE."),
		TestCase_get_current_recipe.new([3, 4, 5, 6], HoradricCube.Recipe.NONE, "4 permanent items with same rarity. Invalid recipe because not enough items."),
		TestCase_get_current_recipe.new([3, 4, 5, 6, 7, 19], HoradricCube.Recipe.NONE, "6 permanent items with same rarity. Invalid recipe because too many items."),

		TestCase_get_current_recipe.new([3, 4, 5, 6, 7, 19], HoradricCube.Recipe.NONE, "6 permanent items with same rarity. Invalid recipe because too many items."),
	]

	var test_case_function: Callable = func(test_case: TestCase_get_current_recipe):
		var item_id_list: Array[int] = test_case.item_id_list
		var item_list: Array[Item] = TestHoradricTool.item_id_list_to_item_list(item_id_list)
		var expected_recipe: HoradricCube.Recipe = test_case.expected_recipe
		var actual_recipe: HoradricCube.Recipe = HoradricCube._get_current_recipe(item_list)

		TestTool.compare(actual_recipe, expected_recipe)

	TestTool.run("get_current_recipe()", test_case_list, test_case_function)


class TestCase_get_item_list_for_autofill extends TestTool.TestCase_base:
	var recipe: HoradricCube.Recipe
	var ingredient_list: Array[int] = []
	var expected_result_list: Array[int] = []

	func _init(recipe_arg: HoradricCube.Recipe, ingredient_list_arg: Array[int], expected_result_list_arg: Array[int], description_arg: String):
		recipe = recipe_arg
		ingredient_list = ingredient_list_arg
		expected_result_list = expected_result_list_arg
		description = description_arg


static func test_get_item_list_for_autofill():
	var test_case_list: Array[TestCase_get_item_list_for_autofill] = [
		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.REBREW, [1001, 1001], [1001, 1001], "2 oils."),
		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.REBREW, [1005, 1005, 1001, 1011, 1001, 1, 2, 3], [1001, 1001], "2 oils mixed with items and other oils."),
		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.NONE, [1, 1001], [], "1 oil and 1 item."),
		
		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.DISTILL, [1003, 1006, 1009, 1015], [1003, 1006, 1009, 1015], "4 oils."),
		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.DISTILL, [1003, 1006, 2004, 2004], [1003, 1006, 2004, 2004], "2 oils and 2 consumables. Mixing should be allowed."),

		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.REASSEMBLE, [3, 4, 5], [3, 4, 5], "3 items."),
		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.REASSEMBLE, [3, 4, 5, 6, 7], [5, 6, 7], "5 items. Lowest level should be picked."),
		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.REASSEMBLE, [3, 4, 5, 36, 37, 38], [36, 37, 38], "3 uncommon items and 3 common items. Lowest rarity should be picked."),

		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.PERFECT, [64, 65, 66, 67, 68], [64, 65, 66, 67, 68], "5 items."),
		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.PERFECT, [1001, 1002, 1003, 10, 64, 65, 66, 198, 67, 68], [64, 65, 66, 67, 68], "5 items mixed with other items and oils."),
		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.PERFECT, [64, 65, 66, 67], [], "4 items. Not enough for Perfect"),
		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.PERFECT, [64, 65, 66, 67, 74], [], "5 items but item74 is different rarity."),

		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.REASSEMBLE, [], [], "0 items for reassemble"),
		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.PERFECT, [], [], "0 items for perfect"),
		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.DISTILL, [], [], "0 items for distill"),
		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.REBREW, [], [], "0 items for rebrew"),

		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.DISTILL, [2008, 2008, 2008, 2008, 2008], [], "4 unique oils for DISTILL. Invalid because can't raise rarity further."),
		TestCase_get_item_list_for_autofill.new(HoradricCube.Recipe.PERFECT, [1, 1, 1, 1, 1], [], "5 permanent items for PERFECT. Invalid because can't raise rarity further."),
	]

	var test_case_function: Callable = func(test_case: TestCase_get_item_list_for_autofill):
		var recipe: HoradricCube.Recipe = test_case.recipe
		var ingredient_list: Array[int] = test_case.ingredient_list
		var ingredient_item_list: Array[Item] = TestHoradricTool.item_id_list_to_item_list(ingredient_list)
		var expected_result_list: Array[int] = test_case.expected_result_list
		var actual_result_item_list: Array[Item] = HoradricCube._get_item_list_for_autofill(recipe, ingredient_item_list)
		var actual_result_list: Array[int] = item_list_to_item_id_list(actual_result_item_list)

		TestTool.compare(actual_result_list, expected_result_list)

	TestTool.run("get_item_list_for_autofill()", test_case_list, test_case_function)


static func item_id_list_to_item_list(item_id_list: Array[int]) -> Array[Item]:
	var item_list: Array[Item] = []

	for item_id in item_id_list:
		var item: Item = Item.make(item_id)
		item_list.append(item)

	return item_list


static func item_list_to_item_id_list(item_list: Array[Item]) -> Array[int]:
	var item_id_list: Array[int] = []

	for item in item_list:
		var item_id: int = item.get_id()
		item_id_list.append(item_id)

#	NOTE: sort so that comparisons work
	item_id_list.sort()

	return item_id_list
