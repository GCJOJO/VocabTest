extends Node

var WORDS : Array[WordResource]
var httpRequest : HTTPRequest

signal words_loaded()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	httpRequest = HTTPRequest.new()
	add_child(httpRequest)
	httpRequest.request_completed.connect(self.http_request_completed)

func load_words() -> void:
	var error := httpRequest.request("http://localhost:5762/vocab-test")
	if error != OK:
		push_error("Une erreur est survenue dans la requête HTTP.")

func http_request_completed(result : int, response_code : int, headers : PackedStringArray, body : PackedByteArray):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()

	# Will print the user agent string used by the HTTPRequest node (as recognized by httpbin.org).
	print(response["action"])
	
	var action = response["action"]
	match action:
		"set-words":
			WORDS.clear()
			var new_words = response["words"]
			for wordJson in new_words:
				var id : int = wordJson["identifiant"]
				var fr : String = wordJson["français"]
				var unsplittedEn : String = wordJson["anglais"]
				var en : PackedStringArray = unsplittedEn.split("/")
				WORDS.append(WordResource.new(id, fr, en))
				
	words_loaded.emit()
				
func checkEnteredWord(wordResource : WordResource, enteredWord : String) -> bool:
	for englishWord : String in wordResource.ENGLISH:
		if enteredWord.to_lower().contains(englishWord.to_lower()): # TODO : Better Checks, Check for distance and give less points but still "correct" answer
			return true
	return false
