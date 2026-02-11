extends Node

var WORDS : Array[WordResource]

signal words_loaded()

func load_words() -> void:
	RequestQueue.requestGet("%s/word-list" % GameManager.SERVER_ADRESS, onWordsGet)

func onWordsGet(response):
	if response == null:
		push_error("Respons is null")
		return
	
	if GameManager.DEBUG_MODE:
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
				var pre : String = wordJson["prefix"] if wordJson["prefix"] != null else ""
				
				var unsplittedEn : String = wordJson["anglais"]
				var en : PackedStringArray = unsplittedEn.split("/")
				WORDS.append(WordResource.new(id, fr, con, en, pre))
				
	words_loaded.emit()
				

func checkEnteredWord(wordResource : WordResource, enteredWord : String) -> float:
	var min_distance : float = 1.0
	for englishWord : String in wordResource.ENGLISH:
		min_distance = min(levenshteinDistance(englishWord.to_lower(), enteredWord.to_lower()), min_distance)
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
