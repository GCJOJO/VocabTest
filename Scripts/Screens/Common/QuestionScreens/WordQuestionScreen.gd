extends Control
class_name WordQuestionScreen

var hasAnswered: bool = false
var currentWord : WordResource

signal enteredWord(word: String)
signal wordChanged(word : WordResource)
signal readyNextQuestion()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%EnglishBox.text_changed.connect(onEnglishTextChanged)
	%EnglishBox.text_submitted.connect(onEnglishTextSubmitted)
	%SendButton.disabled = true
	
func showResult(wordSimilarity: float, similarityThreshold : float, _showingInstantResult : bool) -> float:
	%SendButton.text = "Suivant"
	%SendButton.disabled = false
	%EnglishBox.editable = false
	
	hasAnswered = true
	%SendButton.grab_focus()
	
	var englishStr : String = " / ".join(currentWord.ENGLISH)
	
	%EnglishBox.text = englishStr
	%Result.visible = true
	
	var mistakes : float = -1.0
	
	if wordSimilarity == 1:
		%Result.text = "[center][font_size=46][color=green]Correct !"
		mistakes = 0.0
		#%GreenParticles.emitting = true
		#%RedParticles.emitting = true
		#%OrangeParticles.emitting = true
	elif wordSimilarity >= similarityThreshold:
		%Result.text = "[center][font_size=46][color=orange]Presque !"
		mistakes = 1 - wordSimilarity
	else:
		%Result.text = "[center][font_size=46][color=red]Faux !"
		mistakes = 1.0
	
	#updateStatus()
	return mistakes
		


func changeWord(newWord: WordResource) -> void:
	currentWord = newWord
	
	%FrenchWord.text = "[font_size=46][center]%s" % currentWord.FRENCH
	%Context.text = "[color=dark_gray][font_size=32][center]%s" % currentWord.CONTEXT
	%Prefix.text = "[color=#555][font_size=28]%s" % currentWord.PREFIX
	
	%SendButton.text = "Envoyer"
	%EnglishBox.editable = true
	%EnglishBox.text = ""
	%Result.visible = false
	%EnglishBox.grab_focus()
	hasAnswered = false
	wordChanged.emit(currentWord)
	
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
		enteredWord.emit(playerWord)
		
		
func onEnglishTextSubmitted(newText: String) -> void:
	if not newText.is_empty():
		sendButtonPressed()

func onEnglishTextChanged(newText: String) -> void:
	%SendButton.disabled = newText.is_empty()
