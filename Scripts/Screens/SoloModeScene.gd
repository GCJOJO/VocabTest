extends Control

const ERROR_THRESHOLD : float = 0.8

var QUESTION_TYPE_ORDER : PackedByteArray
var RANDOMIZED_WORDS : Array[WordResource]
var RANDOMIZED_VERBS : Array[VerbResource]
var CURRENT_QUESTION_INDEX : int = -1
var CURRENT_WORD_INDEX : int = -1
var CURRENT_VERB_INDEX : int = -1

var LobbyOptions = {
	"max_words" : 10,
	"categories": GameManager.WORD_CATEGORY | GameManager.VERB_CATEGORY,
	"round_timer": 15, 
	"similarity_threshold": 0.8
}

var roundTimer : int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$GameMenu.hide()
	$Results.hide()
	
	%GameMenu.readyNextQuestion.connect(update_word)
	
	%GameOptions.wordsCountChanged.connect(func(value : int): LobbyOptions["max_words"] = value)
	%GameOptions.categoriesChanged.connect(func(value : int): LobbyOptions["categories"] = value)
	%GameOptions.timerChanged.connect(func(value : int): LobbyOptions["round_timer"] = value)
	%GameOptions.wordsThresholdChanged.connect(func(value : float): LobbyOptions["similarity_threshold"] = value)
	
	await get_tree().create_timer(0.5).timeout
	loadSoloMode()
	
func loadSoloMode() -> void:
	$GameMenu.hide()
	$Results.hide()
	$OptionScreen.show()
	if WordManager.WORDS == null or len(WordManager.WORDS) == 0 or WordManager.VERBS == null or WordManager.VERBS.size() == 0:
		if GameManager.DEBUG_MODE:
			push_warning("No words")
		return
	
	%GameOptions.setup()
	
func startGame() -> void:
	$OptionScreen.hide()
	$Results.hide()
	$GameMenu.show()
	
	CURRENT_QUESTION_INDEX = -1
	CURRENT_VERB_INDEX = -1
	CURRENT_WORD_INDEX = -1
	
	var questionTypes : PackedByteArray = []
	var maxAvailableQuestions : int = 0
	
	print(LobbyOptions["categories"])
	
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
	
	LobbyOptions["max_words"] = min(LobbyOptions["max_words"], maxAvailableQuestions)
	
	var questionTypeMaxAmounts : Dictionary[int, int]
	questionTypeMaxAmounts[GameManager.WORD_CATEGORY] = RANDOMIZED_WORDS.size()
	questionTypeMaxAmounts[GameManager.VERB_CATEGORY] = RANDOMIZED_VERBS.size()
		
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
	print(CURRENT_QUESTION_INDEX)
	if(CURRENT_QUESTION_INDEX >= QUESTION_TYPE_ORDER.size()):
		var correct_words : int = LobbyOptions["max_words"] - %GameMenu.mistakes
		%CorrectWords.text = "%s / %s" % [correct_words, LobbyOptions["max_words"]]
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

func returnToOptionScreen() -> void:
	$Results.hide()
	$OptionScreen.show()
