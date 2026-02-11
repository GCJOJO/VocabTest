extends Control
class_name Scoreboard

@export var ScoreboardPlayerScene : PackedScene = preload("res://Prefabs/scoreboard_player.tscn")
var PLAYER_SCORES : Dictionary[String, float] = {}

var PLAYERS_DATA_TO_UPDATE : Dictionary[String, Callable]

func _ready() -> void:
	GameManager.userInfoChanged.connect(onUserInfoChanged)
	
func onUserInfoChanged(userId : String, userData : UserResource):
	if PLAYERS_DATA_TO_UPDATE.has(userId):
		var callback : Callable = PLAYERS_DATA_TO_UPDATE[userId]
		callback.call(userData)
		PLAYERS_DATA_TO_UPDATE.erase(userId)
	
func setScore(playerId : String, playerScore : float) -> void:
	PLAYER_SCORES[playerId] = playerScore
	
func addScore(playerId : String, playerScore : float) -> void:
	if PLAYER_SCORES.has(playerId):
		PLAYER_SCORES[playerId] += playerScore
	else:
		setScore(playerId, playerScore)
		
func removePlayer(playerId : String) -> void:
	PLAYER_SCORES.erase(playerId)
	var scoreboardPlayer : ScoreboardPlayer = get_node("./%s" % playerId) as ScoreboardPlayer
	if scoreboardPlayer == null:
		return
	scoreboardPlayer.queue_free()

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
			
			var player : UserResource = GameManager.getPlayerData(playerId)
			scoreboardPlayer.name = playerId
			scoreboardPlayer.setId(playerId)
			if player != null:
				scoreboardPlayer.setName(player.USERNAME)
			else:
				PLAYERS_DATA_TO_UPDATE[playerId] = onReceivedPlayerData 
				scoreboardPlayer.setName("Loading...")
				
			scoreboardPlayer.setScore(PLAYER_SCORES[playerId])
			add_child(scoreboardPlayer)
					
		else:
			var scoreboardPlayer : ScoreboardPlayer = get_node("%s" % playerId) as ScoreboardPlayer
			if scoreboardPlayer == null:
				continue
			scoreboardPlayer.setScore(PLAYER_SCORES[playerId])
		orderedPlayer.push_back({"id" : playerId, "score" : PLAYER_SCORES[playerId]})
	
	orderedPlayer.sort_custom(func(a, b): return a["score"] > b["score"])
	
	for index in range(0, len(orderedPlayer)):
		var playerId = orderedPlayer[index]
		var scoreboardPlayer : Control = get_node(playerId["id"])
		if scoreboardPlayer == null:
			continue
			
		var positionTween : Tween = get_tree().create_tween()
		positionTween.set_ease(Tween.EASE_IN_OUT)
		var calculatedPosition : Vector2 = Vector2(0, scoreboardPlayer.size.y * index)
		positionTween.set_parallel(true)
		positionTween.tween_property(scoreboardPlayer, "position", calculatedPosition, 0.5)


func onReceivedPlayerData(userData : UserResource):
	var scoreboardPlayer : ScoreboardPlayer = get_node("./%s" % userData.USER_ID) as ScoreboardPlayer
	if scoreboardPlayer == null:
		return
	if userData.USER_ID == scoreboardPlayer.playerId:
		scoreboardPlayer.setName(userData.USERNAME)
