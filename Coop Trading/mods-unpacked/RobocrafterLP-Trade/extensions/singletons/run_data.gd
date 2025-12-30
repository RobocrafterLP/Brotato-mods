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
