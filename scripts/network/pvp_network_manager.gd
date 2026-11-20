class_name PvPNetworkManager
extends Node

signal connection_status_changed(status: String)
signal peer_connected(is_host: bool, room_code: String)
signal spectator_connected(room_code: String, room_data: Dictionary)
signal peer_disconnected(reason: String)
signal packet_received(data: Dictionary)
signal ping_updated(ping_ms: int)

# Dedicated Backend WebSocket URL
# Default Render.com hosted server or localhost
@export var server_url: String = "wss://kaiser-shuttle-server.onrender.com"

var ws: WebSocketPeer = WebSocketPeer.new()
var is_active: bool = false
var is_host: bool = false
var is_spectator: bool = false
var current_room: String = ""
var last_status: String = "idle"
var current_ping: int = 0
var ping_timer: float = 0.0
var last_ping_sent_msec: int = 0
var connection_timeout_timer: float = 0.0

var pending_action: String = "" # "host", "join", or "spectate"
var pending_char: String = "nishikawa"
var pending_pts: int = 11
var pending_sets: int = 1

func _ready() -> void:
	process_physics_priority = -100
	_resolve_server_url()

func _resolve_server_url() -> void:
	if OS.has_feature("web"):
		var custom_url = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('server')")
		if custom_url is String and not custom_url.is_empty():
			server_url = custom_url
			print("[PvP] Custom server URL from query params: ", server_url)

func set_custom_server_url(url: String) -> void:
	server_url = url.strip_edges()
	print("[PvP] Server URL configured to: ", server_url)

func _physics_process(delta: float) -> void:
	if not is_active:
		return

	ws.poll()
	var state = ws.get_ready_state()

	match state:
		WebSocketPeer.STATE_CONNECTING:
			connection_timeout_timer += delta
			if connection_timeout_timer > 8.0:
				connection_timeout_timer = 0.0
				disconnect_peer()
				peer_disconnected.emit("Hết thời gian kết nối server (%s)" % server_url)

		WebSocketPeer.STATE_OPEN:
			connection_timeout_timer = 0.0
			
			# Flush pending actions upon connection
			if not pending_action.is_empty():
				var act = pending_action
				pending_action = ""
				if act == "host":
					var pkt = {
						"t": "create_room",
						"code": current_room,
						"char": pending_char,
						"pts": pending_pts,
						"sets": pending_sets
					}
					send_packet(pkt)
				elif act == "join":
					var pkt = {
						"t": "join_room",
						"code": current_room,
						"char": pending_char
					}
					send_packet(pkt)
				elif act == "spectate":
					var pkt = {
						"t": "join_spectator",
						"code": current_room
					}
					send_packet(pkt)

			# Handle Ping / Pong (every 1.5 seconds)
			ping_timer += delta
			if ping_timer >= 1.5:
				ping_timer = 0.0
				last_ping_sent_msec = Time.get_ticks_msec()
				send_packet({"t": "ping", "ts": last_ping_sent_msec})

			# Process all incoming packets
			while ws.get_available_packet_count() > 0:
				var packet_bytes = ws.get_packet()
				var text = packet_bytes.get_string_from_utf8()
				if text.is_empty():
					continue
				var parsed = JSON.parse_string(text)
				if parsed is Dictionary:
					_handle_server_packet(parsed)

		WebSocketPeer.STATE_CLOSING:
			pass

		WebSocketPeer.STATE_CLOSED:
			var code = ws.get_close_code()
			var reason = ws.get_close_reason()
			if is_active:
				is_active = false
				last_status = "disconnected"
				connection_status_changed.emit("disconnected")
				peer_disconnected.emit("Server đã ngắt kết nối (Mã: %d, Lý do: %s)" % [code, reason])

func _handle_server_packet(data: Dictionary) -> void:
	var t = str(data.get("t", ""))
	match t:
		"pong":
			var sent_ts = int(data.get("ts", 0))
			if sent_ts > 0:
				current_ping = max(1, Time.get_ticks_msec() - sent_ts)
				ping_updated.emit(current_ping)

		"room_created":
			current_room = str(data.get("code", current_room))
			last_status = "hosting"
			connection_status_changed.emit("hosting")

		"room_joined":
			current_room = str(data.get("code", current_room))
			last_status = "connected"
			connection_status_changed.emit("connected")
			peer_connected.emit(false, current_room)
			packet_received.emit(data)

		"guest_joined":
			last_status = "connected"
			connection_status_changed.emit("connected")
			peer_connected.emit(true, current_room)
			packet_received.emit(data)

		"spectator_joined":
			current_room = str(data.get("code", current_room))
			last_status = "spectating"
			is_spectator = true
			connection_status_changed.emit("spectating")
			spectator_connected.emit(current_room, data)
			packet_received.emit(data)

		"opponent_left":
			peer_disconnected.emit("Đối thủ đã thoát khỏi phòng.")

		"error":
			var msg = str(data.get("msg", "Lỗi mạng server"))
			peer_disconnected.emit(msg)

		_:
			packet_received.emit(data)

func host_room(code: String, char_id: String = "nishikawa", pts: int = 11, sets: int = 1) -> void:
	is_active = true
	is_host = true
	is_spectator = false
	current_room = code.to_upper().strip_edges()
	pending_action = "host"
	pending_char = char_id
	pending_pts = pts
	pending_sets = sets
	connection_timeout_timer = 0.0

	_connect_if_needed()

func join_room(code: String, char_id: String = "wall") -> void:
	is_active = true
	is_host = false
	is_spectator = false
	current_room = code.to_upper().strip_edges()
	pending_action = "join"
	pending_char = char_id
	connection_timeout_timer = 0.0

	_connect_if_needed()

func join_spectator(code: String) -> void:
	is_active = true
	is_host = false
	is_spectator = true
	current_room = code.to_upper().strip_edges()
	pending_action = "spectate"
	connection_timeout_timer = 0.0

	_connect_if_needed()

func _connect_if_needed() -> void:
	var state = ws.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		return
	if state == WebSocketPeer.STATE_CONNECTING:
		return

	last_status = "connecting"
	connection_status_changed.emit("connecting")
	var err = ws.connect_to_url(server_url)
	if err != OK:
		is_active = false
		last_status = "error"
		connection_status_changed.emit("error")
		peer_disconnected.emit("Không thể mở kết nối tới " + server_url)

func start_match(pts: int, sets: int, first_server: String = "") -> void:
	var pkt = {
		"t": "start_match",
		"pts": pts,
		"sets": sets
	}
	if not first_server.is_empty():
		pkt["first_server"] = first_server
	send_packet(pkt)

func send_packet(data: Dictionary) -> void:
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var json_str = JSON.stringify(data)
		ws.send_text(json_str)

func disconnect_peer() -> void:
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN or ws.get_ready_state() == WebSocketPeer.STATE_CONNECTING:
		ws.close(1000, "Client disconnect")
	is_active = false
	pending_action = ""
	last_status = "idle"
	peer_disconnected.emit("Đã ngắt kết nối")
