extends Node

const SERVER_ADRESS : String = "http://localhost:5762"
const WEBSOCKET_ADRESS : String = "ws://localhost:5763"
const SALT : String = "IOHA64594HGIU@@^ùy_ièLKHJ652746"
const PLAYER_DATA_SAVE_FILE : String = "user://player.data"

var PlayerUUID : String = ""

var cachedPlayers : Dictionary = {}

signal userInfoChanged(userId : String, userData : UserResource)

func getPlayerData(userId : String):
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
	print("User info changed for user id : %s", userId)

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
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		return

	var playerData = json.data

	if not playerData.has("player_uuid"):
		return
	
	PlayerUUID = playerData["player_uuid"]
	GameManager.getPlayerData(PlayerUUID)
