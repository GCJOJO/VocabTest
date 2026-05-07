extends Control

@export var LOBBY_BUTTON_SCENE : PackedScene = preload("res://Prefabs/LobbyButton.tscn")

var lobbyId : String = ""
var hasAlreadyLoaded : bool = false
var is_spectating : bool = false
var winner_id : String = ""
var eliminated_players : Array[String] = []

signal word_changed()

var socket : WebSocketPeer = WebSocketPeer.new()

const WEBSOCKET_TIMEOUT : int = 100

enum LobbyMode
{
	Classic = 0,
	BattleRoyale = 1
}

var LobbyOptions = {
	"max_words" : 10,
	"categories": 16,
	"round_timer": 15, 
	"similarity_threshold": 0.8,
	"lobby_mode" : int(LobbyMode.BattleRoyale)
}
	
func _ready() -> void:
	set_process(false)

func loadMultiplayerScreen() -> void:
	if hasAlreadyLoaded and (socket.get_ready_state() == WebSocketPeer.STATE_CLOSING or socket.get_ready_state() == WebSocketPeer.STATE_CLOSING):
		connectToWebsocket()
		return
	
	if hasAlreadyLoaded:
		return
	hasAlreadyLoaded = true
	
	$LobbyScreen.visible = false
	$InGameScreen.visible = false
	$ResultsScreen.visible = false
	%GameMenu.answerEntered.connect(submitAnswer)
	%GameMenu.readyNextQuestion.connect(requestNextQuestion)
	
	%GameOptions.wordsCountChanged.connect(func(value : int): updateLobbyOptions("max_words", value))
	%GameOptions.categoriesChanged.connect(func(value : int): updateLobbyOptions("categories", value))
	%GameOptions.wordsThresholdChanged.connect(func(value: float): updateLobbyOptions("similarity_threshold", value))
	%GameOptions.timerChanged.connect(func(value: int): updateLobbyOptions("round_timer", value))
	
	%GameOptions.setIsDisabled(true)
	%GameOptions.setup()
	
	connectToWebsocket()
	
func connectToWebsocket():
	if socket.get_ready_state() == WebSocketPeer.STATE_CONNECTING or socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		return
	
	set_process(true)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var error = socket.connect_to_url(GameManager.WEBSOCKET_ADRESS, TLSOptions.client_unsafe())
	if error == OK:
		if GameManager.DEBUG_MODE:
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
		
		if GameManager.DEBUG_MODE:
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
	if socket.get_ready_state() != socket.STATE_OPEN:
		return
	var json : String = JSON.stringify({"action" : "leave-lobby", "player_id" : GameManager.PlayerUUID, "lobby_id" : lobbyId})
	socket.send_text(json)
	
func disbandLobby() -> void:
	if socket.get_ready_state() != socket.STATE_OPEN:
		return
	var json : String = JSON.stringify({"action" : "disband-lobby", "player_id" : GameManager.PlayerUUID, "lobby_id" : lobbyId})
	socket.send_text(json)

func submitAnswer(answerType : int, answer) -> void:
	if socket.get_ready_state() != socket.STATE_OPEN:
		return
	var json : String = JSON.stringify({"action" : "send-answer", "player_id": GameManager.PlayerUUID, "lobby_id" : lobbyId, "answer_type" : answerType, "answer"  : answer})
	socket.send_text(json)

func requestNextQuestion() -> void:
	if socket.get_ready_state() != socket.STATE_OPEN:
		return
	var json : String = JSON.stringify({"action" : "request-next-question", "player_id" : GameManager.PlayerUUID, "lobby_id": lobbyId})
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
	if socket.get_ready_state() != socket.STATE_OPEN:
		return
	LobbyOptions[key] = value
	var json : String = JSON.stringify({"action" : "update-lobby-options", "player_id": GameManager.PlayerUUID, "lobby_id": lobbyId, "options": LobbyOptions})
	socket.send_text(json)

func continueGame() -> void:
	$ResultsScreen.visible = false
	$LobbyScreen.visible = true
	socket.send_text(JSON.stringify({"action" : "continue-game", "lobby_id" : lobbyId}))

func _doNewQuestion(questionType : int, newQuestion : Dictionary) -> void:
	if is_spectating:
		for player in %Scoreboard.get_scoreboard().keys():
			if eliminated_players.has(player): continue
			$SpectatorScreen.update_player_state(player, SpectatorScreenPlayer.PlayerState.TypingAnswer)
		return
	
	match questionType:
		GameManager.WORD_CATEGORY:
			var context : String = newQuestion["contexte"] if newQuestion["contexte"] != null else ""
			var englishWords : PackedStringArray = newQuestion["anglais"].split("/")
			var newWord : = WordResource.new(newQuestion["identifiant"], newQuestion["français"], context, englishWords)
			%GameMenu.setWord(newWord)
		GameManager.VERB_CATEGORY:
			var context : String = newQuestion["context"] if newQuestion["context"] != null else ""
			var inf : String = newQuestion["infinitive"]
			var pre : String = newQuestion["preterit"]
			var pp : String = newQuestion["past_participle"]
			var newVerb : = VerbResource.new(newQuestion["id"], newQuestion["french"], context, inf.split("/"), pre.split("/"), pp.split("/"))
			%GameMenu.setVerb(newVerb)
		GameManager.COUNTRY_CATEGORY:
			var context : String = ""
			var englishWords : PackedStringArray = newQuestion["english"].split("/")
			var newWord : = WordResource.new(newQuestion["id"], newQuestion["french"], context, englishWords)
			%GameMenu.setCountry(newWord)
		GameManager.GRAMMAR_CATEGORY:
			var context : String = newQuestion["category"] if newQuestion["category"] != null else ""
			var englishWords : PackedStringArray = newQuestion["english"].split("/")
			var newWord : = WordResource.new(newQuestion["id"], newQuestion["french"], context, englishWords)
			%GameMenu.setGrammar(newWord)
	
	word_changed.emit()

