extends Node

var WORDS : Array[WordResource]
#var httpRequest : HTTPRequest

signal words_loaded()

# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#httpRequest = HTTPRequest.new()
	#add_child(httpRequest)
	#httpRequest.request_completed.connect(self.http_request_completed)

func load_words() -> void:
	#var error := httpRequest.request("%s/vocab-test" % GameManager.SERVER_ADRESS)
	#if error != OK:
		#push_error("Une erreur est survenue dans la requête HTTP.")
	RequestQueue.requestGet("%s/vocab-test" % GameManager.SERVER_ADRESS, onWordsGet)

func onWordsGet(response):
	print(response["action"])
	
	var action = response["action"]
	match action:
		"set-words":
			WORDS.clear()
			var new_words = response["words"]
			for wordJson in new_words:
				var id : int = wordJson["identifiant"]
				var fr : String = wordJson["français"]
				var con : String = wordJson["contexte"] if wordJson["contexte"] != null else ""
				
				var unsplittedEn : String = wordJson["anglais"]
				var en : PackedStringArray = unsplittedEn.split("/")
				WORDS.append(WordResource.new(id, fr, con, en))
				
	words_loaded.emit()
				
#func checkEnteredWord(wordResource : WordResource, enteredWord : String) -> float:
	#for englishWord : String in wordResource.ENGLISH:
		#if enteredWord.to_lower().contains(englishWord.to_lower()): # TODO : Better Checks, Check for distance and give less points but still "correct" answer
			#return true
	#return false
	
func checkEnteredWord(wordResource : WordResource, enteredWord : String) -> float:
	var min_distance : float = 1.0
	for englishWord : String in wordResource.ENGLISH:
		min_distance = min(levenshteinDistance(englishWord, enteredWord), min_distance)
	return (1.0 - min_distance)

func levenshteinDistance(wordA : String, wordB : String) -> float:
	# Create an empty matrix with the dimensions of the lengths of the strings plus one
	var maxLength : float = max(wordA.length(), wordB.length())
	var matrix = []
	for i in range(len(wordA) + 1):
		matrix.append([])
		for j in range(len(wordB) + 1):
			matrix[i].append(0)

	# Initialize the first row and column with the indices of the strings
	for i in range(len(wordA) + 1):
		matrix[i][0] = i
	for j in range(len(wordB) + 1):
		matrix[0][j] = j

	# Fill the rest of the matrix with the minimum values of the possible operations
	for i in range(1, len(wordA) + 1):
		for j in range(1, len(wordB) + 1):
			var cost
			# If the characters are equal, there is no additional cost
			if wordA[i - 1] == wordB[j - 1]:
				cost = 0
			else:
				cost = 1
			# The value of the cell is the minimum between deleting, inserting or replacing the character
			matrix[i][j] = min(matrix[i - 1][j] + 1, matrix[i][j - 1] + 1, matrix[i - 1][j - 1] + cost)

	# The last value of the matrix is ​​the Levenshtein distance between the two strings
	return matrix[len(wordA)][len(wordB)] / maxLength
