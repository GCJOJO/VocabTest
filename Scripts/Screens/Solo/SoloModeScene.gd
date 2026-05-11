extends Control

const ERROR_THRESHOLD : float = 0.8

var QUESTION_TYPE_ORDER : PackedByteArray
var RANDOMIZED_WORDS : Array[WordResource]
var RANDOMIZED_VERBS : Array[VerbResource]
var RANDOMIZED_COUNTRIES : Array[WordResource]
var RANDOMIZED_GRAMMAR : Array[WordResource]

var CURRENT_QUESTION_INDEX : int = -1
var CURRENT_WORD_INDEX : int = -1
var CURRENT_VERB_INDEX : int = -1
var CURRENT_COUNTRY_INDEX : int = -1
var CURRENT_GRAMMAR_INDEX : int = -1

enum SoloGamemode
{
	CLASSIC = 0,
	ONE_SHOT = 1
}

var current_gamemode : SoloGamemode = SoloGamemode.CLASSIC

var LobbyOptions = {
	"max_words" : 10,
	"categories": GameManager.WORD_CATEGORY | GameManager.VERB_CATEGORY | GameManager.COUNTRY_CATEGORY | GameManager.GRAMMAR_CATEGORY,
	"round_timer": 15, 
	"similarity_threshold": 0.8
}

signal word_changed()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$GameMenu.hide()
	$Results.hide()
	
	%GameMenu.readyNextQuestion.connect(update_word)
	
	%GameOptions.wordsCountChanged.connect(func(value : int): LobbyOptions["max_words"] = value)
	%GameOptions.categoriesChanged.connect(func(value : int): LobbyOptions["categories"] = value)
	%GameOptions.timerChanged.connect(func(value : int): LobbyOptions["round_timer"] = value)
	%GameOptions.wordsThresholdChanged.connect(func(value : float): LobbyOptions["similarity_threshold"] = value)
	%GameOptions.gamemode_changed.connect(on_gamemode_changed)
	
	%GameMenu.on_mistake.connect(on_mistake)
	
	await get_tree().create_timer(0.5).timeout
	loadSoloMode()
	
func loadSoloMode() -> void:
	$GameMenu.hide()
	$Results.hide()
	$OptionScreen.show()
	if WordManager.WORDS == null or WordManager.WORDS.size() == 0 or WordManager.VERBS == null or WordManager.VERBS.size() == 0 or WordManager.COUNTRIES == null or WordManager.COUNTRIES.size() == 0 or WordManager.GRAMMAR == null or WordManager.GRAMMAR.size() == 0:
		if GameManager.DEBUG_MODE:
			push_warning("No words")
		return
	
	%GameOptions.setup()
	
func startGame() -> void:
	$OptionScreen.hide()
	$Results.hide()
	$GameMenu.show()
	
	if current_gamemode == SoloGamemode.ONE_SHOT:
		LobbyOptions["max_words"] = WordManager.get_total_question_amount()
		LobbyOptions["categories"] = GameManager.WORD_CATEGORY | GameManager.VERB_CATEGORY | GameManager.COUNTRY_CATEGORY | GameManager.GRAMMAR_CATEGORY
		LobbyOptions["round_timer"] = 30
		LobbyOptions["similarity_threshold"] = 1
	
	CURRENT_QUESTION_INDEX = -1
	CURRENT_VERB_INDEX = -1
	CURRENT_WORD_INDEX = -1
	CURRENT_COUNTRY_INDEX = -1
	CURRENT_GRAMMAR_INDEX = -1
	
	var questionTypes : PackedByteArray = []
	var maxAvailableQuestions : int = 0
	
	if GameManager.DEBUG_MODE:
		print("Chosen Categories : %s" % LobbyOptions["categories"])
	
	if LobbyOptions["categories"] & GameManager.WORD_CATEGORY:
		CURRENT_WORD_INDEX = 0
		RANDOMIZED_WORDS = WordManager.WORDS
		RANDOMIZED_WORDS.shuffle()
		questionTypes.push_back(GameManager.WORD_CATEGORY)
		maxAvailableQuestions += RANDOMIZED_WORDS.size()
	
	if LobbyOptions["categories"] & GameManager.VERB_CATEGORY:
		CURRENT_VERB_INDEX = 0
		RANDOMIZED_VERBS = WordManager.VERBS
		RANDOMIZED_VERBS.shuffle()
		questionTypes.push_back(GameManager.VERB_CATEGORY)
		maxAvailableQuestions += RANDOMIZED_VERBS.size()
		
	if LobbyOptions["categories"] & GameManager.COUNTRY_CATEGORY:
		CURRENT_COUNTRY_INDEX = 0
		RANDOMIZED_COUNTRIES = WordManager.COUNTRIES
		RANDOMIZED_COUNTRIES.shuffle()
		questionTypes.push_back(GameManager.COUNTRY_CATEGORY)
		maxAvailableQuestions += RANDOMIZED_COUNTRIES.size()
		
	if LobbyOptions["categories"] & GameManager.GRAMMAR_CATEGORY:
		CURRENT_GRAMMAR_INDEX = 0
		RANDOMIZED_GRAMMAR = WordManager.GRAMMAR
		RANDOMIZED_GRAMMAR.shuffle()
		questionTypes.push_back(GameManager.GRAMMAR_CATEGORY)
		maxAvailableQuestions += RANDOMIZED_GRAMMAR.size()
	
	LobbyOptions["max_words"] = min(LobbyOptions["max_words"], maxAvailableQuestions)
	
	var questionTypeMaxAmounts : Dictionary[int, int]
	questionTypeMaxAmounts[GameManager.WORD_CATEGORY] = RANDOMIZED_WORDS.size()
	questionTypeMaxAmounts[GameManager.VERB_CATEGORY] = RANDOMIZED_VERBS.size()
	questionTypeMaxAmounts[GameManager.COUNTRY_CATEGORY] = RANDOMIZED_COUNTRIES.size()
	questionTypeMaxAmounts[GameManager.GRAMMAR_CATEGORY] = RANDOMIZED_GRAMMAR.size()
		
	# make question type order
	var questionTypeAmounts : Dictionary[int, int]
	for type in questionTypes:
		questionTypeAmounts[type] = 0
	
	QUESTION_TYPE_ORDER.clear()
	QUESTION_TYPE_ORDER.resize(LobbyOptions["max_words"])
	for i in range(LobbyOptions["max_words"]):
		var type : int = -1
		while true:
			type = questionTypes[randi_range(0, questionTypes.size() - 1)]
			if questionTypeAmounts[type] < questionTypeMaxAmounts[type]:
				break
		
		QUESTION_TYPE_ORDER[i] = type
		questionTypeAmounts[type] += 1
		
	print(QUESTION_TYPE_ORDER)
	
	RANDOMIZED_WORDS = WordManager.WORDS
	RANDOMIZED_WORDS.shuffle()
	
	%GameMenu.setup(true, LobbyOptions["max_words"], LobbyOptions["similarity_threshold"], LobbyOptions["round_timer"], true)
	update_word()

