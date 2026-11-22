extends SceneTree

func _init():
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	main._ready()
	print("main is_visible_in_tree: ", main.is_visible_in_tree())
	var hud = main.get_node("HUD")
	print("hud class: ", hud.get_class())
	var sb = hud.get_node("BWFScoreboard")
	print("sb parent: ", sb.get_parent().name)
	print("sb is_visible_in_tree: ", sb.is_visible_in_tree())
	quit()
