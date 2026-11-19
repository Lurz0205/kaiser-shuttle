class_name PvPNetworkManager
extends Node

signal connection_status_changed(status: String)
signal peer_connected(is_host: bool, room_code: String)
signal peer_disconnected(reason: String)
signal packet_received(data: Dictionary)
signal ping_updated(ping_ms: int)

var is_active: bool = false
var is_host: bool = false
var current_room: String = ""
var last_status: String = "idle"
var current_ping: int = 0
var status_poll_timer: float = 0.0

# Desktop / Mock test support
var is_mock_mode: bool = false
var mock_connected: bool = false

func _ready() -> void:
	process_physics_priority = -100

func _physics_process(delta: float) -> void:
	if not is_active:
		return

	if OS.has_feature("web"):
		_poll_web_network(delta)
	elif is_mock_mode:
		_poll_mock_network(delta)

func host_room(code: String) -> void:
	is_active = true
	is_host = true
	current_room = code.to_upper().strip_edges()
	last_status = "hosting"
	
	if OS.has_feature("web"):
		var js_code = "window.KaiserNet && window.KaiserNet.initHost('%s');" % current_room
		JavaScriptBridge.eval(js_code)
	else:
		is_mock_mode = true
		mock_connected = true
		last_status = "connected"
		peer_connected.emit(true, current_room)

func join_room(code: String) -> void:
	is_active = true
	is_host = false
	current_room = code.to_upper().strip_edges()
	last_status = "connecting"
	
	if OS.has_feature("web"):
		var js_code = "window.KaiserNet && window.KaiserNet.initGuest('%s');" % current_room
		JavaScriptBridge.eval(js_code)
	else:
		is_mock_mode = true
		mock_connected = true
		last_status = "connected"
		peer_connected.emit(false, current_room)

func send_packet(data: Dictionary) -> void:
	if not is_active:
		return
		
	if OS.has_feature("web"):
		var json_str = JSON.stringify(data)
		# Pass json as string to KaiserNet.sendPacket
		var js_code = "window.KaiserNet && window.KaiserNet.sendPacket(%s);" % json_str
		JavaScriptBridge.eval(js_code)
	elif is_mock_mode:
		# In desktop mock mode, loopback packet for testing if needed
		pass

func disconnect_peer() -> void:
	is_active = false
	mock_connected = false
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.KaiserNet && window.KaiserNet.reset();")
	last_status = "idle"
	peer_disconnected.emit("User disconnected")

func _poll_web_network(delta: float) -> void:
	status_poll_timer += delta
	if status_poll_timer >= 0.15: # Poll status ~6.6 times per second
		status_poll_timer = 0.0
		var status_json = JavaScriptBridge.eval("window.KaiserNet ? window.KaiserNet.getStatus() : '{}'")
		if status_json is String and not status_json.is_empty():
			var parsed = JSON.parse_string(status_json)
			if parsed is Dictionary:
				var st = parsed.get("status", "idle")
				var ping = int(parsed.get("ping", 0))
				
				if ping != current_ping:
					current_ping = ping
					ping_updated.emit(current_ping)
					
				if st != last_status:
					var prev_st = last_status
					last_status = st
					connection_status_changed.emit(st)
					if st == "connected" and prev_st != "connected":
						peer_connected.emit(is_host, current_room)
					elif st == "disconnected" and prev_st == "connected":
						peer_disconnected.emit("Peer closed connection")
					elif st == "error":
						var err_msg = str(parsed.get("lastError", "Unknown network error"))
						peer_disconnected.emit(err_msg)

	# Fetch incoming packets at 60Hz physics rate
	var packets_json = JavaScriptBridge.eval("window.KaiserNet ? window.KaiserNet.getPackets() : '[]'")
	if packets_json is String and not packets_json.is_empty() and packets_json != "[]":
		var list = JSON.parse_string(packets_json)
		if list is Array:
			for item in list:
				if item is Dictionary:
					packet_received.emit(item)

func _poll_mock_network(_delta: float) -> void:
	pass
