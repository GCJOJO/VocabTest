extends Control
class_name ScoreboardPlayer

var playerId : String
var playerName : String
var playerScore : float
var is_leaderboard : bool = false

func _ready() -> void:
	var width = max(320, get_parent().size.x)
	set_deferred("size", Vector2(width, 64))

func set_is_leaderboard(leaderboard : bool) -> void:
	is_leaderboard = leaderboard

func setId(newId : String) -> void:
	playerId = newId

func setName(newName : String) -> void:
	playerName = newName
	$%PlayerName.text = "[font_size=24]%s" % playerName
	
func setScore(newScore : float) -> void:
	playerScore = newScore
	if not is_leaderboard:
		$%PlayerScore.text = "[font_size=18]%.2f points" % playerScore
	else:
		$%PlayerScore.text = "[font_size=18]%.0f mots" % playerScore
