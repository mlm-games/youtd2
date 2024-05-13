class_name ActionSwapItems


static func make(item_uid_src: int, item_uid_dest: int, src_item_container_uid: int, dest_item_container_uid: int) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.SWAP_ITEMS,
		Action.Field.UID: item_uid_src,
		Action.Field.UID_2: item_uid_dest,
		Action.Field.SRC_ITEM_CONTAINER_UID: src_item_container_uid,
		Action.Field.DEST_ITEM_CONTAINER_UID: dest_item_container_uid,
		})

	return action


static func execute(action: Dictionary, player: Player):
	var item_uid_src: int = action[Action.Field.UID]
	var item_uid_dest: int = action[Action.Field.UID_2]
	var src_item_container_uid: int = action[Action.Field.SRC_ITEM_CONTAINER_UID]
	var dest_item_container_uid: int = action[Action.Field.DEST_ITEM_CONTAINER_UID]

	var item_src: Item = GroupManager.get_by_uid("items", item_uid_src)
	var item_dest: Item = GroupManager.get_by_uid("items", item_uid_dest)
	var src_item_container: ItemContainer = GroupManager.get_by_uid("item_containers", src_item_container_uid)
	var dest_item_container: ItemContainer = GroupManager.get_by_uid("item_containers", dest_item_container_uid)

	if item_src == null || item_dest == null || src_item_container == null || dest_item_container == null:
		Messages.add_error(player, "Failed to swap items.")

		return

	var verify_ok: bool = ActionSwapItems.verify(player, item_src, item_dest, src_item_container, dest_item_container)
	if !verify_ok:
		return

	var swapping_items_in_same_container: bool = src_item_container == dest_item_container
	if swapping_items_in_same_container:
#		NOTE: do extra work for the case where items are
#		swapped in same container, to ensure that their
#		indexes are swapped
		var item_src_index: int = dest_item_container.index_of_item(item_src)
		var item_dest_index: int = dest_item_container.index_of_item(item_dest)

# 		NOTE: must remove both items first to avoid errors about
# 		capacity
		src_item_container.remove_item(item_src)
		dest_item_container.remove_item(item_dest)

#		NOTE: need to take care of order, otherwise indexes
#		will get messed up
		if item_src_index <= item_dest_index:
			dest_item_container.add_item(item_dest, item_src_index)
			dest_item_container.add_item(item_src, item_dest_index)
		else:
			dest_item_container.add_item(item_src, item_dest_index)
			dest_item_container.add_item(item_dest, item_src_index)
	else:
# 		NOTE: must remove both items first to avoid errors about
# 		capacity
		src_item_container.remove_item(item_src)
		dest_item_container.remove_item(item_dest)
		dest_item_container.add_item(item_src)
		src_item_container.add_item(item_dest)


# NOTE: don't need to check for capacity because swapping
# items doesn't change the amount of items in each container
static func verify(player: Player, item_src: Item, item_dest: Item, src_container: ItemContainer, dest_container: ItemContainer) -> bool:
	if item_src == null || item_dest == null:
		return false

	var src_trying_to_move_consumable_to_tower: bool = item_src.is_consumable() && dest_container is TowerItemContainer
	var dest_trying_to_move_consumable_to_tower: bool = item_dest.is_consumable() && src_container is TowerItemContainer

	if src_trying_to_move_consumable_to_tower || dest_trying_to_move_consumable_to_tower:
		Messages.add_error(player, "Can't place consumables into towers")
		
		return false

	return true