func update_word() -> void:
	CURRENT_QUESTION_INDEX += 1
	if(CURRENT_QUESTION_INDEX >= QUESTION_TYPE_ORDER.size()):
		var correct_words : int = LobbyOptions["max_words"] - %GameMenu.mistakes
		%CorrectWords.text = "%s / %s" % [correct_words, LobbyOptions["max_words"]]
		
		if current_gamemode != SoloGamemode.ONE_SHOT:
			#print("Total Response Time : %ss, Current Question Index : %s" % [$GameMenu.total_response_time, CURRENT_QUESTION_INDEX])
			var average_response_time : float = $GameMenu.total_response_time / max(CURRENT_QUESTION_INDEX, 1)
			%AverageTime.text = "%ss" % average_response_time
		
		$Results.show()
		$GameMenu.hide()
		return
		
	match QUESTION_TYPE_ORDER[CURRENT_QUESTION_INDEX]:
		0:
			var correct_words : int = LobbyOptions["max_words"] - %WordQuestion.mistakes
			%CorrectWords.text = "%s / %s" % [correct_words, LobbyOptions["max_words"]]
			$Results.show()
			$GameMenu.hide()
		GameManager.WORD_CATEGORY:
			%GameMenu.setWord(RANDOMIZED_WORDS[CURRENT_WORD_INDEX])
			CURRENT_WORD_INDEX += 1
		GameManager.VERB_CATEGORY:
			%GameMenu.setVerb(RANDOMIZED_VERBS[CURRENT_VERB_INDEX])
			CURRENT_VERB_INDEX += 1
		GameManager.COUNTRY_CATEGORY:
			%GameMenu.setWord(RANDOMIZED_COUNTRIES[CURRENT_COUNTRY_INDEX])
			CURRENT_COUNTRY_INDEX += 1
		GameManager.GRAMMAR_CATEGORY:
			%GameMenu.setWord(RANDOMIZED_GRAMMAR[CURRENT_GRAMMAR_INDEX])
			CURRENT_GRAMMAR_INDEX += 1
			
	word_changed.emit()

func returnToOptionScreen() -> void:
	$Results.hide()
	$OptionScreen.show()

func on_mistake() -> void:
	if current_gamemode == SoloGamemode.ONE_SHOT:
		var score : int = CURRENT_QUESTION_INDEX
		%GameMenu.mistakes += WordManager.get_total_question_amount() - (CURRENT_QUESTION_INDEX + 1)
		CURRENT_QUESTION_INDEX = QUESTION_TYPE_ORDER.size() + 1
		
		var update_average_time_lambda : Callable = func():
			var average_response_time : float = $GameMenu.total_response_time / max(score, 1)
			%AverageTime.text = "%ss" % average_response_time
			
		update_average_time_lambda.call_deferred()
		
		if not GameManager.PlayerUUID.is_empty():
			var json : String = JSON.stringify({
				"player_id" : GameManager.PlayerUUID, 
				"new_score" : score
			})
			RequestQueue.requestPost("%s/update-score" % GameManager.SERVER_ADRESS, on_post_new_score, json)
			

func on_post_new_score(data : Dictionary) -> void:
	if data.has("action"):
		match data["action"]:
			"score-updated":
				print("Score updated for player %s, new score %s" % [data["player_id"], data["new_score"]])
				%GameOptions.update_leaderboard()
			"score-update-failed":
				push_error("Unable to update player score")

func on_gamemode_changed(new_gamemode : int) -> void:
	current_gamemode = new_gamemode as SoloGamemode
	
