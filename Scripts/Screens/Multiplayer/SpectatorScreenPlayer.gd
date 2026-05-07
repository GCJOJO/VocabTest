extends Control
class_name SpectatorScreenPlayer

enum PlayerState
{
	TypingAnswer,
	Answered,
	Eliminated
}

const PANEL_VARIATIONS : Dictionary = {
	PlayerState.TypingAnswer : "spectator_player_typing",
	PlayerState.Answered: "spectator_player_answered",
	PlayerState.Eliminated: "spectator_player_eliminated"
}

var player_info : UserResource = null
var player_id : String
var player_state : PlayerState = PlayerState.TypingAnswer
var player_score : float = 0.0

func setup(new_player_id : String, new_player_score : float):
	player_id = new_player_id
	player_info = GameManager.getPlayerData(player_id)
	if player_info == null:
		GameManager.userInfoChanged.connect(on_player_get)
		%PlayerName.hide()
		
	player_score = new_player_score
	refresh()

func on_player_get(other_player_id : String, other_player_info : UserResource):
	if other_player_id != player_id:
		return
	
	player_info = other_player_info
	GameManager.userInfoChanged.disconnect(on_player_get)
	%PlayerName.show()
	refresh()

func update_score(new_score : float):
	player_score = new_score
	refresh()
	
func update_state(new_state : PlayerState):
	player_state = new_state
	refresh()

func refresh() -> void:
	%PlayerName.text = player_info.USERNAME
	%Score.text = "Score : %s" % player_score
	
	%BackgroundPanel.theme_type_variation = PANEL_VARIATIONS[player_state]
