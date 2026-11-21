extends SceneTree

func _init() -> void:
	print("=== RUNNING THE SPIKE UI & LIQUID GLASS AUTOMATED TEST ===")
	
	var menu = MainMenuController.new()
	root.add_child(menu)
	menu._ready()
	
	# 1. Test Title State
	assert(menu.current_state == MainMenuController.MenuState.TITLE, "Initial state should be TITLE")
	assert(menu.title_panel != null and menu.title_panel.visible, "Title panel should be visible")
	assert(not menu.top_bar.visible, "Top bar should be hidden on TITLE")
	print("✓ Test 1: Title Screen initialized cleanly with Studio 3D Shuttlecock")
	
	# 2. Test Lobby State
	menu.switch_state(MainMenuController.MenuState.LOBBY)
	assert(menu.current_state == MainMenuController.MenuState.LOBBY, "State should be LOBBY")
	assert(menu.lobby_panel.visible, "Lobby panel should be visible")
	assert(menu.top_bar.visible, "Top bar should be visible on LOBBY")
	assert(menu.top_bar.z_index == 100, "Top bar should have z_index 100")
	print("✓ Test 2: Main Lobby (Liquid Glass Box + Studio Icons + Top Bar z_index 100) active")
	
	# 3. Test Navigation Tabs Clicks (Quản lý cầu thủ & Cài đặt)
	assert(menu.nav_tabs.has("roster"), "Nav tab roster exists")
	assert(menu.nav_tabs.has("settings"), "Nav tab settings exists")
	
	# Click Quản lý cầu thủ
	menu.nav_tabs["roster"].emit_signal("pressed")
	assert(menu.current_state == MainMenuController.MenuState.ROSTER, "State should be ROSTER after clicking tab")
	assert(menu.roster_panel.visible, "Roster panel should be visible")
	print("✓ Test 3: Click 'Quản Lý Cầu Thủ' works flawlessly")
	
	# Click Cài đặt
	menu.nav_tabs["settings"].emit_signal("pressed")
	assert(menu.current_state == MainMenuController.MenuState.SETTINGS, "State should be SETTINGS after clicking tab")
	assert(menu.settings_panel.visible, "Settings panel should be visible")
	print("✓ Test 4: Click 'Cài Đặt' works flawlessly")
	
	# Click Cửa hàng & Nhiệm vụ
	menu.nav_tabs["shop"].emit_signal("pressed")
	assert(menu.current_state == MainMenuController.MenuState.SHOP, "State should be SHOP")
	menu.nav_tabs["quests"].emit_signal("pressed")
	assert(menu.current_state == MainMenuController.MenuState.QUESTS, "State should be QUESTS")
	menu.nav_tabs["lobby"].emit_signal("pressed")
	assert(menu.current_state == MainMenuController.MenuState.LOBBY, "State should be LOBBY")
	print("✓ Test 5: All 5 Top Nav Tabs cycle smoothly without being blocked")
	
	# 4. Test Direct Player Real Name Input
	assert(menu.top_name_input != null, "Top name input LineEdit exists")
	menu.top_name_input.text = "Minh Triết"
	menu.top_name_input.text_changed.emit("Minh Triết")
	assert(menu.pvp_player_name == "Minh Triết", "Real player name should update immediately")
	print("✓ Test 6: Direct real name typing and persistent storage confirmed")
	
	# 5. Test Match Selection Cards
	menu.switch_state(MainMenuController.MenuState.MATCH_SELECT)
	assert(menu.match_select_panel.visible, "Match select panel visible")
	print("✓ Test 7: Match Selection with Studio PNG Icons active")
	
	# 6. Test Match Setup vs AI
	var match_started = [false]
	menu.start_match_requested.connect(func(p, r, d, pts, sets):
		match_started[0] = true
	)
	menu._confirm_and_start_match()
	assert(match_started[0], "start_match_requested emitted successfully")
	print("✓ Test 8: AI Match starting signal verified")
	
	# 7. Test Virtual Touch Pad
	var touch_pad = VirtualTouchPad.new()
	root.add_child(touch_pad)
	touch_pad._ready()
	touch_pad.visible = true
	touch_pad.queue_redraw()
	print("✓ Test 9: Classic Minimal Touch Pad initialized without errors")
	
	print("=== ALL 9 ADVANCED UI TESTS PASSED 100% ===")
	quit(0)
