extends Control
class_name LobbyButton

var lobbyId : String = ""
var lobbyOwner : String = ""
var lobbyPlayerCount : int = 0
signal join_lobby(lobby_id : String)

func enable() -> void:
	$JoinButton.disabled = false
	
func disable() -> void:
	$JoinButton.disabled = true

func setup(lobby):
	lobbyId = lobby["id"]
	lobbyOwner = lobby["owner"]
	lobbyPlayerCount = lobby["player_count"]
	var owningPlayer = GameManager.getPlayerData(lobbyOwner)
	if owningPlayer == null:
		$JoinButton.text = "Rejoindre : %d sur %d" % [lobbyPlayerCount, 10]
		GameManager.userInfoChanged.connect(onUserInfoChanged)
	else:
		$JoinButton.text = "Rejoindre %s : %s sur %s" % [owningPlayer.USERNAME, lobbyPlayerCount, 10]
		
func onUserInfoChanged(userId : String, userData : UserResource) -> void:
	if userId != lobbyOwner:
		return
	GameManager.userInfoChanged.disconnect(onUserInfoChanged)
	$JoinButton.text = "Rejoindre %s : %s sur %s" % [userData.USERNAME, lobbyPlayerCount, 10]

func join():
	join_lobby.emit(lobbyId)
