extends SceneTree
func _init():
	ProjectSettings.load_resource_pack('res://scratch/downloaded_index.pck')
	var f = FileAccess.open('res://scripts/main.gd', FileAccess.READ)
	if f:
		var txt = f.get_as_text()
		print('Contains MainMenuController:', txt.find('MainMenuController') != -1)
		print('Contains _set_in_game_hud_visible(false):', txt.find('_set_in_game_hud_visible(false)') != -1)
		print('Contains TITLE:', txt.find('MenuState.TITLE') != -1)
	quit()
