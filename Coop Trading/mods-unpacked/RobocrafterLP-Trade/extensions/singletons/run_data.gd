extends "res://singletons/run_data.gd"

const RobocrafterLP_Trade = "RobocrafterLP-Trade"
const trade_items_over_limit_config = "TRADE_ITEMS_OVER_LIMIT"

var coop_trading_config: ModConfig
var is_trade_items_over_limit: bool = false


# Extended func's
func _ready():
	var ModsConfigInterface = get_node("/root/ModLoader/dami-ModOptions/ModsConfigInterface")

	if ModsConfigInterface != null:
		ModsConfigInterface.connect("setting_changed", self, "on_coop_trading_setting_changed")
		coop_trading_config = ModLoaderConfig.get_current_config(RobocrafterLP_Trade)
		
	if coop_trading_config != null and trade_items_over_limit_config in coop_trading_config.data:
		is_trade_items_over_limit = coop_trading_config.data[trade_items_over_limit_config]


# Custom func's
func on_coop_trading_setting_changed(setting_name, value, mod_name): # Yes, func is called that because some conflicts happen here
	var config = ModLoaderConfig.get_current_config(RobocrafterLP_Trade)

	if setting_name == trade_items_over_limit_config:
		is_trade_items_over_limit = value
		if config != null:
			config.data[trade_items_over_limit_config] = value

func is_can_trade_item(object_data, player_index: int) -> bool:
	if self.is_trade_items_over_limit:
		return true

	if object_data is ItemData:
		if self.get_remaining_max_nb_item(object_data, player_index) > 0 or self.get_remaining_max_nb_item(object_data, player_index) == -1:
			return true
		else:
			return false
	else:
		return false


# --- Trade eligibility: single source of truth ---------------------------------
# Reason codes shared by the trade execution (coop_shop) and the trade UI
# (coop_item_popup), so the button state and the actual rule can never disagree.
# 0 always means "allowed".
const WTB_OK := 0
const WTB_TIER_TOO_HIGH := 1
const WTB_TIER_TOO_LOW := 2
const WTB_NO_MELEE := 3
const WTB_NO_RANGED := 4
const WTB_LOCKED := 5
const WTB_NO_DUPLICATE := 6
const WTB_NO_SLOT := 7
const WTB_CANT_MERGE := 8

const ITB_OK := 0
const ITB_NOT_TRADEABLE := 1
const ITB_AT_LIMIT := 2

# item_tumor (Primal Dread) collects its owner's mutation effects; a second one on the receiver
# would never grow, and the sender would lose everything it had absorbed.
const NON_TRADEABLE_ITEM_IDS := ["item_celery_tea", "item_lure", "item_peacock", "item_tumor"]

const _TRADE_REFUSED_SOUNDS := [
	preload("res://entities/units/unit/hurt_sounds/punch_general_body_impact_01.wav"),
	preload("res://entities/units/unit/hurt_sounds/punch_general_body_impact_02.wav"),
	preload("res://entities/units/unit/hurt_sounds/punch_general_body_impact_03.wav"),
	preload("res://entities/units/unit/hurt_sounds/punch_general_body_impact_04.wav"),
]

# Feedback when a trade is refused. The old Player.new().hurt_sounds was always null (those sounds
# are assigned in player.tscn, not the script) and leaked an orphan Player node on every refusal.
func play_trade_refused_sound() -> void:
	SoundManager.play(Utils.get_rand_element(_TRADE_REFUSED_SOUNDS), 0, 0.0, true)

# Mirrors the game's shop_items_container._can_weapon_be_bought, but returns WHY a
# weapon can't go to player_index (WTB_OK if it can). Same rule order as the game.
func get_weapon_trade_block_reason(weapon_data: WeaponData, player_index: int) -> int:
	var min_weapon_tier = get_player_effect(Keys.min_weapon_tier_hash, player_index)
	var max_weapon_tier = get_player_effect(Keys.max_weapon_tier_hash, player_index)
	var no_melee_weapons = get_player_effect_bool(Keys.no_melee_weapons_hash, player_index)
	var no_ranged_weapons = get_player_effect_bool(Keys.no_ranged_weapons_hash, player_index)
	var no_duplicate_weapons = get_player_effect_bool(Keys.no_duplicate_weapons_hash, player_index)
	var lock_current_weapons = get_player_effect_bool(Keys.lock_current_weapons_hash, player_index)

	var weapon_type = weapon_data.type
	var weapon_slot_available: bool = has_weapon_slot_available(weapon_data, player_index)

	# Same as vanilla since Primal Dread: only a flavor-compatible copy can absorb the weapon (meca,
	# mutant and cursed versions don't merge). buy_weapon silently drops a weapon that can't merge,
	# so a looser check here lost the traded weapon.
	var player_has_weapon: bool = get_combine_candidates(weapon_data, player_index).size() > 0

	var player_has_weapon_family: bool = weapon_data.weapon_id in get_unique_weapon_ids(player_index)

	if weapon_data.tier > max_weapon_tier:
		return WTB_TIER_TOO_HIGH
	if weapon_data.tier < min_weapon_tier:
		return WTB_TIER_TOO_LOW
	if no_melee_weapons and weapon_type == WeaponType.MELEE:
		return WTB_NO_MELEE
	if no_ranged_weapons and weapon_type == WeaponType.RANGED:
		return WTB_NO_RANGED
	if lock_current_weapons and not weapon_slot_available:
		return WTB_LOCKED
	# Inventory full but the weapon will combine into an upgrade the receiver owns: allowed.
	if player_has_weapon and not weapon_slot_available and weapon_data.upgrades_into != null and weapon_data.upgrades_into.tier <= max_weapon_tier:
		return WTB_OK
	if no_duplicate_weapons and player_has_weapon_family:
		return WTB_NO_DUPLICATE
	if not weapon_slot_available:
		# They own the weapon, but that copy can't take it (incompatible flavor or max tier).
		for weapon in get_player_weapons(player_index):
			if weapon.my_id == weapon_data.my_id:
				return WTB_CANT_MERGE
		return WTB_NO_SLOT
	return WTB_OK

# Why an item can't go to player_index (ITB_OK if it can).
func get_item_trade_block_reason(item_data, player_index: int) -> int:
	if item_data == null or not (item_data is ItemData):
		return ITB_NOT_TRADEABLE
	if NON_TRADEABLE_ITEM_IDS.has(item_data.my_id):
		return ITB_NOT_TRADEABLE
	if is_can_trade_item(item_data, player_index):
		return ITB_OK
	return ITB_AT_LIMIT
