extends CoopItemPopup

signal weapon_trade_button_pressed_coop(weapon_data, player_index)
signal item_trade_button_pressed_coop(item_data, player_index)

var _ptrade = [null, null, null, null]
var _pcbuttoncoop
var _cancel_focus_neighbour_3: NodePath

const TRADE_BUTTON_DUPLICATE_FLAGS = Node.DUPLICATE_GROUPS | Node.DUPLICATE_SCRIPTS | Node.DUPLICATE_USE_INSTANCING

func Is_coop() -> bool:
	return RunData.get_player_count() > 1

func _ready():
	if not Is_coop():
		return
	# Cache the native path before update_trade_buttons() rewires CancelButton.
	_cancel_focus_neighbour_3 = _cancel_button.get_focus_neighbour(3)
	_pcbuttoncoop = _cancel_button.duplicate()
	var children = _pcbuttoncoop.get_children()
	for child in children:
		child.free()
	if not _pcbuttoncoop:
		return

	# Clear inherited navigation paths before creating player-trade buttons.
	for side in range(4):
		_pcbuttoncoop.set_focus_neighbour(side, NodePath(""))
	_pcbuttoncoop.focus_next = NodePath("")
	_pcbuttoncoop.focus_previous = NodePath("")

	for player_index in RunData.get_player_count():
		var test = _discard_button.get_stylebox("normal").duplicate()
		var button = _pcbuttoncoop.duplicate(TRADE_BUTTON_DUPLICATE_FLAGS)
		button.text = "TRADE_GIVE_TO_PLAYER_BUTTON_%s" % str(player_index + 1)
		button.name = "%%_p%s" % (player_index + 1)
		button.connect("pressed", self, "_on_TradeButton_pressed_coop" + str(player_index + 1))
		button.set_script(preload("res://ui/menus/global/my_menu_button.gd"))
		button.add_stylebox_override("normal", test)
		button.hide()
		_ptrade[player_index] = button
		var buttons = _cancel_button.get_parent()
		buttons.add_child(button)
		buttons.move_child(button, _cancel_button.get_index() + 1)

func update_trade_buttons() -> void:
	yield (get_tree().create_timer(.1), "timeout")
	var _p2
	var _p3
	var _p4
	var cbd = _cancel_focus_neighbour_3
	# var s = _ptrade.size()
	if player_index == 0:
		_p2 = _ptrade[1]
		_p3 = _ptrade[2]
		_p4 = _ptrade[3]
	elif player_index == 1:
		_p2 = _ptrade[0]
		_p3 = _ptrade[2]
		_p4 = _ptrade[3]
	elif player_index == 2:
		_p2 = _ptrade[0]
		_p3 = _ptrade[1]
		_p4 = _ptrade[3]
	elif player_index == 3:
		_p2 = _ptrade[0]
		_p3 = _ptrade[1]
		_p4 = _ptrade[2]
		
	if _p2 != null and _p3 != null and _p4 != null:
		_p2.set_focus_neighbour(1, _cancel_button.get_path())
		_p2.set_focus_neighbour(3, _p3.get_path())
		_p3.set_focus_neighbour(1, _p2.get_path())
		_p3.set_focus_neighbour(3, _p4.get_path())
		_p4.set_focus_neighbour(1, _p3.get_path())
		_p4.set_focus_neighbour(3, cbd)

		if _focused:
			_p2.show()
			_p3.show()
			_p4.show()
		else:
			_p2.hide()
			_p3.hide()
			_p4.hide()
	elif _p2 != null and _p3 != null:
		_p2.set_focus_neighbour(1, _cancel_button.get_path())
		_p2.set_focus_neighbour(3, _p3.get_path())
		_p3.set_focus_neighbour(1, _p2.get_path())
		_p3.set_focus_neighbour(3, cbd)

		if _focused:
			_p2.show()
			_p3.show()
		else:
			_p2.hide()
			_p3.hide()
	elif _p2 != null:
		_p2.set_focus_neighbour(1, _cancel_button.get_path())
		_p2.set_focus_neighbour(3, cbd)

		if _focused:
			_p2.show()
		else:
			_p2.hide()

	if _p2 != null:
		_cancel_button.set_focus_neighbour(3, _p2.get_path())
		if _focused:
			_cancel_button.show()
		else:
			_cancel_button.hide()
		
		if !ModLoaderStore.mod_data.has("RobocrafterLP-ItemSelling"):
			_discard_button.hide()
			
		_combine_button.hide()
		
		if _item_data is WeaponData and _focused:
			_discard_button.show()
			_combine_button.visible = RunData.can_combine(_item_data, player_index)
		


func trade_update_visible(element):
	if not Is_coop():
		return

	if _item_data is WeaponData and buttons_enabled:
		for _player_index in RunData.get_player_count():
			var button = _ptrade[_player_index]
			button.focus_mode = FOCUS_ALL if _focused else FOCUS_NONE
			
		update_trade_buttons()
	elif _item_data is ItemData and buttons_enabled and not "character" in _item_data.my_id:
		for _player_index in RunData.get_player_count():
			var button = _ptrade[_player_index]
			button.focus_mode = FOCUS_ALL if _focused else FOCUS_NONE
		
		update_trade_buttons()
	else:
		for _player_index in RunData.get_player_count():
			var button = _ptrade[_player_index]
			button.hide()

func display_element(element: InventoryElement) -> void:
	.display_element(element)
	trade_update_visible(null)

func focus()->void :
	.focus()
	trade_update_visible(null)

func hide(_player_index: = - 1)->void :
	.hide(_player_index)
	trade_update_visible(null)

func _on_TradeButton_pressed_coop1() -> void:
	_on_TradeButton_pressed_coop(0)

func _on_TradeButton_pressed_coop2() -> void:
	_on_TradeButton_pressed_coop(1)

func _on_TradeButton_pressed_coop3() -> void:
	_on_TradeButton_pressed_coop(2)

func _on_TradeButton_pressed_coop4() -> void:
	_on_TradeButton_pressed_coop(3)

func _on_TradeButton_pressed_coop(to: int) -> void:
	if _item_data is ItemData:
		emit_signal("item_trade_button_pressed_coop", _item_data, player_index, to)
	elif _item_data is WeaponData:
		emit_signal("weapon_trade_button_pressed_coop", _item_data, player_index, to)


func should_show_buttons(item_data: ItemParentData, focused: bool) -> bool:
	if item_data is ItemData:
		return buttons_enabled and not "character" in item_data.my_id and (not RunData.is_coop_run or focused)
	elif item_data is WeaponData:
		return .should_show_buttons(item_data, focused)
	return false

func _update_button_visibilities() -> void:
	var buttons := [_combine_button, _discard_button, _cancel_button]
	if _item_data is WeaponData:
		._update_button_visibilities()
		return
	elif _item_data is ItemData:
		if _item_data == null or not should_show_buttons(_item_data, _focused):
			for button in buttons:
				if button != null:
					button.hide()
					button.focus_mode = FOCUS_NONE
			return

		for button in buttons:
			if (button != _combine_button):
				button.show()
				button.focus_mode = FOCUS_ALL if _focused else FOCUS_NONE
		
		trade_update_visible(null)
