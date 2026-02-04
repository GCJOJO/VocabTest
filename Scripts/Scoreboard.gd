extends Control
class_name Scoreboard

@export var ScoreboardPlayerScene : PackedScene = preload("res://Scenes/scoreboard_player.tscn")
var PLAYER_SCORES : Dictionary[String, int] = {}

#func _ready() -> void:
	#setScore("Feur", 150)
	#setScore("FJEioh0", 200)
	#setScore("Bonbon", 1)
	#setScore("Bob", 5000)
	#
	#await get_tree().create_timer(1).timeout
	#
	#refreshScoreboard()
	#
	#setScore("Feur", 250)
	#setScore("FJEioh0", 300)
	#setScore("Bonbon", 500)
	#setScore("Bob", 10)
	#
	#await get_tree().create_timer(5).timeout
	#
	#refreshScoreboard()
	
func setScore(playerId : String, playerScore : int) -> void:
	PLAYER_SCORES[playerId] = playerScore
	
func addScore(playerId : String, playerScore : int) -> void:
	if PLAYER_SCORES.has(playerId):
		PLAYER_SCORES[playerId] += playerScore
	else:
		setScore(playerId, playerScore)
		

func refreshScoreboard() -> void:
	var orderedPlayer : Array
	
	for playerId in PLAYER_SCORES:
		
		var has_name : bool = false
		for child in get_children():
			if child.name == playerId:
				has_name = true
				break
		
		if not has_name:
			var node : = ScoreboardPlayerScene.instantiate()
			if node is not ScoreboardPlayer:
				node.queue_free()
				continue
			var scoreboardPlayer : ScoreboardPlayer = node as ScoreboardPlayer
			scoreboardPlayer.name = playerId
			scoreboardPlayer.setId(playerId)
			scoreboardPlayer.setName("Bob")
			scoreboardPlayer.setScore(PLAYER_SCORES[playerId])
			add_child(scoreboardPlayer)
		orderedPlayer.push_back({"id" : playerId, "score" : PLAYER_SCORES[playerId]})
	
	orderedPlayer.sort_custom(func(a, b): return a["score"] > b["score"])
	
	for index in range(0, len(orderedPlayer)):
		var playerId = orderedPlayer[index]
		var scoreboardPlayer : Control = get_node(playerId["id"])
		var positionTween : Tween = get_tree().create_tween()
		positionTween.set_ease(Tween.EASE_IN_OUT)
		var calculatedPosition : Vector2 = Vector2(0, scoreboardPlayer.size.y * index)
		positionTween.set_parallel(true)
		positionTween.tween_property(scoreboardPlayer, "position", calculatedPosition, 0.5)
