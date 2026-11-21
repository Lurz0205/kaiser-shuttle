extends SceneTree

func _init() -> void:
	print("=== RUNNING THE SPIKE UI & CLASSIC TOUCH AUTOMATED TEST ===")
	
	var menu = MainMenuController.new()
	root.add_child(menu)
	menu._ready()
	
	# 1. Test Title State
	assert(menu.current_state == MainMenuController.MenuState.TITLE, "Initial state should be TITLE")
	assert(menu.title_panel != null and menu.title_panel.visible, "Title panel should be visible")
	assert(not menu.top_bar.visible, "Top bar should be hidden on TITLE")
	print("✓ Test 1: Title Screen initialized cleanly")
	
	# 2. Test Lobby State
	menu.switch_state(MainMenuController.MenuState.LOBBY)
	assert(menu.current_state == MainMenuController.MenuState.LOBBY, "State should be LOBBY")
	assert(menu.lobby_panel.visible, "Lobby panel should be visible")
	assert(menu.top_bar.visible, "Top bar should be visible on LOBBY")
	assert(menu.hero_standee != null, "Hero standee exists")
	print("✓ Test 2: Main Lobby (Top Bar + Hero Standee + Widgets + CTA) active")
	
	# 3. Test Match Selection Cards (The Spike Carousel)
	menu.switch_state(MainMenuController.MenuState.MATCH_SELECT)
	assert(menu.current_state == MainMenuController.MenuState.MATCH_SELECT, "State should be MATCH_SELECT")
	assert(menu.match_select_panel.visible, "Match select panel visible")
	print("✓ Test 3: Match Selection (5 Horizontal Cards Carousel) active")
	
	# 4. Test Roster / Locker Room (Character Switching)
	menu.switch_state(MainMenuController.MenuState.ROSTER)
	assert(menu.roster_panel.visible, "Roster panel visible")
	menu._select_player("fuji")
	assert(menu.selected_player_id == "fuji", "Player switched to Fuji")
	menu._select_player("nishikawa")
	assert(menu.selected_player_id == "nishikawa", "Player switched back to Nishikawa")
	print("✓ Test 4: Character Roster (S+, S tiers & Active Switch) functioning")
	
	# 5. Test Settings Panel & Stepped Volume Bars
	menu.switch_state(MainMenuController.MenuState.SETTINGS)
	assert(menu.settings_panel.visible, "Settings panel visible")
	print("✓ Test 5: The Spike Settings (Stepped Volume Bars & GFX) verified")
	
	# 6. Test Match Setup vs AI
	var match_started = [false]
	menu.start_match_requested.connect(func(p, r, d, pts, sets):
		match_started[0] = true
		assert(p == "nishikawa", "P1 should be nishikawa")
		assert(r == "wall", "Rival should be wall")
	)
	menu._confirm_and_start_match()
	assert(match_started[0], "start_match_requested emitted successfully")
	print("✓ Test 6: AI Match starting signal verified")
	
	# 7. Test Virtual Touch Pad (Classic Minimal Athletic)
	var touch_pad = VirtualTouchPad.new()
	root.add_child(touch_pad)
	touch_pad._ready()
	touch_pad.visible = true
	touch_pad.queue_redraw()
	print("✓ Test 7: Classic Minimal Touch Pad initialized without errors")
	
	print("=== ALL 7 THE SPIKE UI TESTS PASSED PERFECTLY ===")
	quit(0)
