extends SceneTree

func _init():
	change_scene_to_file("res://scenes/Main.tscn")
	create_timer(0.2).timeout.connect(_on_timer)

func _on_timer():
	var main_scene = current_scene
	var cb = main_scene.get_node("HUD/ControlsBar")
	var bs = main_scene.get_node("HUD/BtnSettings")
	var bwf = main_scene.bwf_scoreboard
	print("ControlsBar preset:", cb.anchors_preset, "anchor_left:", cb.anchor_left, "anchor_top:", cb.anchor_top)
	print("BtnSettings preset:", bs.anchors_preset, "anchor_left:", bs.anchor_left, "anchor_top:", bs.anchor_top)
	print("Before _set_in_game_hud_visible:")
	print("  cb pos:", cb.position, "global_pos:", cb.global_position)
	print("  bs pos:", bs.position, "global_pos:", bs.global_position)
	
	main_scene._set_in_game_hud_visible(true)
	
	print("After _set_in_game_hud_visible:")
	print("  cb pos:", cb.position, "global_pos:", cb.global_position, "visible:", cb.visible)
	print("  bs pos:", bs.position, "global_pos:", bs.global_position, "visible:", bs.visible)
	print("  bwf pos:", bwf.position, "global_pos:", bwf.global_position, "visible:", bwf.visible)
	quit()
