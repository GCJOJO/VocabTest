extends Control

@export var player_spectator_screen : PackedScene = preload("uid://dy8q7wis4ne1e")

func _ready() -> void:
	get_tree().root.size_changed.connect(on_viewport_size_changed)
	
	on_viewport_size_changed()

func on_viewport_size_changed() -> void:
	var container_width : float = $SmoothScrollContainer.size.x
	print("Container width : %s" % container_width)
	
	var instance = player_spectator_screen.instantiate()
	
	if instance is not Control:
		instance.queue_free()
		return
	
	var min_instance_width : float = (instance as Control).get_combined_minimum_size().x
	var columns : int = floor(container_width / min_instance_width)
	var separation_percentage : float = (container_width / min_instance_width) - columns
	@warning_ignore("narrowing_conversion")
	var separation : int = (separation_percentage * container_width) / (8 * columns)
	%PlayerContainer.columns = max(columns, 1)
	%PlayerContainer.add_theme_constant_override("h_separation", separation)
	instance.queue_free()

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
		
	
func set_word(new_word : WordResource) -> void:
	%QuestionCategory.text = "[b][i]Mots[/i][/b]"
	%Question.text = new_word.FRENCH
	
func set_verb(new_verb : VerbResource) -> void:
	%QuestionCategory.text = "[b][i]Verbes[/i][/b]"
	%Question.text = new_verb.FRENCH
	
func set_country(new_country : WordResource) -> void:
	%QuestionCategory.text = "[b][i]Pays[/i][/b]"
	%Question.text = new_country.FRENCH
	
func set_grammar(new_grammar : WordResource) -> void:
	%QuestionCategory.text = "[b][i]Grammaire[/i][/b]"
	%Question.text = new_grammar.FRENCH
	
func update_player_state(player_id : String, new_state : SpectatorScreenPlayer.PlayerState):
	var player_screen : SpectatorScreenPlayer = %PlayerContainer.get_node_or_null(player_id) as SpectatorScreenPlayer
	if player_screen == null: return
	
	player_screen.update_state(new_state)

func update_player_score(player_id : String, new_score : float):
	var player_screen : SpectatorScreenPlayer = %PlayerContainer.get_node_or_null(player_id) as SpectatorScreenPlayer
	if player_screen == null: return
	
	player_screen.update_score(new_score)
