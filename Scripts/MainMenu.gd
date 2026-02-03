extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func loadSoloMode() -> void:
	WordManager.load_words()
	var callback = func():
		get_tree().change_scene_to_file("res://Scenes/solo_mode.tscn")
	WordManager.words_loaded.connect(callback)
	

func loadMultiplayer() -> void:
	get_tree().change_scene_to_file("res://Scenes/mutliplayer_lobby.tscn")
