extends SceneTree

func _init():
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	
	# Wait for engine _ready() to complete
	await process_frame
	await process_frame
	
	print("--- CALLING CONFIRM AND START MATCH ---")
	main.main_menu._confirm_and_start_match()
	
	await process_frame
	await process_frame
	
	var hud = main.get_node("HUD")
	print("--- HUD NODES IN MATCH ---")
	print("HUD visible: ", hud.visible, " layer: ", hud.layer)
	for c in hud.get_children():
		if c is Control:
			print("Control: ", c.name, " visible: ", c.visible, " is_visible_in_tree: ", c.is_visible_in_tree(), " size: ", c.size, " pos: ", c.position, " z_index: ", c.z_index)
			
	var img = root.get_viewport().get_texture().get_image()
	if img:
		img.save_png("debug_match_hud_real.png")
		print("Saved debug_match_hud_real.png, size: ", img.get_size())
	quit()
