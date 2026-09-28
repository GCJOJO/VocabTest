extends Control

@onready var header_noise : FastNoiseLite = preload("res://Resources/MainMenu_HeaderNoise.tres")
@export var header_noise_speed : float = 10.0

func _ready() -> void:
	GameManager.check_server_version()
	
	GameManager.tryLoadPlayerData()
	$LoginScreen.onUserLoggedIn.connect(onUserLoggedIn)
	
	if GameManager.PlayerUUID.is_empty():
		$Header/VBoxContainer/MultiplayerPlayButton.disabled = true
	else:
		onUserLoggedIn(GameManager.PlayerUUID)
	
	print("Fetching Words")
	WordManager.words_loaded.connect(%SoloMode.loadSoloMode)
	WordManager.load_words()
	

func _process(delta: float) -> void:
	header_noise.offset.x += delta * header_noise_speed

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
