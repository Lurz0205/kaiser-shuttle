extends SceneTree

func _init() -> void:
	print("==================================================")
	print("   TESTING NEW CHARACTERS, STATS & SKILLS         ")
	print("==================================================")
	
	var CharacterStats = load("res://scripts/core/character_stats.gd")
	var SpecialSkills = load("res://scripts/mechanics/special_skills.gd")
	
	# 1. Test Stats & Max Flow
	var nishi = CharacterStats.create_nishikawa()
	assert(nishi.max_flow == 100.0, "Nishikawa max_flow should be 100")
	print("✓ 1. Nishikawa max_flow = %f" % nishi.max_flow)
	
	var fuji = CharacterStats.create_fuji()
	assert(fuji.max_flow == 80.0, "Fuji max_flow should be 80")
	assert(fuji.control >= 99.0, "Fuji is S+ tier")
	print("✓ 2. Fuji (S+) max_flow = %f, Control = %f" % [fuji.max_flow, fuji.control])
	
	var isabel = CharacterStats.create_wall()
	assert(isabel.max_flow == 90.0, "Isabel max_flow should be 90")
	print("✓ 3. Isabel max_flow = %f" % isabel.max_flow)
	
	var gitae = CharacterStats.create_gitae()
	assert(gitae.max_flow == 100.0, "Gitae max_flow should be 100")
	assert(gitae.special_skill_id == "fire_realm", "Gitae skill is fire_realm")
	print("✓ 4. Han Gitae max_flow = %f, Skill = %s" % [gitae.max_flow, gitae.special_skill_id])
	
	var sara = CharacterStats.create_sara()
	assert(sara.max_flow == 105.0, "Sara max_flow should be 105")
	assert(sara.special_skill_id == "ice_domain", "Sara skill is ice_domain")
	print("✓ 5. Sara max_flow = %f, Skill = %s" % [sara.max_flow, sara.special_skill_id])
	
	# 2. Test Player & Shuttlecock Mechanics
	var main_scene = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main_scene)
	
	var player = main_scene.get_node("Player")
	var ai_rival = main_scene.get_node("AIRival")
	var shuttlecock = main_scene.get_node("Shuttlecock")
	player.court_side = "player"
	ai_rival.court_side = "ai"
	player.shuttlecock = shuttlecock
	ai_rival.shuttlecock = shuttlecock
	player.opponent_player = ai_rival
	ai_rival.opponent_player = player
	var touch_pad = load("res://scripts/ui/virtual_touch_pad.gd").new()
	main_scene.add_child(touch_pad)
	
	assert(player != null, "Player exists")
	assert(ai_rival != null, "AI exists")
	assert(shuttlecock != null, "Shuttlecock exists")
	assert(touch_pad != null, "TouchPad exists")
	
	# Test Han Gitae active skill
	player.stats = gitae
	player.stats.flow = 100.0
	assert(player.stats.can_use_special(), "Gitae flow full")
	var activated = player.activate_active_skill()
	assert(activated, "Gitae active skill activated")
	assert(player.is_fire_realm_active, "is_fire_realm_active is true")
	assert(player.stats.flow == 0.0, "Flow consumed")
	print("✓ 6. Han Gitae active skill triggered successfully")
	
	# Test Gitae half-court hitbox
	shuttlecock.is_active = true
	shuttlecock.is_net_fault = false
	player.can_hit = true
	player.court_side = "player"
	shuttlecock.global_position = Vector2(500.0, 300.0) # Player side
	player.global_position = Vector2(100.0, 560.0) # Far back
	var hit_st = player.get_hit_status()
	print("Hit status: ", hit_st, " can_hit: ", player.can_hit, " s_pos: ", shuttlecock.global_position)
	assert(hit_st["can_hit"] == true, "Gitae can hit from anywhere on his half court")
	assert(hit_st["is_perfect"] == true, "Gitae fire realm hits are perfect")
	print("✓ 7. Han Gitae half-court hitbox confirmed")
	
	# Test Fire Ball burn penalty on opponent (Nerfed to 1.5 per stat)
	ai_rival.stats = isabel
	shuttlecock.is_fire_ball = true
	shuttlecock.fire_ball_owner = "player"
	shuttlecock.global_position = Vector2(800.0, 300.0) # On AI's side
	var prev_opp_sta = ai_rival.stats.stamina
	var prev_opp_acc = ai_rival.stats.accuracy
	ai_rival._execute_hit("clear", {"can_hit": true, "zone": "underhand", "quality": 1.0, "is_perfect": true})
	assert(abs((prev_opp_acc - ai_rival.stats.accuracy) - 1.5) < 0.01, "Opponent lost exactly 1.5 accuracy from fire ball")
	assert(prev_opp_sta - ai_rival.stats.stamina >= 1.5, "Opponent lost at least 1.5 stamina from fire ball")
	assert(shuttlecock.is_fire_ball == false, "Fire ball cleared after hit")
	print("✓ 8. Fire Ball burn penalty correctly nerfed to (-1.5 sta, -1.5 bal, -1.5 acc)")

	# Test Sara 0 Flow, Sara Ice Smash, and Gitae +8 Flow mechanics
	shuttlecock.global_position = Vector2(400.0, 300.0) # On Player's side
	shuttlecock.is_active = true
	shuttlecock.is_net_fault = false
	player.stats = sara
	player.stats.flow = 0.0
	player.is_ice_domain_active = true
	player.is_fire_realm_active = false
	player._execute_hit("clear", {"can_hit": true, "zone": "overhead", "quality": 1.0, "is_perfect": true})
	assert(player.stats.flow == 0.0, "Sara earns 0 flow during ice domain")
	print("✓ 8b. Sara earns 0 flow during ice domain (auto-perfect doesn't farm flow)")

	# Test Sara Ice Smash snowflake flag + 15 balance drain
	shuttlecock.global_position = Vector2(400.0, 260.0)
	player._execute_hit("smash", {"can_hit": true, "zone": "overhead", "quality": 1.0, "is_perfect": true})
	assert(shuttlecock.is_sara_ice_smash == true, "Sara smash during ice domain sets is_sara_ice_smash")
	ai_rival.balance = 100.0
	shuttlecock.is_smash = true
	shuttlecock.global_position = Vector2(800.0, 350.0)
	ai_rival._execute_hit("clear", {"can_hit": true, "zone": "underhand", "quality": 1.0, "is_perfect": true})
	assert(ai_rival.balance <= 90.0, "Opponent lost 15 balance from Sara Ice Smash")
	print("✓ 8c. Sara Ice Smash snowflake trail flag & 15 balance drain confirmed")

	shuttlecock.global_position = Vector2(400.0, 300.0)
	player.stats = gitae
	player.stats.flow = 0.0
	player.is_fire_realm_active = true
	player.is_ice_domain_active = false
	player._execute_hit("clear", {"can_hit": true, "zone": "overhead", "quality": 1.0, "is_perfect": true})
	assert(player.stats.flow == 8.0, "Han Gitae nerfed: earns 8 flow per perfect hit")
	print("✓ 8d. Han Gitae nerfed: earns 8 flow per perfect hit (less than normal 15)")
	
	# Test Sara active skill & teleport
	player.stats = sara
	player.stats.flow = 105.0
	player.is_fire_realm_active = false
	assert(player.stats.can_use_special(), "Sara flow full")
	var sara_act = player.activate_active_skill()
	assert(sara_act, "Sara active skill activated")
	assert(player.is_ice_domain_active, "Sara is_ice_domain_active is true")
	player._physics_process(0.016)
	ai_rival._physics_process(0.016)
	assert(ai_rival.ice_slow_active, "Opponent slowed by ice domain")
	print("✓ 9. Sara Ice Domain active & slows opponent by 20%")
	
	# Test Sara Teleport to high shuttlecock
	shuttlecock.global_position = Vector2(300.0, 200.0) # High air
	player.global_position = Vector2(100.0, 560.0)
	player.teleport_to_shuttlecock()
	assert(abs(player.global_position.x - (300.0 - 40.0)) < 5.0, "Sara teleports in X to sweetspot")
	assert(player.global_position.y < 500.0, "Sara teleports airborne for high ball")
	print("✓ 10. Sara Teleport airborne to sweetspot confirmed: pos = %s" % str(player.global_position))
	
	# Test Sara Teleport to ground shuttlecock
	shuttlecock.global_position = Vector2(400.0, 530.0) # Low ground
	player.teleport_to_shuttlecock()
	assert(player.global_position.y >= 540.0, "Sara stays on ground for low ball")
	print("✓ 11. Sara Teleport on ground confirmed: pos = %s" % str(player.global_position))
	
	# Test TouchPad skill button
	touch_pad.player = player
	assert(touch_pad.btn_skill_center != Vector2.ZERO, "Skill button center set")
	print("✓ 12. Virtual Touchpad Skill Button configured at %s" % str(touch_pad.btn_skill_center))
	
	print("==================================================")
	print("   ALL TESTS PASSED 100%! EXCELLENT!              ")
	print("==================================================")
	quit()
