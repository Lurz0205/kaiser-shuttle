extends SceneTree
func _init():
	var success = ProjectSettings.load_resource_pack('res://scratch/downloaded_index.pck')
	print('Load PCK success:', success)
	print('main.gd exists:', FileAccess.file_exists('res://scripts/main.gd'))
	print('main_menu_controller.gd exists:', FileAccess.file_exists('res://scripts/ui/main_menu_controller.gd'))
	quit()
