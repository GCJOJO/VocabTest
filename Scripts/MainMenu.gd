extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.tryLoadPlayerData()
	
	if GameManager.PlayerUUID.is_empty():
		$MultiplayerPlayButton.disabled = true
		$LoginScreen.onUserLoggedIn.connect(onUserLoggedIn)
	else:
		onUserLoggedIn(GameManager.PlayerUUID)
		
	WordManager.load_words()


func onUserLoggedIn(userUUID : String) -> void:
	$LoginScreen.hide()
	GameManager.PlayerUUID = userUUID
	$MultiplayerPlayButton.disabled = false
	
	GameManager.getPlayerData(userUUID)
	
	GameManager.savePlayerData()
	
	$LoginButton.hide()
	$LoginScreen.hide()
	$LogoutButton.show()

func loadSoloMode() -> void:
	WordManager.load_words()
	var callback = func():
		get_tree().change_scene_to_file("res://Scenes/solo_mode.tscn")
	WordManager.words_loaded.connect(callback)
	

func loadMultiplayer() -> void:
	get_tree().change_scene_to_file("res://Scenes/mutliplayer_screen.tscn")


func logout() -> void:
	GameManager.PlayerUUID = ""
	$MultiplayerPlayButton.disabled = false
	$LoginButton.show()
	$LogoutButton.hide()
	
