extends Control

const SERVER_ADRESS : String = "http://localhost:5762"
const WEBSOCKET_ADRESS : String = "ws://localhost:5763"

@onready var playerId : String = UUID.v4()
var lobbyId : String = ""

var httpRequest : HTTPRequest = HTTPRequest.new()
var socket : WebSocketPeer = WebSocketPeer.new()

func _ready() -> void:
	set_process(true)
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(httpRequest)
	httpRequest.request_completed.connect(self.http_request_completed)
	var error = socket.connect_to_url(WEBSOCKET_ADRESS, TLSOptions.client_unsafe())
	if error == OK:
		print("Connecting to websocket")
		await get_tree().create_timer(1).timeout
		
		socket.send_text("Feur ahahahahahahahahaéh")
		createLobby()
	else:
		push_error("Unable to connect to websocket")
	

func createLobby() -> void:
	var json : String = JSON.stringify({"action" : "create-lobby", "player_id" : playerId})
	#socket.put_packet(json.to_utf8_buffer())
	socket.send_text(json)
	
func getLobbyList() -> void:
	httpRequest.request("%s/lobbies" % SERVER_ADRESS)

func startLobby() -> void:
	var json : String = JSON.stringify({"action" : "start-lobby", "player_id" : playerId, "lobbyId": lobbyId})
	socket.send_text(json)
	
func joinLobby(joinedLobbyId : String) -> void:
	var json : String = JSON.stringify({"action" : "join-lobby", "player_id" : playerId, "lobbyId" : joinedLobbyId})
	socket.send_text(json)

func leaveLobby() -> void:
	var json : String = JSON.stringify({"action" : "leave-lobby", "player_id" : playerId, "lobbyId" : lobbyId})
	socket.send_text(json)
	
func disbandLobby() -> void:
	var json : String = JSON.stringify({"action" : "disband-lobby", "player_id" : playerId, "lobbyId" : lobbyId})
	socket.send_text(json)

func http_request_completed(_result : int, _response_code : int, _headers : PackedStringArray, body : PackedByteArray):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()

	if response == null:
		breakpoint
		return

	# Will print the user agent string used by the HTTPRequest node (as recognized by httpbin.org).
	print(response)
	if not response.has("action"):
		return
	var action = response["action"]
	if action == "set-lobbies":
		print(response["lobbies"])
	
func handle_packet(packet_str : String) -> void:
	var json : JSON = JSON.new()
	json.parse(packet_str)
	if json == null:
		return
	
	var data = json.get_data()
	print(data)
	
	if not data.has("action"):
		return
	
	var action = data["action"]
	match action:
		"lobby-created":
			getLobbyList()
		"lobby-joined":
			doJoinLobby(data["lobby_id"])
		"lobby-left":
			doQuitLobby()
		"lobby-disbanded":
			doQuitLobby()

func isInLobby() -> bool:
	return not lobbyId.is_empty()

func doJoinLobby(newLobbyId : String) -> void:
	lobbyId = newLobbyId

func doStartLobby() -> void:
	pass

func doQuitLobby() -> void:
	lobbyId = ""

func _process(_delta):
	socket.poll()
	var state = socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			var packetStr = socket.get_packet().get_string_from_utf8()
			print("Packet: ", packetStr)
			handle_packet(packetStr)
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		
