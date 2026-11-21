extends SceneTree
func _init():
	var main = load('res://scenes/Main.tscn').instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	print('main_menu size:', main.main_menu.size)
	print('main_menu pos:', main.main_menu.position)
	print('main_menu visible:', main.main_menu.visible)
	print('global_bg size:', main.main_menu.global_bg.size if main.main_menu.global_bg else 'NULL')
	print('global_bg tex:', main.main_menu.global_bg.texture != null if main.main_menu.global_bg else 'NULL')
	print('title_panel size:', main.main_menu.title_panel.size if main.main_menu.title_panel else 'NULL')
	print('title_panel vis:', main.main_menu.title_panel.visible if main.main_menu.title_panel else 'NULL')
	quit()
