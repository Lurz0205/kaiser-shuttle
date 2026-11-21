extends SceneTree
func _init():
	var btn = Button.new()
	root.add_child(btn)
	print('btn is BaseButton:', btn is BaseButton)
	print('has release_focus:', btn.has_method('release_focus'))
	print('connecting...')
	btn.pressed.connect(btn.release_focus)
	print('connected!')
	print('is_connected:', btn.pressed.is_connected(btn.release_focus))
	quit()
