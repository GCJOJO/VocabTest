extends Node

var WORDS : Array[WordResource]
var VERBS : Array[VerbResource]
var COUNTRIES : Array[WordResource]
var GRAMMAR : Array[WordResource]

signal words_loaded()
signal verbs_loaded()
signal countries_loaded()
signal grammar_loaded()

func load_words() -> void:
	RequestQueue.requestGet("%s/words-list" % GameManager.SERVER_ADRESS, onWordsGet)
	RequestQueue.requestGet("%s/verbs-list" % GameManager.SERVER_ADRESS, onVerbsGet)
	RequestQueue.requestGet("%s/countries-list" % GameManager.SERVER_ADRESS, onCountriesGet)
	RequestQueue.requestGet("%s/grammar-list" % GameManager.SERVER_ADRESS, onGrammarGet)

func onWordsGet(response):
	if response == null:
		push_error("Respons is null")
		return
	
	if GameManager.DEBUG_MODE:
		print(response["action"])
	
	var action = response["action"]
	if action != "words-list":
		return
	
	WORDS.clear()
	var new_words = response["words"]
	for wordJson in new_words:
		var id : int = wordJson["identifiant"]
		var fr : String = wordJson["français"]
		var con : String = wordJson["contexte"] if wordJson["contexte"] != null else ""
		var pre : String = wordJson["prefix"] if (wordJson.has("prefix") and wordJson["prefix"] != null) else ""
		
		var unsplittedEn : String = wordJson["anglais"]
		var en : PackedStringArray = unsplittedEn.split("/")
		WORDS.append(WordResource.new(id, fr, con, en, pre))
				
	words_loaded.emit()

func onVerbsGet(response) -> void:
	if response == null:
		return
		
	var action = response["action"]
	if action != "verbs-list":
		return
		
	VERBS.clear()
	var new_verbs = response["verbs"]
	for wordJson in new_verbs:
		var id : int = wordJson["id"]
		var fr : String = wordJson["french"]
		var con : String = wordJson["context"] if wordJson["context"] != null else ""
		var inf : PackedStringArray = wordJson["infinitive"].split("/")
		var pre : PackedStringArray = wordJson["preterit"].split("/")
		var pp : PackedStringArray = wordJson["past_participle"].split("/")
		VERBS.append(VerbResource.new(id, fr, con, inf, pre, pp))
				
	verbs_loaded.emit()

func onCountriesGet(response) -> void:
	if response == null:
		push_error("Respons is null")
		return
	
	if GameManager.DEBUG_MODE:
		print(response["action"])
	
	var action = response["action"]
	if action != "countries-list":
		return
	
	COUNTRIES.clear()
	var new_words = response["countries"]
	for wordJson in new_words:
		var id : int = wordJson["id"]
		var fr : String = wordJson["french"]
		var en : PackedStringArray = [wordJson["english"]]
		var con : String = "" # No Context for countries
		var pre : String = "" # No prefix for countries
		
		COUNTRIES.append(WordResource.new(id, fr, con, en, pre))
		
	countries_loaded.emit()

func onGrammarGet(response):
	if response == null:
		push_error("Respons is null")
		return
	
	if GameManager.DEBUG_MODE:
		print(response["action"])
	
	var action = response["action"]
	if action != "grammar-list":
		return
	
	GRAMMAR.clear()
	var new_words = response["grammar"]
	for wordJson in new_words:
		var id : int = wordJson["id"]
		var fr : String = wordJson["french"]
		var con : String = wordJson["category"] if wordJson["category"] != null else ""
		var pre : String = ""
		
		var unsplittedEn : String = wordJson["english"]
		var en : PackedStringArray = unsplittedEn.split("/")
		GRAMMAR.append(WordResource.new(id, fr, con, en, pre))
		
	grammar_loaded.emit()

func checkEnteredWord(wordResource : WordResource, enteredWord : String) -> float:
	var min_distance : float = 1.0
	for englishWord : String in wordResource.ENGLISH:
		min_distance = min(levenshteinDistance(englishWord.to_lower(), enteredWord.to_lower()), min_distance)
	return (1.0 - min_distance)

func checkEnteredVerb(verbResource : VerbResource, enteredVerbs : PackedStringArray) -> float:
	var infDistance : float = 1.0
	var preDistance : float = 1.0
	var ppDistance : float = 1.0
	for inf : String in verbResource.INFINITIVE:
		infDistance = min(levenshteinDistance(inf.to_lower(), enteredVerbs[0].to_lower()), infDistance)
	for pre : String in verbResource.PRETERIT:
		preDistance = min(levenshteinDistance(pre.to_lower(), enteredVerbs[1].to_lower()), preDistance)
	for pp : String in verbResource.PRESENT_PARTICIPLE:
		ppDistance = min(levenshteinDistance(pp.to_lower(), enteredVerbs[2].to_lower()), ppDistance)
	return 1 - ((infDistance + preDistance + ppDistance) / 3.0)

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
