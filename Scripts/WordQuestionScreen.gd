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
	$Status.visible = false

func setup(show_instant_result : bool, max_question_number: int) -> void:
	showInstantResult = show_instant_result
	maxQuestionNumber = max_question_number
	
func showResult(valid: bool) -> void:
	%SendButton.text = "Suivant"
	%SendButton.disabled = false
	%EnglishBox.editable = false
	
	var englishStr : String = " / ".join(currentWord.ENGLISH)
	
	%EnglishBox.text = englishStr
	%Result.visible = true
	%Result.text = "[center][font_size=46][color=green]Correct !" if valid else "[center][font_size=46][color=red]Faux !"
	mistakes += 0 if valid else 1
	%Status.text = "[center][font_size=24]%d/%d\nFautes : %d" % [currentQuestionNumber, maxQuestionNumber, mistakes]
	
func incrementQuestionNumber() -> void:
	currentQuestionNumber += 1

func changeWord(newWord: WordResource) -> void:
	currentWord = newWord
	
	%FrenchWord.text = "[font_size=64][center]%s" % currentWord.FRENCH
	%Context.text = "[color=dark_gray][font_size=32][center]%s" % currentWord.CONTEXT
	
	%SendButton.text = "Envoyer"
	%SendButton.disabled = false
	%EnglishBox.editable = true
	%EnglishBox.text = ""
	%Result.visible = false
	
func sendButtonPressed():
	if hasAnswered:
		hasAnswered = false
		readyNextQuestion.emit()
		%SendButton.disabled = true
	else:
		if %EnglishBox.text.is_empty():
			return
		hasAnswered = true
		var playerWord : String = %EnglishBox.text.to_lower()
		%SendButton.disabled = true
		%SendButton.text = "Envoyé"
		%EnglishBox.editable = false
		entered_word.emit(playerWord)
		
		if showInstantResult:
			showResult(WordManager.checkEnteredWord(currentWord, playerWord))
			%SendButton.disabled = false
			%SendButton.text = "Suivant"
			%EnglishBox.editable = true
