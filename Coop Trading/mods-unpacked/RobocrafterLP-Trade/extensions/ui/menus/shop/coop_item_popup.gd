extends CoopItemPopup

signal weapon_trade_button_pressed_coop(weapon_data, player_index)
signal item_trade_button_pressed_coop(item_data, player_index)

var _ptrade = [null, null, null, null]
var _ptrade_reason = [null, null, null, null]
var _pcbuttoncoop
# Vanilla focus target directly below Cancel, captured before we rewire anything.
# Primal Dread put the meca Upgrade button there; earlier versions had nothing.
var _below_cancel: Control = null

# No DUPLICATE_SIGNALS: a copy of Cancel would otherwise also fire _on_CancelButton_pressed on every trade.
const TRADE_BUTTON_DUPLICATE_FLAGS = Node.DUPLICATE_GROUPS | Node.DUPLICATE_SCRIPTS | Node.DUPLICATE_USE_INSTANCING

func Is_coop() -> bool:
	return RunData.get_player_count() > 1

func _ready():
	if not Is_coop():
		return
	if not _cancel_button.focus_neighbour_bottom.is_empty():
		_below_cancel = _cancel_button.get_node_or_null(_cancel_button.focus_neighbour_bottom)
	_pcbuttoncoop = _cancel_button.duplicate()
	var children = _pcbuttoncoop.get_children()
	for child in children:
		child.free()
	if not _pcbuttoncoop:
		return

	# Drop the navigation inherited from Cancel; _rebuild_trade_focus_chain wires the trade buttons.
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
		_ptrade_reason[player_index] = _make_reason_label(buttons, button)

func update_trade_buttons() -> void:
	# Defer one frame so this never runs nested inside a trade/button-press (which mutated a
	# control mid-signal and could crash), and so buttons are settled in the tree before we read
	# their paths. One idle frame is visually instant, unlike the original fixed 0.1s delay.
	yield(get_tree(), "idle_frame")
	if not is_inside_tree():
		return

	for i in RunData.get_player_count():
		if _ptrade[i] != null:
			_ptrade[i].visible = _focused and i != player_index

	_rebuild_trade_focus_chain()

	# Vanilla's button logic only knows weapons, so set the item buttons here. Weapons are left
	# to vanilla, which also handles weapon locks and the Primal Dread meca Upgrade/effect choice.
	if _item_data is ItemData:
		_cancel_button.visible = _focused
		if !ModLoaderStore.mod_data.has("RobocrafterLP-ItemSelling"):
			_discard_button.hide()
		_combine_button.hide()

	# Disable target buttons the receiver can't accept, and show the reason beneath each.
	_refresh_trade_gates()

# Controller focus chain: Cancel -> visible trade buttons (on-screen order) -> whatever vanilla had
# below Cancel. Rebuilt from the cached vanilla target every time; re-reading Cancel's neighbour
# after we had overwritten it made the trade button point at itself, hiding the Upgrade button.
func _rebuild_trade_focus_chain() -> void:
	if not is_inside_tree():
		return

	var chain := [_cancel_button]
	for child in _cancel_button.get_parent().get_children():
		if child in _ptrade and child.visible:
			chain.push_back(child)

	for i in range(1, chain.size()):
		chain[i].focus_neighbour_top = chain[i].get_path_to(chain[i - 1])
		chain[i - 1].focus_neighbour_bottom = chain[i - 1].get_path_to(chain[i])

	var last: Control = chain[chain.size() - 1]
	if _below_cancel != null:
		last.focus_neighbour_bottom = last.get_path_to(_below_cancel)
		_below_cancel.focus_neighbour_top = _below_cancel.get_path_to(last)
	else:
		last.focus_neighbour_bottom = NodePath()


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
			if _ptrade_reason[_player_index] != null:
				_ptrade_reason[_player_index].hide()
		_rebuild_trade_focus_chain()

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


# --- Trade gating UI ------------------------------------------------------------
func _make_reason_label(container: Node, button: Control) -> Label:
	var label = Label.new()
	label.align = Label.ALIGN_CENTER
	label.autowrap = true
	# Smaller than the button text and a muted gray, so it reads as a quiet status note
	# rather than an error message.
	var base_font = button.get_font("font")
	if base_font is DynamicFont:
		var small_font = base_font.duplicate()
		small_font.size = int(max(8, base_font.size * 0.55))
		label.add_font_override("font", small_font)
	label.add_color_override("font_color", Color(0.6, 0.6, 0.6))
	label.hide()
	container.add_child(label)
	container.move_child(label, button.get_index() + 1)
	return label

# For each visible target button, ask the single source of truth (RunData) whether the
# trade is allowed; if not, disable the button and show why. Re-run every time the popup
# is shown/focused, so it reflects the receiver's current inventory and character.
func _refresh_trade_gates() -> void:
	for i in RunData.get_player_count():
		var button = _ptrade[i]
		if button == null:
			continue
		var label = _ptrade_reason[i]
		if i == player_index or not button.visible:
			if label != null:
				label.hide()
			continue
		var reason = _get_trade_block_reason(_item_data, i)
		if reason == 0:
			button.disabled = false
			if label != null:
				label.hide()
		else:
			button.disabled = true
			if label != null:
				label.text = _trade_block_text(_item_data, reason, i)
				label.show()

func _get_trade_block_reason(item_data, target_player_index: int) -> int:
	if item_data is WeaponData:
		return RunData.get_weapon_trade_block_reason(item_data, target_player_index)
	elif item_data is ItemData:
		return RunData.get_item_trade_block_reason(item_data, target_player_index)
	return 0

func _trade_block_text(item_data, reason: int, target_player_index: int) -> String:
	var p = str(target_player_index + 1)
	if item_data is WeaponData:
		if reason == RunData.WTB_TIER_TOO_HIGH:
			return "Weapon tier too high for P%s" % p
		elif reason == RunData.WTB_TIER_TOO_LOW:
			return "Weapon tier too low for P%s" % p
		elif reason == RunData.WTB_NO_MELEE:
			return "P%s can't use melee weapons" % p
		elif reason == RunData.WTB_NO_RANGED:
			return "P%s can't use ranged weapons" % p
		elif reason == RunData.WTB_LOCKED:
			return "P%s's weapons are locked" % p
		elif reason == RunData.WTB_NO_DUPLICATE:
			return "P%s already has this weapon" % p
		elif reason == RunData.WTB_NO_SLOT:
			return "P%s has no free weapon slot" % p
		elif reason == RunData.WTB_CANT_MERGE:
			return "Can't merge with P%s's copy" % p
	elif item_data is ItemData:
		if reason == RunData.ITB_NOT_TRADEABLE:
			return "This item can't be traded"
		elif reason == RunData.ITB_AT_LIMIT:
			return "P%s is at the item limit" % p
	return ""


# The meca Upgrade only applies to weapons, and vanilla resets it inside the
# _update_button_visibilities we bypass for items. Do the same here so an Upgrade button or
# effect choice left over from a previously viewed weapon can't linger on an item.
# (call/get keep this working on game versions before Primal Dread.)
func _hide_meca_upgrade_ui() -> void:
	if has_method("_cancel_pending_upgrade"):
		call("_cancel_pending_upgrade")
	var upgrade_button = get("_upgrade_button")
	if upgrade_button != null:
		upgrade_button.hide()


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
		_hide_meca_upgrade_ui()
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
