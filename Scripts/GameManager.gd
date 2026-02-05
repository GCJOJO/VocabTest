extends Node

const SERVER_ADRESS : String = "http://localhost:5762"
const WEBSOCKET_ADRESS : String = "ws://localhost:5763"
const SALT : String = "IOHA64594HGIU@@^ùy_ièLKHJ652746"
const PLAYER_DATA_SAVE_FILE : String = "user://player.data"

var PlayerUUID : String = ""

func savePlayerData() -> void:
	var save_file = FileAccess.open(PLAYER_DATA_SAVE_FILE, FileAccess.WRITE)
	# JSON provides a static method to serialized JSON string.
	var json_string = JSON.stringify({"player_uuid" : PlayerUUID})
	# Store the save dictionary as a new line in the save file.
	save_file.store_line(json_string)
	
func tryLoadPlayerData() -> void:
	if not FileAccess.file_exists(PLAYER_DATA_SAVE_FILE):
		return # Error! We don't have a save to load.

	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	var save_file = FileAccess.open(PLAYER_DATA_SAVE_FILE, FileAccess.READ)
	var json_string = save_file.get_as_text()

	# Creates the helper class to interact with JSON.
	var json = JSON.new()

	# Check if there is any error while parsing the JSON string, skip in case of failure.
	var parse_result = json.parse(json_string)
	if not parse_result == OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		return

	# Get the data from the JSON object.
	var playerData = json.data

	if not playerData.has("player_uuid"):
		return
	
	PlayerUUID = playerData["player_uuid"]
