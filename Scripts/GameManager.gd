extends Node

const SERVER_ADRESS : String = "https://88.190.53.5:33362"
const WEBSOCKET_ADRESS : String = "wss://88.190.53.5:33363"
#const SERVER_ADRESS : String = "https://localhost:5762"
#const WEBSOCKET_ADRESS : String = "wss://localhost:5763"
const SALT : String = "IOHA64594HGIU@@^ùy_ièLKHJ652746"
const PLAYER_DATA_SAVE_FILE : String = "user://player.data"
const VERSION_STRING = "0.0.7"
@onready var DEBUG_MODE : bool = OS.is_debug_build() or Engine.is_editor_hint()

const WORD_CATEGORY : int    = 1 << 0
const VERB_CATEGORY : int    = 1 << 1
const COUNTRY_CATEGORY : int = 1 << 2
const GRAMMAR_CATEGORY : int = 1 << 3

enum LobbyMode
{
	Classic = 0,
	BattleRoyale = 1
}

var PlayerUUID : String = ""

var cachedPlayers : Dictionary = {}

signal userInfoChanged(userId : String, userData : UserResource)

func getPlayerData(userId : String) -> UserResource:
	if cachedPlayers.has(userId):
		return cachedPlayers[userId]
	
	RequestQueue.requestGet("%s/user/%s" % [SERVER_ADRESS, userId], onUserGet)
	return null

func onUserGet(response) -> void:
	if response == null:
		return
	
	if not response.has("action"):
		return
	var action = response["action"]
	if action != "user-info":
		return
		
	var user = response["user_info"]
	var userId : String = user["uuid"]
	var newUser : UserResource = UserResource.new(userId, user["username"], user["first_name"], user["last_name"])
	cachedPlayers[userId] = newUser
	userInfoChanged.emit(userId, newUser)
	if GameManager.DEBUG_MODE:
		print("User info changed for user id : %s", userId)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("fullscreen"):
		var mode := DisplayServer.window_get_mode()
		var is_window: bool = mode != DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if is_window else DisplayServer.WINDOW_MODE_WINDOWED)

func savePlayerData() -> void:
	var save_file = FileAccess.open(PLAYER_DATA_SAVE_FILE, FileAccess.WRITE)
	var json_string = JSON.stringify({"player_uuid" : PlayerUUID})
	save_file.store_line(json_string)
	
func tryLoadPlayerData() -> void:
	if not FileAccess.file_exists(PLAYER_DATA_SAVE_FILE):
		return

	var save_file = FileAccess.open(PLAYER_DATA_SAVE_FILE, FileAccess.READ)
	var json_string = save_file.get_as_text()

	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if not parse_result == OK:
		if GameManager.DEBUG_MODE:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		return

	var playerData = json.data

	if not playerData.has("player_uuid"):
		return
	
	PlayerUUID = playerData["player_uuid"]
	GameManager.getPlayerData(PlayerUUID)
