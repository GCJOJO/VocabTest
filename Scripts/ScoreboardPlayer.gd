extends Control
class_name ScoreboardPlayer

var playerId : String
var playerName : String
var playerScore : int

func _ready() -> void:
	size = Vector2(576, 64)

func setId(newId : String) -> void:
	playerId = newId

func setName(newName : String) -> void:
	playerName = newName
	$%PlayerName.text = "[font_size=32]%s" % playerName
	
func setScore(newScore : int) -> void:
	playerScore = newScore
	$%PlayerScore.text = "[font_size=32]%s" % playerScore
