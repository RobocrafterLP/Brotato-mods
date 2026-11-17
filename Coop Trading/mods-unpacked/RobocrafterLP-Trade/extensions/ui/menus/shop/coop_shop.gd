extends CoopShop

# There I tried to do "is_trade_weapons_over_limit"
# but when the player starts with a weapon over the limit, all weapons after the limit disappear.
#----------------------------------
# So, we could "crack the code" a little and add more hands to the player's over-limit weapons
# but I don't think that would make much sense.

func _ready():
	var player_count: int = RunData.get_player_count()

	for player_index in player_count:
		var _item_popup = _get_item_popup(player_index)
		var _error_discard_weapon = _item_popup.connect(
			"weapon_trade_button_pressed_coop", self, "on_weapon_trade_button_pressed_coop"
		)
		var _error_discard_item = _item_popup.connect(
			"item_trade_button_pressed_coop", self, "on_item_trade_button_pressed_coop"
		)

func on_weapon_trade_button_pressed_coop(weapon_data: WeaponData, from_player_index: int = 0, to_player_index: int = 1) -> void:
	if !_can_weapon_be_bought(weapon_data, to_player_index):
		RunData.play_trade_refused_sound()
		return

	process_player_weapons_inventory(weapon_data, from_player_index)
	.buy_weapon(weapon_data, to_player_index)
	_update_stats(to_player_index)

	SoundManager.play(Utils.get_rand_element(recycle_sounds), 0, 0.1, true)

func on_item_trade_button_pressed_coop(item_data: ItemData, from_player_index: int = 0, to_player_index: int = 1) -> void:
	# Same single source of truth the popup uses to enable/disable the button.
	if RunData.get_item_trade_block_reason(item_data, to_player_index) != RunData.ITB_OK:
		RunData.play_trade_refused_sound()
		return

	process_player_items_inventory(item_data, from_player_index)
	.buy_item(item_data, to_player_index)
	_update_stats(to_player_index)

	SoundManager.play(Utils.get_rand_element(recycle_sounds), 0, 0.1, true)

# Weapon trade eligibility lives in ONE place: RunData.get_weapon_trade_block_reason,
# so this execution guard and the button state in coop_item_popup can never disagree.
func _can_weapon_be_bought(weapon_data: WeaponData, player_index: int) -> bool:
	return RunData.get_weapon_trade_block_reason(weapon_data, player_index) == RunData.WTB_OK

func process_player_items_inventory(item_data: ItemData, player_index: int):
	_popup_manager.reset_focus(player_index)

	# Remove just this slot, like vanilla's recycle does: the inventory then moves this player's
	# selector to a neighbouring slot, or (via focus_lost) to Reroll/Go when the row is now empty.
	# Rebuilding the whole row left the selector on a deleted slot and froze that player's controller.
	_get_gear_container(player_index).items_container._elements.remove_element(item_data, 1, true)

	# apply_replacement = false: the item lives on with the receiver, so the sender must not also get
	# its replaced_by item (that duplicated e.g. Dino Egg into its next hatch stage).
	RunData.remove_item(item_data, player_index, false, false)

	_get_shop_items_container(player_index).reload_shop_items()
	_get_coop_player_container(player_index).on_hide_focused_inventory_popup()
	# Refresh the stat panel AFTER the item and its effects are removed (was called before).
	_update_stats(player_index)

func process_player_weapons_inventory(weapon_data: WeaponData, player_index: int):
	_popup_manager.reset_focus(player_index)

	# Same as vanilla recycling: remove only this slot so the selector is re-homed properly
	# (and the WEAPONS x/y label updates via elements_changed).
	_get_gear_container(player_index).weapons_container._elements.remove_element(weapon_data, 1, true)

	RunData.remove_weapon(weapon_data, player_index)

	_get_shop_items_container(player_index).reload_shop_items()
	_get_coop_player_container(player_index).on_hide_focused_inventory_popup()
	# Refresh the stat panel AFTER the weapon and its effects are removed (was called before).
	_update_stats(player_index)
