extends Control

@export var player_spectator_screen : PackedScene = preload("uid://dy8q7wis4ne1e")

# Dictionnary of player IDs => score
func load_players(players : Dictionary[String, float]) -> void:
	for child in %PlayerContainer.get_children():
		child.queue_free()
	
	print(players.keys())
	print(players.values())
	
	for player in players.keys():
		var player_screen : SpectatorScreenPlayer = player_spectator_screen.instantiate() as SpectatorScreenPlayer
		if player_screen == null: continue
		
		player_screen.setup(player, players[player])
		player_screen.name = player
		%PlayerContainer.add_child(player_screen)
		
	
func update_player_state(player_id : String, new_state : SpectatorScreenPlayer.PlayerState):
	var player_screen : SpectatorScreenPlayer = %PlayerContainer.get_node_or_null(player_id) as SpectatorScreenPlayer
	if player_screen == null: return
	
	player_screen.update_state(new_state)

func update_player_score(player_id : String, new_score : float):
	var player_screen : SpectatorScreenPlayer = %PlayerContainer.get_node_or_null(player_id) as SpectatorScreenPlayer
	if player_screen == null: return
	
	player_screen.update_score(new_score)
