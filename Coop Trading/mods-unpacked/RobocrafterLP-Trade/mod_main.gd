extends Node

const RobocrafterLP_Trade_ID = "RobocrafterLP-Trade"
const RobocrafterLP_Trade_DIR := RobocrafterLP_Trade_ID
const RobocrafterLP_Trade_LOG_NAME := RobocrafterLP_Trade_ID + ":Main"

var mod_dir_path := ""
var extensions_dir_path := ""
var translations_dir_path := ""


# Extended func's
func _init() -> void:
	mod_dir_path = ModLoaderMod.get_unpacked_dir().plus_file(RobocrafterLP_Trade_DIR)
	install_script_extensions()
	add_translations()

func _ready() -> void:
	ModLoaderLog.info("Ready!", RobocrafterLP_Trade_LOG_NAME)	
	_config(RobocrafterLP_Trade_ID, RobocrafterLP_Trade_LOG_NAME)


# Custom func's
func install_script_extensions() -> void:
	extensions_dir_path = mod_dir_path.plus_file("extensions")

	var extensions = [
		"singletons/run_data.gd",
		"singletons/debug_service.gd",
		"ui/menus/shop/coop_item_popup.gd"
	]

	for extension in extensions:
		ModLoaderMod.install_script_extension(extensions_dir_path.plus_file(extension))

func add_translations() -> void:
	translations_dir_path = mod_dir_path.plus_file("translations")

	var translations = [
		"en",
		"de",
		"ru"
	]

	for translation in translations:
		ModLoaderMod.add_translation(translations_dir_path.plus_file("RobocrafterLP-Trade.%s.translation" % translation))

func _config(mod_id: String, mod_log: String)-> void: # Defaults for Mods Options
	var data = ModLoaderStore.mod_data[mod_id]
	
	if data != null:
		var version = data.manifest.version_number
		ModLoaderLog.info("Current Version is %s." % version, mod_log)
		var config = ModLoaderConfig.get_config(mod_id, version)
	
		if config == null:
			var defaultConfig = ModLoaderConfig.get_default_config(mod_id)
			if defaultConfig != null:
				config = ModLoaderConfig.create_config(mod_id, version, defaultConfig.data)
			else:
				config = ModLoaderConfig.create_config(mod_id, version, {})
			
		if config != null and ModLoaderConfig.get_current_config_name(mod_id) != version:
			ModLoaderConfig.set_current_config(config)
			if config.is_valid():
				config.save_to_file()
				ModLoaderLog.info("Save config to : %s" % config.save_path, mod_log)