func _doShowResult(wordSimilarity : float, similarityThreshold : float) -> void:
	#$InGameScreen/WordQuestion.showResult(wordSimilarity, similarityThreshold)
	%GameMenu.showResultsSimilarity(wordSimilarity, similarityThreshold)

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
	is_spectating = false
	eliminated_players.clear()
	
	$LobbyScreen.visible = false
	$InGameScreen.visible = true
	%GameMenu.setup(false, LobbyOptions["max_words"], LobbyOptions["similarity_threshold"], LobbyOptions["round_timer"], false)
	$SpectatorScreen/Timer.setMaxRoundTimer(LobbyOptions["round_timer"])

func _doQuitLobby() -> void:
	lobbyId = ""
	$ResultsScreen.visible = false
	$InGameScreen.visible = false
	$LobbyScreen.visible = false
	$LobbyDiscoveryScreen.visible = true
	enableAllButtons()
	getLobbyList()
	#get_tree().reload_current_scene()

func _doEndGame(new_winner_id : String) -> void:
	%WinnerName.hide()
	winner_id = new_winner_id
	var winner_info : UserResource = GameManager.getPlayerData(winner_id)
	if winner_info == null:
		GameManager.userInfoChanged.connect(update_winner)
	else:
		%WinnerName.text = "[tornado radius=3 freq=2]%s[/tornado] est le grand vainqueur !" % winner_info.USERNAME
		%WinnerName.show()
	
	#Maybe show end results screen
	$InGameScreen.visible = false
	$SpectatorScreen.visible = false
	$ResultsScreen.visible = true
	
	queryIsLobbyOwner(lobbyId)

func update_winner(user_id : String, winner_info : UserResource):
	if user_id == winner_id:
		%WinnerName.text = "[tornado radius=3 freq=2]%s[/tornado] est le grand vainqueur !" % winner_info.USERNAME
		%WinnerName.show()
		GameManager.userInfoChanged.disconnect(update_winner)

func _doPlayerJoined(joiningPlayerId : String):
	%InGameScoreboard.setScore(joiningPlayerId, 0)
	%LobbyScoreboard.setScore(joiningPlayerId, 0)
	%InGameScoreboard.refreshScoreboard()
	%LobbyScoreboard.refreshScoreboard()

func _doUpdateScores(updatedScores : Array) -> void:
	for i in range(0, updatedScores.size()):
		var newScore = updatedScores[i]
		var scorePlayerId = newScore["player_id"]
		var newPlayerScore = newScore["new_score"]
		%InGameScoreboard.setScore(scorePlayerId, newPlayerScore)
		%LobbyScoreboard.setScore(scorePlayerId, newPlayerScore)
		%Scoreboard.setScore(scorePlayerId, newPlayerScore)
		$SpectatorScreen.update_player_score(scorePlayerId, newPlayerScore)
		
	%InGameScoreboard.refreshScoreboard()
	%LobbyScoreboard.refreshScoreboard()
	%Scoreboard.refreshScoreboard()

func _do_spectate() -> void:
	is_spectating = true
	$InGameScreen.visible = false
	$SpectatorScreen.visible = true
	
	var players = %Scoreboard.get_scoreboard()
	$SpectatorScreen.load_players(players)
	
	$SpectatorScreen.update_player_state(GameManager.PlayerUUID, SpectatorScreenPlayer.PlayerState.Eliminated)
	eliminated_players.push_back(GameManager.PlayerUUID)
	
func _do_eliminate_player(other_id : String) -> void:
	$SpectatorScreen.update_player_state(other_id, SpectatorScreenPlayer.PlayerState.Eliminated)
	eliminated_players.push_back(other_id)
	
func _do_player_answer(other_id : String) -> void:
	if eliminated_players.has(other_id): return
	$SpectatorScreen.update_player_state(other_id, SpectatorScreenPlayer.PlayerState.Answered)

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
		"new-question":
			var newQuestion = data["question"]
			_doNewQuestion(newQuestion["category"], newQuestion["question"])
		"lobby-started":
			_doStartLobby()
		"lobby-created":
			#_doJoinLobby(data["lobby_id"], [])
			joinLobby(data["lobby_id"])
		"lobby-joined":
			_doJoinLobby(data["lobby_id"], data["current_lobby_players"])
		"lobby-left":
			if GameManager.DEBUG_MODE:
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
		"spectate":
			_do_spectate()
		"player-eliminated": #player_id
			_do_eliminate_player(data["player_id"])
		"player-answered": #player_id / Used when a player is spectating to know who has already answered
			_do_player_answer(data["player_id"])
		"end-game": #winner_id
			_doEndGame(data["winner_id"])
		"new-owner":
			setIsLobbyOwner(data["player_id"] == GameManager.PlayerUUID)
		"timer-update":
			var currentTime = LobbyOptions["round_timer"] - data["current_round_timer"]
			%GameMenu.setTimer(currentTime)
			$SpectatorScreen/Timer.setRoundTimer(currentTime)
		"player-left":
			%LobbyScoreboard.removePlayer(data["player_id"])
			%InGameScoreboard.removePlayer(data["player_id"])
			%LobbyScoreboard.refreshScoreboard()
			%InGameScoreboard.refreshScoreboard()

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
		if GameManager.DEBUG_MODE:
			print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		returnToMainMenu()
		
func returnToMainMenu() -> void:
	set_process(false)
	pass
