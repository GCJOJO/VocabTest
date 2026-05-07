extends Control

func _ready() -> void:
	GameManager.tryLoadPlayerData()
	$LoginScreen.onUserLoggedIn.connect(onUserLoggedIn)
	
	if GameManager.PlayerUUID.is_empty():
		$Header/VBoxContainer/MultiplayerPlayButton.disabled = true
	else:
		onUserLoggedIn(GameManager.PlayerUUID)
		
	WordManager.load_words()
	WordManager.words_loaded.connect(%SoloMode.loadSoloMode)
	%MultiplayerMode.loadMultiplayerScreen()
	

func onUserLoggedIn(userUUID : String) -> void:
	$LoginScreen.hide()
	$WordQuestionViewportTexture.mouse_filter = MouseFilter.MOUSE_FILTER_PASS
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
	%MultiplayerMode.hide()
	%MultiplayerMode.leaveLobby()
	%SoloMode.show()
	%SoloMode.loadSoloMode()
	

func loadMultiplayer() -> void:
	$Header/VBoxContainer/SoloPlayButton.theme_type_variation = ""
	$Header/VBoxContainer/MultiplayerPlayButton.theme_type_variation = "SelectedButton"
	%SoloMode.hide()
	%MultiplayerMode.loadMultiplayerScreen()
	%MultiplayerMode.show()


func logout() -> void:
	GameManager.PlayerUUID = ""
	$Header/VBoxContainer/MultiplayerPlayButton.disabled = false
	$Header/LoginButton.show()
	$Header/LogoutButton.hide()
	
func _on_login_button_pressed() -> void:
	$WordQuestionViewportTexture.mouse_filter = MouseFilter.MOUSE_FILTER_IGNORE
