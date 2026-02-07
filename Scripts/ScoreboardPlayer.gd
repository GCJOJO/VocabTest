extends Control
class_name ScoreboardPlayer

var playerId : String
var playerName : String
var playerScore : float

func _ready() -> void:
	size = Vector2(320, 64)

func setId(newId : String) -> void:
	playerId = newId

func setName(newName : String) -> void:
	playerName = newName
	$%PlayerName.text = "[font_size=24]%s" % playerName
	
func setScore(newScore : float) -> void:
	playerScore = newScore
	$%PlayerScore.text = "[font_size=18]%.2f" % playerScore
