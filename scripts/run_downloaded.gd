extends SceneTree
func _init():
	ProjectSettings.load_resource_pack('res://scratch/downloaded_index.pck')
	var main = load('res://scenes/Main.tscn').instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	print('--- LOADED FROM PCK ---')
	print('main_menu:', main.main_menu)
	print('main_menu visible:', main.main_menu.visible if main.main_menu else 'NULL')
	print('bwf_scoreboard visible:', main.bwf_scoreboard.visible if main.bwf_scoreboard else 'NULL')
	print('btn_char_select visible:', main.btn_char_select.visible if main.btn_char_select else 'NULL')
	print('label_banner visible:', main.label_banner.visible if main.label_banner else 'NULL')
	quit()
