extends Control

var lobbyId : String = ""

var httpRequest : HTTPRequest

func _ready() -> void:
	httpRequest = HTTPRequest.new()
	add_child(httpRequest)
	httpRequest.request_completed.connect(self.http_request_completed)
	
	createLobby()

func createLobby() -> void:
	var json : String = JSON.stringify({"player_name": "Godette", "host_ip" : ""})
	
	var error := httpRequest.request("http://localhost:5762/vocab-test", ["Content-Type: application/json"], HTTPClient.METHOD_POST, json)
	if error != OK:
		push_error("Une erreur est survenue dans la requête HTTP.")
	
	print("Creating Server")
	ConnectionManager.startServer()
	
	
	
func startLobby() -> void:
	var json : String = JSON.stringify({"lobbyId": lobbyId})
	

func http_request_completed(result : int, response_code : int, headers : PackedStringArray, body : PackedByteArray):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()

	# Will print the user agent string used by the HTTPRequest node (as recognized by httpbin.org).
	print(response)
	if not response.has("action"):
		return
	var action = response["action"]
