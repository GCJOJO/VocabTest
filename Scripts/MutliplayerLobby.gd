extends Control

@export var LOBBY_BUTTON_SCENE : PackedScene = preload("res://Prefabs/LobbyButton.tscn")

var lobbyId : String = ""

#var httpRequest : HTTPRequest = HTTPRequest.new()
var socket : WebSocketPeer = WebSocketPeer.new()

const WEBSOCKET_TIMEOUT : int = 100

var LobbyOptions = {
	"max_words" : 10,
	"categories": 16,
	"round_timer": 15, 
	"similarity_threshold": 0.8
}

func _ready() -> void:
	$LobbyScreen.visible = false
	$InGameScreen.visible = false
	$InGameScreen/WordQuestion.entered_word.connect(submitWord)
	$InGameScreen/WordQuestion.readyNextQuestion.connect(requestNextWord)
	
	%GameOptions.wordsCountChanged.connect(func(value : int): updateLobbyOptions("max_words", value))
	%GameOptions.wordsThresholdChanged.connect(func(value: float): updateLobbyOptions("similarity_threshold", value))
	%GameOptions.timerChanged.connect(func(value: int): updateLobbyOptions("round_timer", value))
	
	%GameOptions.setIsDisabled(true)
	
	set_process(true)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var error = socket.connect_to_url(GameManager.WEBSOCKET_ADRESS, TLSOptions.client_unsafe())
	if error == OK:
		print("Connecting to websocket")
		
		%CreateLobby.disabled = true
		%Refresh.disabled = true
		
		var timeSpent : int = 0
		var couldConnect : bool = false
		while timeSpent < WEBSOCKET_TIMEOUT:
			await get_tree().create_timer(0.1).timeout
			timeSpent += 1
			if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
				socket.send_text("Feur ahahahahahahahahaéh")
				getLobbyList()
				couldConnect = true
				%CreateLobby.disabled = false
				%Refresh.disabled = false
				break
		if not couldConnect:
			push_warning("Unable to connect to websocket")
			returnToMainMenu()
			return
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
	
	var json : String = JSON.stringify({"action" : "create-lobby", "player_id" : GameManager.PlayerUUID})
	#socket.put_packet(json.to_utf8_buffer())
	socket.send_text(json)
	
func getLobbyList() -> void:
	%Refresh.disabled = true
	
	var children = %Lobbies.get_children()
	for child in children:
		child.queue_free()
	
	RequestQueue.requestGet("%s/lobbies" % GameManager.SERVER_ADRESS, onLobbiesGet)

func onLobbiesGet(response):
	if response == null:
		return

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

func startLobby() -> void:
	$LobbyScreen/StartLobby.disabled = true
	var json : String = JSON.stringify({"action" : "start-lobby", "player_id" : GameManager.PlayerUUID, "lobby_id": lobbyId})
	socket.send_text(json)
	
func joinLobby(joinedLobbyId : String) -> void:
	disableAllButtons()
		
	var json : String = JSON.stringify({"action" : "join-lobby", "player_id" : GameManager.PlayerUUID, "lobby_id" : joinedLobbyId})
	socket.send_text(json)

func leaveLobby() -> void:
	var json : String = JSON.stringify({"action" : "leave-lobby", "player_id" : GameManager.PlayerUUID, "lobby_id" : lobbyId})
	socket.send_text(json)
	
func disbandLobby() -> void:
	var json : String = JSON.stringify({"action" : "disband-lobby", "player_id" : GameManager.PlayerUUID, "lobby_id" : lobbyId})
	socket.send_text(json)

func submitWord(word: String) -> void:
	var json : String = JSON.stringify({"action" : "send-word", "player_id": GameManager.PlayerUUID, "lobby_id": lobbyId, "word": word})
	socket.send_text(json)

func requestNextWord() -> void:
	var json : String = JSON.stringify({"action" : "request-next-word", "player_id" : GameManager.PlayerUUID, "lobby_id": lobbyId})
	socket.send_text(json)

func isInLobby() -> bool:
	return not lobbyId.is_empty()
	
func queryIsLobbyOwner(id : String) -> void:
	RequestQueue.requestGet("%s/owner/%s?player_id=%s" % [GameManager.SERVER_ADRESS, id, GameManager.PlayerUUID], func(response):
		if response == null or response["action"] == null:
			return
		if response["action"] == "test-ownership":
			var result : bool = response["result"]
			setIsLobbyOwner(result))
	#httpRequest.request('%s/owner/%s?player_id=%s' % [GameManager.SERVER_ADRESS, id, GameManager.PlayerUUID])

func setIsLobbyOwner(isOwner : bool):
	$LobbyScreen/StartLobby.disabled = not isOwner
	$LobbyScreen/StartLobby.visible = isOwner
	%GameOptions.setIsDisabled(not isOwner)

