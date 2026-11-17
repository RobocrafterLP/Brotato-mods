extends UpgradesUI

func _ready() -> void:
	if !RunData.is_coop_run:
		return

	if RunData.is_coop_run != is_coop_ui:
		return 

	var player_count = RunData.get_player_count()

	for player_index in player_count:
		var player_container: = _get_player_container(player_index)
		var _error_connect = player_container.connect("item_trade_button_pressed", self, "_on_item_trade_button_pressed", [player_index])

func _on_item_trade_button_pressed(item_data:ItemParentData, to_player_index:int, player_index:int)->void :
	_player_is_choosing[player_index] = false
	var consumable = _showing_option[player_index]
	consumable.player_index = to_player_index
	emit_signal("item_take_button_pressed", item_data, consumable)
	
	LinkedStats.reset_player(player_index)
	_update_player_stats(player_index)
	_recheck_extra_items(player_index)
	if not _extra_items_to_process[player_index]:
		emit_signal("consumable_selected", consumable)
		_showing_option[player_index] = null
	if not _show_next_player_options():
		emit_signal("options_processed")
