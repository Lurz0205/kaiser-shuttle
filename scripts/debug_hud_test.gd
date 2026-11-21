extends SceneTree

func _init():
	change_scene_to_file("res://scenes/Main.tscn")
	create_timer(0.2).timeout.connect(_on_timer)

func _on_timer():
	var main_scene = current_scene
	print("--- AFTER SCENE LOAD ---")
	var hud = main_scene.get_node("HUD")
	print("HUD visible: ", hud.visible)
	print("MainMenu visible: ", main_scene.main_menu.visible if main_scene.main_menu else "None")
	print("BWF visible: ", main_scene.bwf_scoreboard.visible if main_scene.bwf_scoreboard else "None")
	
	print("--- CALLING _on_menu_start_match ---")
	main_scene._on_menu_start_match("nishikawa", "wall", 1, 11, 1)
	print("MainMenu visible: ", main_scene.main_menu.visible if main_scene.main_menu else "None")
	print("BWF visible: ", main_scene.bwf_scoreboard.visible if main_scene.bwf_scoreboard else "None")
	print("BWF pos: ", main_scene.bwf_scoreboard.position, " size: ", main_scene.bwf_scoreboard.size)
	print("StaminaPlayer visible: ", main_scene.stamina_bar_bg_player.visible if main_scene.stamina_bar_bg_player else "None")
	print("StaminaPlayer pos: ", main_scene.stamina_bar_bg_player.position, " size: ", main_scene.stamina_bar_bg_player.size)
	print("BtnSettings visible: ", main_scene.btn_settings.visible if main_scene.btn_settings else "None", " pos: ", main_scene.btn_settings.position)
	print("BtnFullscreen visible: ", main_scene.btn_fullscreen.visible if main_scene.btn_fullscreen else "None", " pos: ", main_scene.btn_fullscreen.position if main_scene.btn_fullscreen else "None")
	print("ControlsBar visible: ", main_scene.controls_bar.visible if main_scene.controls_bar else "None", " pos: ", main_scene.controls_bar.position)
	
	print("--- LISTING HUD CHILDREN ---")
	for c in hud.get_children():
		print("Child: ", c.name, " (", c.get_class(), ") visible=", c.visible if "visible" in c else "n/a", " z_index=", c.z_index if "z_index" in c else "n/a")
	quit()
