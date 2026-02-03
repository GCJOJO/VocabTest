extends Control

const SERVER_ADRESS : String = "http://localhost:5762"
const WEBSOCKET_ADRESS : String = "ws://localhost:5763"

@export var LOBBY_BUTTON_SCENE : PackedScene = preload("res://Prefabs/LobbyButton.tscn")

@onready var playerId : String = UUID.v4()
var lobbyId : String = ""

var httpRequest : HTTPRequest = HTTPRequest.new()
var socket : WebSocketPeer = WebSocketPeer.new()

func _ready() -> void:
	$LobbyScreen.visible = false
	$InGameScreen.visible = false
	
	set_process(true)
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(httpRequest)
	httpRequest.request_completed.connect(self.http_request_completed)
	var error = socket.connect_to_url(WEBSOCKET_ADRESS, TLSOptions.client_unsafe())
	if error == OK:
		print("Connecting to websocket")
		await get_tree().create_timer(1).timeout
		
		socket.send_text("Feur ahahahahahahahahaéh")
		getLobbyList()
	else:
		push_error("Unable to connect to websocket")
	
func disableAllButtons() -> void:
	%CreateLobby.disabled = true
	%Refresh.disabled = true
	
	for child : LobbyButton in %Lobbies.get_children():
		child.disable()
		
func enableAllButtons() -> void:
	%CreateLobby.disabled = false
	%Refresh.disabled = false
	
	for child : LobbyButton in %Lobbies.get_children():
		child.enable()

func createLobby() -> void:
	disableAllButtons()
	
	var json : String = JSON.stringify({"action" : "create-lobby", "player_id" : playerId})
	#socket.put_packet(json.to_utf8_buffer())
	socket.send_text(json)
	
func getLobbyList() -> void:
	%Refresh.disabled = true
	
	var children = %Lobbies.get_children()
	for child in children:
		child.queue_free()
	
	httpRequest.request("%s/lobbies" % SERVER_ADRESS)

func startLobby() -> void:
	$LobbyScreen/StartLobby.disabled = true
	var json : String = JSON.stringify({"action" : "start-lobby", "player_id" : playerId, "lobby_id": lobbyId})
	socket.send_text(json)
	
func joinLobby(joinedLobbyId : String) -> void:
	disableAllButtons()
		
	var json : String = JSON.stringify({"action" : "join-lobby", "player_id" : playerId, "lobby_id" : joinedLobbyId})
	socket.send_text(json)

func leaveLobby() -> void:
	var json : String = JSON.stringify({"action" : "leave-lobby", "player_id" : playerId, "lobby_id" : lobbyId})
	socket.send_text(json)
	
func disbandLobby() -> void:
	var json : String = JSON.stringify({"action" : "disband-lobby", "player_id" : playerId, "lobby_id" : lobbyId})
	socket.send_text(json)

func http_request_completed(_result : int, _response_code : int, _headers : PackedStringArray, body : PackedByteArray):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()

	if response == null:
		return

	# Will print the user agent string used by the HTTPRequest node (as recognized by httpbin.org).
	print(response)
	if not response.has("action"):
		return
	var action = response["action"]
	if action == "set-lobbies":
		%Refresh.disabled = false
		
		print(response["lobbies"])
		for lobby in response["lobbies"]:
			if lobby["status"] == "started":
				continue
			
			var node = LOBBY_BUTTON_SCENE.instantiate()
			if node is not LobbyButton:
				node.queue_free()
				continue
			
			var lobbyBtn : LobbyButton = node as LobbyButton
			lobbyBtn.name = "LobbyButton-%s" % lobby["id"]
			lobbyBtn.setup(lobby)
			lobbyBtn.join_lobby.connect(joinLobby)
			%Lobbies.add_child(lobbyBtn)
	if action == "test-ownership":
		var result : bool = response["result"]
		$LobbyScreen/StartLobby.disabled = not result
		$LobbyScreen/StartLobby.visible = result
	
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
		"new-word":
			_doNewWord(data["word"])
		"lobby-started":
			_doStartLobby()
		"lobby-created":
			_doJoinLobby(data["lobby_id"])
		"lobby-joined":
			_doJoinLobby(data["lobby_id"])
		"lobby-left":
			print("Lobby Left")
			_doQuitLobby()
		"lobby-disbanded":
			_doQuitLobby()

func isInLobby() -> bool:
	return not lobbyId.is_empty()
	
func queryIsLobbyOwner(id : String) -> void:
	var body = JSON.stringify({"lobby_id": id, "player_id" : playerId})
	var headers = ["Content-Type: application/json"]
	httpRequest.request('%s/owner' % SERVER_ADRESS, headers, HTTPClient.METHOD_GET, body)

func _doNewWord(newWordData) -> void:
	var context : String = newWordData["contexte"] if newWordData["contexte"] != null else ""
	var englishWords : PackedStringArray = newWordData["anglais"].split("/")
	var newWord : = WordResource.new(newWordData["identifiant"], newWordData["français"], context, englishWords)
	%WordQuestion.changeWord(newWord)

func _doJoinLobby(newLobbyId : String) -> void:
	lobbyId = newLobbyId
	$LobbyDiscoveryScreen.visible = false
	$LobbyScreen.visible = true
	$LobbyScreen/StartLobby.disabled = true
	$LobbyScreen/StartLobby.visible = false
	queryIsLobbyOwner(lobbyId)

func _doStartLobby() -> void:
	$LobbyScreen.visible = false
	$InGameScreen.visible = true

func _doQuitLobby() -> void:
	lobbyId = ""
	$LobbyScreen.visible = false
	$LobbyDiscoveryScreen.visible = true
	enableAllButtons()
	getLobbyList()
	#get_tree().reload_current_scene()

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
		
	
