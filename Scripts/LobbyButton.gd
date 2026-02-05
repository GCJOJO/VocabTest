extends Control
class_name LobbyButton

var lobbyId : String = ""
signal join_lobby(lobby_id : String)

func enable() -> void:
	$JoinButton.disabled = false
	
func disable() -> void:
	$JoinButton.disabled = true

func setup(lobby):
	lobbyId = lobby["id"]
	$JoinButton.text = "Rejoindre : %d sur %d (%s)" % [lobby["player_count"], 10, lobbyId]

func join():
	join_lobby.emit(lobbyId)
