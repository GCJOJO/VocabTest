extends Control

var mistakes : float = 0.0

var showInstantResults : bool = false
var currentQuestionNumber : int = 0
var maxQuestionNumber : int = 0
var roundTimer : int = 0
var maxRoundTimer : int = 0
var questionSimilarityThreshold : float = -1.0

var useLocalTimer : bool = false
var currentQuestionCategory : int = 0

signal answerEntered(questionType : int, answer)
signal readyNextQuestion()

func _ready() -> void:	
	%WordQuestion.readyNextQuestion.connect(readyNextQuestion.emit)
	%VerbQuestion.readyNextQuestion.connect(readyNextQuestion.emit)
	
	%WordQuestion.enteredWord.connect(func(answer): 
		onAnswerEntered(currentQuestionCategory, answer))
	%WordQuestion.wordChanged.connect(onQuestionChanged)
		
	%VerbQuestion.enteredVerb.connect(func(answer): 
		onAnswerEntered(currentQuestionCategory, answer))
	%VerbQuestion.verbChanged.connect(onQuestionChanged)
		
	$Timer.timeout.connect(onTimerTick)

func onQuestionChanged(_newQuestion):
	if useLocalTimer:
		$Timer.paused = false
	roundTimer = maxRoundTimer + 1
	onTimerTick()

func onAnswerEntered(questionType : int, answer):
	answerEntered.emit(questionType, answer)
	if useLocalTimer:
		$Timer.paused = true
	if(showInstantResults):
		showResults(answer)

func setup(show_instant_results : bool, max_question_number : int, question_similarity_threshold : float, round_timer : int, use_local_timer : bool) -> void:
	showInstantResults = show_instant_results
	currentQuestionNumber = 0
	currentQuestionCategory = 0
	maxQuestionNumber = max_question_number
	questionSimilarityThreshold = question_similarity_threshold
	maxRoundTimer = round_timer
	roundTimer = round_timer
	useLocalTimer = use_local_timer
	
	$TimerScreen.setMaxRoundTimer(maxRoundTimer)
	
	mistakes = 0.0
	
	updateStatus()
	
	if use_local_timer:
		$Timer.start()
	
func setWord(newWord : WordResource) -> void:
	currentQuestionCategory = GameManager.WORD_CATEGORY
	%WordQuestion.changeWord(newWord)
	%WordQuestion.visible = true
	%VerbQuestion.visible = false
	incrementQuestionNumber()
	updateStatus()
	
func setVerb(newVerb : VerbResource) -> void:
	currentQuestionCategory = GameManager.VERB_CATEGORY
	%VerbQuestion.changeVerb(newVerb)
	%WordQuestion.visible = false
	%VerbQuestion.visible = true
	incrementQuestionNumber()
	updateStatus()
	
func setCountry(newWord : WordResource) -> void:
	currentQuestionCategory = GameManager.COUNTRY_CATEGORY
	%WordQuestion.changeWord(newWord)
	%WordQuestion.visible = true
	%VerbQuestion.visible = false
	incrementQuestionNumber()
	updateStatus()
	
func setGrammar(newWord : WordResource) -> void:
	currentQuestionCategory = GameManager.GRAMMAR_CATEGORY
	%WordQuestion.changeWord(newWord)
	%WordQuestion.visible = true
	%VerbQuestion.visible = false
	incrementQuestionNumber()
	updateStatus()

func incrementQuestionNumber() -> void:
	currentQuestionNumber += 1

func showResultsSimilarity(answerSimilarity : float, similarityThreshold : float):
	var errorAmount : float = 0.0
	match currentQuestionCategory:
		GameManager.WORD_CATEGORY:
			errorAmount = %WordQuestion.showResult(answerSimilarity, similarityThreshold, false)
		GameManager.VERB_CATEGORY:
			errorAmount = %VerbQuestion.showResult(answerSimilarity, similarityThreshold, false)
		GameManager.COUNTRY_CATEGORY:
			errorAmount = %WordQuestion.showResult(answerSimilarity, similarityThreshold, false)
		GameManager.GRAMMAR_CATEGORY:
			errorAmount = %WordQuestion.showResult(answerSimilarity, similarityThreshold, false)
		
	print("Error amount : %s" % errorAmount)
	
	mistakes += errorAmount
	if errorAmount >= 1.0:
		%ExplosionSprite.show()
		%ExplosionSprite.play(&"default")
		$ExplosionSound.play()
	updateStatus()

func showResults(answer) -> void:
	var errorAmount : float = 0.0
	match currentQuestionCategory:
		GameManager.WORD_CATEGORY:
			var curWord : WordResource = %WordQuestion.currentWord
			var similarity : float = WordManager.checkEnteredWord(curWord, answer)
			print("Similarity %s" % similarity)
			errorAmount = %WordQuestion.showResult(similarity, questionSimilarityThreshold, showInstantResults)
		GameManager.VERB_CATEGORY:
			if answer.is_empty():
				answer = []
				answer.resize(3)
			var curVerb : VerbResource = %VerbQuestion.currentVerb
			var similarity : float = WordManager.checkEnteredVerb(curVerb, answer)
			print("Similarity %s" % similarity)
			errorAmount = %VerbQuestion.showResult(similarity, questionSimilarityThreshold, showInstantResults)
		GameManager.COUNTRY_CATEGORY:
			var curWord : WordResource = %WordQuestion.currentWord
			var similarity : float = WordManager.checkEnteredWord(curWord, answer)
			print("Similarity %s" % similarity)
			errorAmount = %WordQuestion.showResult(similarity, questionSimilarityThreshold, showInstantResults)
		GameManager.GRAMMAR_CATEGORY:
			var curWord : WordResource = %WordQuestion.currentWord
			var similarity : float = WordManager.checkEnteredWord(curWord, answer)
			print("Similarity %s" % similarity)
			errorAmount = %WordQuestion.showResult(similarity, questionSimilarityThreshold, showInstantResults)
		
	print("Error amount : %s" % errorAmount)
	
	mistakes += errorAmount
	if errorAmount >= 1.0:
		%ExplosionSprite.show()
		%ExplosionSprite.play(&"default")
		$ExplosionSound.play()
	updateStatus()

func onTimerTick() -> void:
	if roundTimer > 0:
		roundTimer -= 1
		if roundTimer == 0:
			showResults("")
		$TimerScreen.setRoundTimer(roundTimer)
	
func setTimer(currentTimer : int) -> void:
	roundTimer = currentTimer
	$TimerScreen.setRoundTimer(roundTimer)
	
func updateStatus() -> void:
	%Status.text = "[center][font_size=24]%d/%d\nFautes : %.1f" % [currentQuestionNumber, maxQuestionNumber, mistakes]
