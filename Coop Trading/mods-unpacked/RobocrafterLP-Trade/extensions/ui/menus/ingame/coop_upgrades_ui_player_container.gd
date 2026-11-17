extends CoopUpgradesUIPlayerContainer

signal item_trade_button_pressed(item_data)

var _trade_buttons = []

func _ready()->void :
	var buttons = _take_button.get_parent().duplicate()
	_take_button.get_parent().get_parent().add_child(buttons)
	_take_button.get_parent().get_parent().move_child(buttons, _take_button.get_parent().get_index() + 1)
	for child in buttons.get_children():
		child.free()

	var player_count = RunData.get_player_count()
	for _player_index in player_count:
		if _player_index != player_index:
			var test = _take_button.get_stylebox("normal").duplicate()
			var button = _take_button.duplicate()
			button.text = "TRADE_GIVE_TO_PLAYER_BUTTON_%s" % str(_player_index + 1)
			button.name = "%%_p%s" % (_player_index + 1)
			button.disconnect("pressed", self, "_on_TakeButton_pressed")
			button.connect("pressed", self, "_on_item_trade_button_pressed" + str(_player_index + 1))
			button.set_script(preload("res://ui/menus/global/my_menu_button.gd"))
			button.add_stylebox_override("normal", test)
			buttons.add_child(button)
			_trade_buttons.push_back(button)

# Trade buttons follow Take's enabled state (e.g. a meca item needs its effect picked first), and stay
# disabled for weapons, which can't be traded from this screen.
func _update_take_button() -> void:
	._update_take_button()
	for button in _trade_buttons:
		button.disabled = _take_button.disabled or not (_item_data is ItemData)

func _on_item_trade_button_pressed1() -> void:
	_on_item_trade_button_pressed(0)

func _on_item_trade_button_pressed2() -> void:
	_on_item_trade_button_pressed(1)

func _on_item_trade_button_pressed3() -> void:
	_on_item_trade_button_pressed(2)

func _on_item_trade_button_pressed4() -> void:
	_on_item_trade_button_pressed(3)

func _on_item_trade_button_pressed(to: int):
	if _button_pressed:return
	if _item_data == null:return
	_button_pressed = true
	_button_delay_timer.start()

	# Resolve a meca item's effect choice the way vanilla's Take does; trading the raw item gave the
	# receiver both unresolved effect options instead of the chosen effect.
	var item_data = _item_data
	if _needs_meca_effect_choice():
		if _meca_effect_choice_selected == -1:
			return
		item_data = DLC2Data.change_effect_option_to_modular_effect(_item_data, _meca_effect_choice_selected)

	if !RunData.is_can_trade_item(item_data, to):
		RunData.play_trade_refused_sound()
		return

	if _things_to_process_container:
		_things_to_process_container.consumables.remove_element(_consumable_data)
	emit_signal("item_trade_button_pressed", item_data, to)
