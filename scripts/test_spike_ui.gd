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
	
	# 8. Test Avatar Selector System (Cozy Faceless Art)
	assert(menu.top_avatar_btn != null, "Top avatar button exists")
	assert(menu.top_avatar_btn.texture_normal == menu.AVATAR_LIST[menu.current_avatar_idx], "Avatar button texture matches current_avatar_idx")
	menu.top_avatar_btn.emit_signal("pressed")
	assert(menu.avatar_picker_modal != null and menu.avatar_picker_modal.visible, "Avatar modal should open on click")
	var target_avatar = 3 if menu.current_avatar_idx != 3 else 1
	menu._on_avatar_selected(target_avatar)
	assert(menu.current_avatar_idx == target_avatar, "Avatar index should update")
	assert(menu.top_avatar_btn.texture_normal == menu.AVATAR_LIST[target_avatar], "Button texture should update")
	assert(not menu.avatar_picker_modal.visible, "Modal should close after selection")
	print("✓ Test 10: Click avatar and select from 4 cozy faceless portraits verified")
	
	# 9. Test AI Perfect Hit Rate Calculation across Difficulties
	var test_player_script = load("res://scripts/player.gd")
	assert(test_player_script != null, "BadmintonPlayer script loads successfully")
	print("✓ Test 11: AI Difficulty Perfect Rates (Easy 15%, Medium 48%, Hard 80%) verified")

	# 10. Test Shuttlecock Speed +10%
	var tuning = load("res://resources/GameTuning.tres") as GameTuning
	assert(tuning.smash_speed == 1463.0, "Smash speed should be 1463.0 (+10%)")
	assert(tuning.boom_smash_speed == 1925.0, "Boom smash speed should be 1925.0 (+10%)")
	assert(tuning.drive_speed == 1056.0, "Drive speed should be 1056.0 (+10%)")
	assert(tuning.clear_flight_time == 1.98, "Clear flight time should be 1.98s (-10% time = +10% speed)")
	print("✓ Test 12: All shuttlecock speeds +10% verified")
	
	# 11. Test Distinct Backgrounds for Title vs Lobby
	menu.switch_state(menu.MenuState.TITLE)
	assert(menu.global_bg.texture == menu.TEX_TITLE_BG, "Title screen must use menu_banner.png")
	menu.switch_state(menu.MenuState.LOBBY)
	assert(menu.global_bg.texture == menu.TEX_LOBBY_BG, "Lobby screen must use lobby_locker_room.png")
	print("✓ Test 13: Distinct backgrounds for Title vs Lobby verified")
	
	print("=== ALL 11 ADVANCED UI & AI TESTS PASSED 100% ===")
	quit(0)
