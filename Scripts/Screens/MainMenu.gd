extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.tryLoadPlayerData()
	
	if GameManager.PlayerUUID.is_empty():
		$Header/VBoxContainer/MultiplayerPlayButton.disabled = true
		$LoginScreen.onUserLoggedIn.connect(onUserLoggedIn)
	else:
		onUserLoggedIn(GameManager.PlayerUUID)
		
	WordManager.load_words()
	WordManager.words_loaded.connect(%SoloMode.loadSoloMode)
	#$MutliplayerScreen.loadMultiplayerScreen()
	

func onUserLoggedIn(userUUID : String) -> void:
	$LoginScreen.hide()
	GameManager.PlayerUUID = userUUID
	$Header/VBoxContainer/MultiplayerPlayButton.disabled = false
	
	GameManager.getPlayerData(userUUID)
	
	GameManager.savePlayerData()
	
	$Header/LoginButton.hide()
	$LoginScreen.hide()
	$Header/LogoutButton.show()

func loadSoloMode() -> void:
	$Header/VBoxContainer/SoloPlayButton.theme_type_variation = "SelectedButton"
	$Header/VBoxContainer/MultiplayerPlayButton.theme_type_variation = ""
	$MutliplayerScreen.hide()
	$MutliplayerScreen.leaveLobby()
	$SoloMode.show()
	$SoloMode.loadSoloMode()
	pass
	#var callback = func():
	#	get_tree().change_scene_to_file("res://Scenes/solo_mode.tscn")
	#WordManager.words_loaded.connect(callback)
	

func loadMultiplayer() -> void:
	#get_tree().change_scene_to_file("res://Scenes/mutliplayer_screen.tscn")
	$Header/VBoxContainer/SoloPlayButton.theme_type_variation = ""
	$Header/VBoxContainer/MultiplayerPlayButton.theme_type_variation = "SelectedButton"
	$SoloMode.hide()
	$MutliplayerScreen.loadMultiplayerScreen()
	$MutliplayerScreen.show()


func logout() -> void:
	GameManager.PlayerUUID = ""
	$Header/VBoxContainer/MultiplayerPlayButton.disabled = false
	$Header/LoginButton.show()
	$Header/LogoutButton.hide()
	
