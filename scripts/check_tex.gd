extends SceneTree
func _init():
	var tex = load('res://assets/ui/scoreboard_bwf_base.png')
	var img = tex.get_image()
	print('img size:', img.get_size())
	print('c_tl:', img.get_pixel(0, 0))
	print('c_tr:', img.get_pixel(img.get_width()-1, 0))
	print('c_bl:', img.get_pixel(0, img.get_height()-1))
	print('c_br:', img.get_pixel(img.get_width()-1, img.get_height()-1))
	quit()
