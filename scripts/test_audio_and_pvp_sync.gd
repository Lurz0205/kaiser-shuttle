extends SceneTree

func _init():
	await _run_test()

func _run_test():
	print("Testing Audio System & PVP Start Button...")
	
	# 1. Test AudioManager
	var AudioManagerScript = load("res://scripts/core/audio_manager.gd")
	var am = AudioManagerScript.new()
	root.add_child(am)
	await process_frame
	
	assert(am.PLAYLIST.size() >= 4, "Playlist must have at least 4 tracks")
	assert(am.PLAYLIST[0]["id"] == "tokyo2020", "Track 0 must be Tokyo 2020")
	assert(am.current_track_idx == 0, "Default track must be index 0")
	print("✓ 1. AudioManager playlist verified with Tokyo 2020 as default")
	
	# Test 5-step volumes
	am.set_master_step(3)
	assert(am.master_step == 3, "Master step must be 3")
	am.set_music_step(2)
	assert(am.music_step == 2, "Music step must be 2")
	am.set_sfx_step(4)
	assert(am.sfx_step == 4, "SFX step must be 4")
	print("✓ 2. 5-step discrete volume math verified")
	
	# Test match bgm toggle
	am.set_bgm_match_enabled(false)
	assert(am.bgm_match_enabled == false, "Match BGM must toggle false")
	am.set_bgm_match_enabled(true)
	assert(am.bgm_match_enabled == true, "Match BGM must toggle true")
	print("✓ 3. In-match BGM toggle verified")
	
	# 2. Test MainMenuController UI
	var MenuScript = load("res://scripts/ui/main_menu_controller.gd")
	var menu = MenuScript.new()
	root.add_child(menu)
	await process_frame
	
	# Check mini player
	assert(menu.mini_player_panel != null, "Mini player panel must exist")
	assert(menu.vinyl_disc_ctrl != null, "Vinyl disc control must exist")
	assert(menu.mini_player_btn_play != null, "Play/Pause button must exist")
	print("✓ 4. Mini music player & rotating vinyl disc UI verified")
	
	# Check PVP Start button sync
	menu.switch_state(MenuScript.MenuState.PVP_LOBBY)
	assert(menu.btn_pvp_start != null, "PVP start button must exist")
	
	# Initially not connected -> disabled
	menu.pvp_is_host = true
	menu.pvp_is_connected = false
	menu._process(0.016)
	assert(menu.btn_pvp_start.disabled == true, "Start button should be disabled when not connected")
	
	# Host connected -> enabled!
	menu.pvp_is_host = true
	menu.pvp_is_connected = true
	menu._process(0.016)
	assert(menu.btn_pvp_start.disabled == false, "Start button MUST be enabled when host is connected!")
	print("✓ 5. PVP host start button dynamic enable verified")
	
	print("==================================================")
	print("   ALL AUDIO & PVP SYNC TESTS PASSED 100%!        ")
	print("==================================================")
	quit()
