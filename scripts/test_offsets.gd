extends SceneTree

func _init():
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	main._ready()
	
	main._on_menu_start_match("nishikawa", "wall", 1, 11, 1)
	
	var hud = main.get_node("HUD")
	var sb = main.bwf_scoreboard
	print("sb size: ", sb.size, " pos: ", sb.position, " global_pos: ", sb.global_position)
	print("sb offset: ", sb.offset_left, ", ", sb.offset_top, ", ", sb.offset_right, ", ", sb.offset_bottom)
	print("sb anchors: ", sb.anchor_left, ", ", sb.anchor_top, ", ", sb.anchor_right, ", ", sb.anchor_bottom)
	
	var btn_b = main.btn_back_to_lobby
	print("btn_back size: ", btn_b.size, " pos: ", btn_b.position, " global_pos: ", btn_b.global_position)
	
	var cbar = main.controls_bar
	print("cbar size: ", cbar.size, " pos: ", cbar.position, " global_pos: ", cbar.global_position)
	quit()
