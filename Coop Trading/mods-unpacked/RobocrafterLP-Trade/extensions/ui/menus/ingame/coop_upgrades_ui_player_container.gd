extends CoopUpgradesUIPlayerContainer

signal item_trade_button_pressed(item_data)

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
			button.text = "TRADE_GIVE_TO_PLAYER_BUTTON_%s" % str(player_index + 1)
			button.name = "%%_p%s" % (_player_index + 1)
			button.disconnect("pressed", self, "_on_TakeButton_pressed")
			button.connect("pressed", self, "_on_item_trade_button_pressed" + str(_player_index + 1))
			button.set_script(preload("res://ui/menus/global/my_menu_button.gd"))
			button.add_stylebox_override("normal", test)
			buttons.add_child(button)

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
	_button_pressed = true
	_button_delay_timer.start()

	if !RunData.is_can_trade_item(_item_data, to):
		SoundManager.play(Utils.get_rand_element(Player.new().hurt_sounds), 0, 0.0, true)
		return

	if _things_to_process_container:
		_things_to_process_container.consumables.remove_element(_consumable_data)
	emit_signal("item_trade_button_pressed", _item_data, to)
