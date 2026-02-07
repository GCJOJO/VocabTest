extends Control
class_name WordQuestionScreen

var showInstantResult : bool
var maxQuestionNumber: int
var currentQuestionNumber: int = 0
var mistakes: int = 0

var hasAnswered: bool = false
var currentWord : WordResource

signal entered_word(word: String)
signal readyNextQuestion()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%EnglishBox.text_changed.connect(onEnglishTextChanged)
	%EnglishBox.text_submitted.connect(onEnglishTextSubmitted)
	%SendButton.disabled = true
	$Status.visible = false

func setup(show_instant_result : bool, max_question_number: int) -> void:
	showInstantResult = show_instant_result
	maxQuestionNumber = max_question_number
	

func showResult(wordSimilarity: float, similarityThreshold : float) -> void:
	%SendButton.text = "Suivant"
	%SendButton.disabled = false
	%EnglishBox.editable = false
	
	hasAnswered = true
	%SendButton.grab_focus()
	
	var englishStr : String = " / ".join(currentWord.ENGLISH)
	
	%EnglishBox.text = englishStr
	%Result.visible = true
	
	if wordSimilarity == 1:
		%Result.text = "[center][font_size=46][color=green]Correct !"
	elif wordSimilarity >= similarityThreshold:
		%Result.text = "[center][font_size=46][color=orange]Presque !"
	else:
		%Result.text = "[center][font_size=46][color=red]Faux !"
	
	mistakes += 0 if wordSimilarity >= similarityThreshold else 1
	%Status.text = "[center][font_size=24]%d/%d\nFautes : %d" % [currentQuestionNumber, maxQuestionNumber, mistakes]
	
func incrementQuestionNumber() -> void:
	currentQuestionNumber += 1

func changeWord(newWord: WordResource) -> void:
	currentWord = newWord
	
	%FrenchWord.text = "[font_size=64][center]%s" % currentWord.FRENCH
	%Context.text = "[color=dark_gray][font_size=32][center]%s" % currentWord.CONTEXT
	
	%SendButton.text = "Envoyer"
	%EnglishBox.editable = true
	%EnglishBox.text = ""
	%Result.visible = false
	%EnglishBox.grab_focus()
	hasAnswered = false
	
func sendButtonPressed():
	if hasAnswered:
		hasAnswered = false
		readyNextQuestion.emit()
		%SendButton.disabled = true
	else:
		if %EnglishBox.text.is_empty():
			return
		var playerWord : String = %EnglishBox.text.to_lower()
		%SendButton.disabled = true
		%SendButton.text = "Envoyé"
		%EnglishBox.editable = false
		entered_word.emit(playerWord)
		
		if showInstantResult:
			showResult(WordManager.checkEnteredWord(currentWord, playerWord), 0.8)
			%SendButton.disabled = false
			%SendButton.text = "Suivant"
			%EnglishBox.editable = true

func onEnglishTextSubmitted(newText: String) -> void:
	if not newText.is_empty():
		sendButtonPressed()

func onEnglishTextChanged(newText: String) -> void:
	%SendButton.disabled = newText.is_empty()