func updateLobbyOptions(key : String, value) :
	LobbyOptions[key] = value
	var json : String = JSON.stringify({"action" : "update-lobby-options", "player_id": GameManager.PlayerUUID, "lobby_id": lobbyId, "options": LobbyOptions})
	socket.send_text(json)

func _doNewWord(newWordData) -> void:
	var context : String = newWordData["contexte"] if newWordData["contexte"] != null else ""
	var englishWords : PackedStringArray = newWordData["anglais"].split("/")
	var newWord : = WordResource.new(newWordData["identifiant"], newWordData["français"], context, englishWords)
	%WordQuestion.changeWord(newWord)

func _doShowResult(wordSimilarity : float, similarityThreshold : float) -> void:
	$InGameScreen/WordQuestion.showResult(wordSimilarity, similarityThreshold)

func _doJoinLobby(newLobbyId : String, currentLobbyPlayers : Array) -> void:
	lobbyId = newLobbyId
	$LobbyDiscoveryScreen.visible = false
	$LobbyScreen.visible = true
	$LobbyScreen/StartLobby.disabled = true
	$LobbyScreen/StartLobby.visible = false
	queryIsLobbyOwner(lobbyId)
	
	currentLobbyPlayers.push_back({"player_id" : GameManager.PlayerUUID, "score" : 0})
	for i in range(0, len(currentLobbyPlayers)):
		var newScore = currentLobbyPlayers[i]
		var scorePlayerId = newScore["player_id"]
		var newPlayerScore = newScore["score"]
		%InGameScoreboard.setScore(scorePlayerId, newPlayerScore)
		%LobbyScoreboard.setScore(scorePlayerId, newPlayerScore)
	
	%InGameScoreboard.refreshScoreboard()
	%LobbyScoreboard.refreshScoreboard()

func _doStartLobby() -> void:
	$LobbyScreen.visible = false
	$InGameScreen.visible = true
	$InGameScreen/Timer.setMaxRoundTimer(LobbyOptions["round_timer"])
	$InGameScreen/Timer.setRoundTimer(LobbyOptions["round_timer"])

func _doQuitLobby() -> void:
	lobbyId = ""
	$LobbyScreen.visible = false
	$LobbyDiscoveryScreen.visible = true
	enableAllButtons()
	getLobbyList()
	#get_tree().reload_current_scene()

func _doEndGame() -> void:
	#Maybe show end results screen
	$InGameScreen.visible = false
	$LobbyScreen.visible = true
	queryIsLobbyOwner(lobbyId)

func _doPlayerJoined(joiningPlayerId : String):
	%InGameScoreboard.setScore(joiningPlayerId, 0)
	%LobbyScoreboard.setScore(joiningPlayerId, 0)
	%InGameScoreboard.refreshScoreboard()
	%LobbyScoreboard.refreshScoreboard()

func _doUpdateScores(updatedScores : Array) -> void:
	for i in range(0, len(updatedScores)):
		var newScore = updatedScores[i]
		var scorePlayerId = newScore["player_id"]
		var newPlayerScore = newScore["new_score"]
		%InGameScoreboard.setScore(scorePlayerId, newPlayerScore)
		%LobbyScoreboard.setScore(scorePlayerId, newPlayerScore)
		
	%InGameScoreboard.refreshScoreboard()
	%LobbyScoreboard.refreshScoreboard()

func handle_packet(packet_str : String) -> void:
	var json : JSON = JSON.new()
	json.parse(packet_str)
	if json == null:
		return
	
	var data = json.get_data()
	if GameManager.DEBUG_MODE:
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
			_doJoinLobby(data["lobby_id"], [])
		"lobby-joined":
			_doJoinLobby(data["lobby_id"], data["current_lobby_players"])
		"lobby-left":
			print("Lobby Left")
			_doQuitLobby()
		"lobby-disbanded":
			_doQuitLobby()
		"player-joined":
			_doPlayerJoined(data["player_id"])
		"update-scores":
			_doUpdateScores(data["scores"])
		"lobby-options-updated":
			LobbyOptions = data["options"]
			%GameOptions.updateOptions(data["options"])
		"show-results":
			_doShowResult(data["word_similarity"], data["similarity_threshold"])
		"end-game":
			_doEndGame()
		"new-owner":
			setIsLobbyOwner(data["player_id"] == GameManager.PlayerUUID)
		"timer-update":
			var currentTime = LobbyOptions["round_timer"] - data["current_round_timer"]
			$InGameScreen/Timer.setRoundTimer(currentTime)
		"player-left":
			%LobbyScoreboard.removePlayer(data["player_id"])
			%InGameScoreboard.removePlayer(data["player_id"])
			%LobbyScoreboard.refreshScoreboard()
			%InGameScoreboard.refreshScoreboard()
			pass

func _process(_delta):
	socket.poll()
	var state = socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			var packetStr = socket.get_packet().get_string_from_utf8()
			handle_packet(packetStr)
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		returnToMainMenu()
		
	
func returnToMainMenu() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
