extends SceneTree

func _init() -> void:
	print("--- TESTING GAUGES & SCOREBOARD SYNC ---")
	var sb_scene = load("res://scenes/BWFScoreboard.tscn")
	assert(sb_scene != null, "BWFScoreboard.tscn must load")
	var sb = sb_scene.instantiate()
	root.add_child(sb)
	
	assert(sb.get_node("Gauges/P1_Gauges/Stamina_BG/Stamina_Fill") != null, "P1 Stamina Fill must exist")
	assert(sb.get_node("Gauges/P1_Gauges/Accuracy_BG/Accuracy_Fill") != null, "P1 Accuracy Fill must exist")
	assert(sb.get_node("Gauges/P1_Gauges/Flow_BG/Flow_Fill") != null, "P1 Flow Fill must exist")
	assert(sb.get_node("Gauges/P2_Gauges/Stamina_BG/Stamina_Fill") != null, "P2 Stamina Fill must exist")
	assert(sb.get_node("Gauges/P2_Gauges/Accuracy_BG/Accuracy_Fill") != null, "P2 Accuracy Fill must exist")
	assert(sb.get_node("Gauges/P2_Gauges/Flow_BG/Flow_Fill") != null, "P2 Flow Fill must exist")
	print("All gauge nodes verified in BWFScoreboard scene!")
	
	# Test update_gauges with dummy dictionary
	var dummy_stats = {
		"stamina": 80.0,
		"max_stamina_cap": 95.0,
		"accuracy": 75.0,
		"flow": 60.0
	}
	sb.update_gauges(dummy_stats, dummy_stats)
	assert(sb.p1_stamina_fill.size.x == 140.0 * 0.8, "Stamina fill width must match")
	print("update_gauges executed successfully!")
	
	sb.queue_free()
	
	print("ALL TESTS PASSED WITH ZERO ERRORS!")
	quit(0)
