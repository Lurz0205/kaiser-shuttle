extends SceneTree
func _init():
	var main = load('res://scenes/Main.tscn').instantiate()
	root.add_child(main)
	print('Frame 0:')
	_print_state(main)
	for i in range(1, 10):
		await process_frame
		print('Frame ', i, ':')
		_print_state(main)
	quit()

func _print_state(main):
	print('  main_menu: ', main.main_menu != null, ' vis: ', main.main_menu.visible if main.main_menu else false, ' state: ', main.main_menu.current_state if main.main_menu else -1)
	print('  title_panel: ', main.main_menu.title_panel.visible if (main.main_menu and main.main_menu.title_panel) else false)
	print('  bwf_scoreboard vis: ', main.bwf_scoreboard.visible if main.bwf_scoreboard else false)
	print('  btn_char_select vis: ', main.btn_char_select.visible if main.btn_char_select else false)
