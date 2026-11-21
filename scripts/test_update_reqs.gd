extends SceneTree

func _init():
	_run()

func _run():
	print("=== RUNNING VERIFICATION FOR 3 USER REQUIREMENTS ===")
	
	# 1. Test High Graphics Mode Default
	var MainMenuController = load("res://scripts/ui/main_menu_controller.gd")
	var menu = MainMenuController.new()
	root.add_child(menu)
	menu._ready()
	assert(menu.low_graphics_mode == false, "MainMenuController must default to high graphics mode (low_graphics_mode = false)")
	print("✓ Req 1.1: MainMenuController defaults to High Graphics")
	
	var main_scene = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame
	await process_frame
	assert(main_scene.low_graphics_mode == false, "Main scene must default to high graphics mode (low_graphics_mode = false)")
	print("✓ Req 1.2: Main scene defaults to High Graphics")
	
	var shuttle = main_scene.shuttlecock
	assert(shuttle != null, "Shuttlecock must exist")
	assert(shuttle.low_graphics_mode == false, "Shuttlecock must default to high graphics mode (low_graphics_mode = false)")
	print("✓ Req 1.3: Shuttlecock defaults to High Graphics")
	
	# 2. Test Player Name Persistence Only
	menu._save_player_name("KAISER_CHAMPION")
	var loaded_name = menu._load_saved_player_name()
	assert(loaded_name == "KAISER_CHAMPION", "Player name must persist")
	
	menu._save_selected_avatar(3)
	menu._load_selected_avatar()
	assert(menu.current_avatar_idx == 0, "Avatar should NOT be persisted to disk/localStorage (only name)")
	print("✓ Req 2: Only player name is persisted, avatar/other state not persisted")
	
	# 3. Test Scoreboard: Square corners & Bold names
	var scoreboard = load("res://scenes/BWFScoreboard.tscn").instantiate()
	root.add_child(scoreboard)
	await process_frame
	
	assert(scoreboard.name_p1 != null, "name_p1 must exist")
	assert(scoreboard.name_p2 != null, "name_p2 must exist")
	
	scoreboard.set_players("MOMOTA", "AXELSEN")
	assert(scoreboard.name_p1.text == "MOMOTA", "P1 name set")
	assert(scoreboard.name_p2.text == "AXELSEN", "P2 name set")
	
	var font_p1 = scoreboard.name_p1.get_theme_font("font")
	assert(font_p1 is SystemFont, "P1 name font must be a SystemFont")
	assert(font_p1.font_weight == 700, "P1 name must have font_weight = 700 (Bold)")
	
	var font_p2 = scoreboard.name_p2.get_theme_font("font")
	assert(font_p2 is SystemFont, "P2 name font must be a SystemFont")
	assert(font_p2.font_weight == 700, "P2 name must have font_weight = 700 (Bold)")
	print("✓ Req 3.1: BWFScoreboard player names have font_weight = 700 (Bold)")
	
	var base_tex = scoreboard.get_node("BaseTexture").texture
	assert(base_tex != null, "BaseTexture must have texture")
	var img = base_tex.get_image()
	assert(img != null, "Image must be accessible")
	# Check corners alpha
	var c_tl = img.get_pixel(0, 0).a
	var c_tr = img.get_pixel(img.get_width() - 1, 0).a
	var c_bl = img.get_pixel(0, img.get_height() - 1).a
	var c_br = img.get_pixel(img.get_width() - 1, img.get_height() - 1).a
	assert(c_tl > 0.99 and c_tr > 0.99 and c_bl > 0.99 and c_br > 0.99, "Scoreboard corners must be solid square (no rounded corners)")
	print("✓ Req 3.2: Scoreboard texture has completely square corners (alpha=1.0 at all 4 corners)")
	
	print("=== ALL 3 REQUIREMENTS SUCCESSFULLY VERIFIED 100% ===")
	quit()
