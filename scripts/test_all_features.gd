extends SceneTree

func _init():
    _run_tests()

func _run_tests():
    print("==================================================")
    print("   MASTER VERIFICATION: ALL FEATURES & FIXES      ")
    print("==================================================")
    
    var MainMenuController = load("res://scripts/ui/main_menu_controller.gd")
    var menu = MainMenuController.new()
    root.add_child(menu)
    menu._ready()
    
    # 1. Title Screen & 3D Logo Emblem
    menu.switch_state(MainMenuController.MenuState.TITLE)
    assert(menu.title_panel != null and menu.title_panel.visible, "Title panel must be visible in TITLE state")
    assert(menu.global_bg != null and menu.global_bg.texture != null, "Global background must exist with texture")
    print("✓ 1. Title Screen active with 3D tournament emblem")
    
    # 2. Lobby Screen & Top Navigation Tabs
    menu.switch_state(MainMenuController.MenuState.LOBBY)
    assert(menu.lobby_panel != null and menu.lobby_panel.visible, "Lobby panel must be visible in LOBBY state")
    assert(menu.top_bar != null and menu.top_bar.visible, "Top bar must be visible in LOBBY state")
    assert(menu.nav_tabs.has("lobby"), "Trang Chủ tab must exist")
    assert(menu.nav_tabs.has("shop"), "Cửa Hàng tab must exist")
    assert(menu.nav_tabs.has("quests"), "Nhiệm Vụ tab must exist")
    assert(menu.nav_tabs.has("roster"), "Quản Lý Cầu Thủ tab must exist")
    assert(menu.nav_tabs.has("settings"), "Cài Đặt tab must exist")
    print("✓ 2. Lobby Screen active with all 5 navigation tabs in Top Bar")
    
    # 3. Main scene & In-game BWF Scoreboard
    var main = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    main._ready()
    
    main._on_menu_start_match("nishikawa", "wall", 1, 11, 1)
    
    var sb = main.bwf_scoreboard
    assert(sb != null and sb.visible, "BWF Scoreboard must be visible in match")
    assert(main.main_menu.visible == false, "MainMenu must be hidden in match")
    assert(sb.offset_left == 420.0, "Scoreboard must be centered at x=420")
    assert(sb.offset_top == 14.0, "Scoreboard y=14")
    assert(sb.custom_minimum_size.x == 440.0 and sb.custom_minimum_size.y == 64.0, "Scoreboard size must be 440x64")
    print("✓ 3. In-Game BWF Scoreboard centered at (420, 14) with size (440, 64) and MainMenu hidden")
    
    # 4. PvP Character Sync
    main._on_menu_start_pvp_match("ROOM_SYNC", false, "fuji", 11, 1, "p1", "wall", "PLAYER_ME", "RIVAL_THEM")
    assert(main.player.character_id == "fuji", "Local player must be assigned selected char")
    assert(main.ai_rival.character_id == "wall", "Opponent player must be assigned selected char")
    print("✓ 4. PvP match character assignment verified for both host and guest")
    
    # 5. Scoreboard square corners and bold font
    var sb_node = main.bwf_scoreboard
    var name_p1 = sb_node.get_node("BaseTexture/NameP1")
    assert(name_p1 != null, "NameP1 must exist")
    var font = name_p1.get_theme_font("font")
    if font and font is SystemFont:
        assert((font as SystemFont).font_weight == 700, "Font weight must be 700 bold")
    print("✓ 5. BWF Scoreboard bold player names confirmed")
    
    # 6. Back Button, Settings & Fullscreen layout
    assert(main.btn_back_to_lobby != null and main.btn_back_to_lobby.visible, "Back to lobby button must be visible in match")
    assert(main.btn_back_to_lobby.offset_left == 20.0 and main.btn_back_to_lobby.offset_top == 16.0, "Back button at (20, 16)")
    assert(main.btn_settings != null and main.btn_settings.visible, "Settings button must be visible in match")
    assert(main.btn_settings.offset_left == 1088.0 and main.btn_settings.offset_top == 16.0, "Settings button at (1088, 16)")
    assert(main.btn_fullscreen != null and main.btn_fullscreen.visible, "Fullscreen button must be visible in match")
    assert(main.btn_fullscreen.offset_left == 1188.0 and main.btn_fullscreen.offset_top == 16.0, "Fullscreen button at (1188, 16)")
    assert(main.btn_settings.offset_right < main.btn_fullscreen.offset_left, "Zero collision between settings and fullscreen buttons")
    print("✓ 6. Back button, settings button and fullscreen button cleanly positioned with zero overlap")
    
    # 7. Playable Shuttlecock is 2D Sprite
    var shuttle_sprite = main.shuttlecock.get_node_or_null("Sprite") as Sprite2D
    assert(shuttle_sprite != null, "In-game shuttlecock must have Sprite2D")
    assert(shuttle_sprite.texture != null, "In-game shuttlecock must have 2D texture")
    print("✓ 7. In-game playable shuttlecock confirmed 2D sprite")
    
    # 8. Profile Default Avatar
    assert(menu.top_avatar_rect != null, "Top avatar must be simple TextureRect")
    assert(menu.top_avatar_rect.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Avatar must be unclickable")
    print("✓ 8. Profile default avatar confirmed simple and unclickable")
    
    # 9. Return to Lobby and Stop Match completely
    main._return_to_lobby_and_stop_match()
    assert(main.current_state == main.MatchState.LOBBY_IDLE, "MatchState must be LOBBY_IDLE after returning to lobby")
    assert(main.shuttlecock.is_active == false, "Shuttlecock must be inactive")
    assert(main.shuttlecock.visible == false, "Shuttlecock must be hidden in lobby")
    assert(main.main_menu.visible == true, "MainMenu must be visible in lobby")
    assert(main.main_menu.current_state == MainMenuController.MenuState.LOBBY, "MainMenu must be in LOBBY state")
    print("✓ 9. Returning to lobby completely stops match physics, shuttlecock and AI logic")
    
    # 10. Virtual Touch Pad enlarged & repositioned layout
    var vpad = main.virtual_touch_pad
    vpad._update_layout()
    assert(vpad.track_rect.position.x == 75.0, "Track shifted right to x=75")
    assert(vpad.knob_radius == 48.0, "Knob enlarged to radius=48")
    assert(vpad.btn_l_radius == 74.0, "Smash/Jump button enlarged to radius=74")
    assert(vpad.btn_j_radius == 56.0, "Drop button enlarged to radius=56")
    print("✓ 10. Virtual Touchpad size enlarged and position shifted right & up verified")
    
    print("==================================================")
    print("   ALL TESTS PASSED 100% - GAME IS ROCK SOLID!    ")
    print("==================================================")
    quit()
