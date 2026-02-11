extends Control
class_name WordQuestionScreen

var showInstantResult : bool
var maxQuestionNumber: int
var currentQuestionNumber: int = 0
var mistakes: int = 0

var hasAnswered: bool = false
var currentWord : WordResource

var wordSimilarityThreshold : float = -1

signal entered_word(word: String)
signal wordChanged(word : WordResource)
signal readyNextQuestion()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%EnglishBox.text_changed.connect(onEnglishTextChanged)
	%EnglishBox.text_submitted.connect(onEnglishTextSubmitted)
	%SendButton.disabled = true
	$Status.visible = true
	%ExplosionSprite.animation_finished.connect(%ExplosionSprite.hide)
	

func setup(show_instant_result : bool, max_question_number: int, word_similarity_threshold : float = -1) -> void:
	showInstantResult = show_instant_result
	maxQuestionNumber = max_question_number
	wordSimilarityThreshold = word_similarity_threshold
	%Status.text = "[center][font_size=24]%d/%d\nFautes : %d" % [currentQuestionNumber, maxQuestionNumber, mistakes]

func showResult(wordSimilarity: float, similarityThreshold : float) -> void:
	%SendButton.text = "Suivant"
	%SendButton.disabled = false if not showInstantResult else %SendButton.disabled
	%EnglishBox.editable = false
	
	hasAnswered = true
	%SendButton.grab_focus()
	
	var englishStr : String = " / ".join(currentWord.ENGLISH)
	
	%EnglishBox.text = englishStr
	%Result.visible = true
	
	if wordSimilarity == 1:
		%Result.text = "[center][font_size=46][color=green]Correct !"
		#%GreenParticles.emitting = true
		#%RedParticles.emitting = true
		#%OrangeParticles.emitting = true
	elif wordSimilarity >= similarityThreshold:
		%Result.text = "[center][font_size=46][color=orange]Presque !"
	else:
		%Result.text = "[center][font_size=46][color=red]Faux !"
		%ExplosionSprite.show()
		%ExplosionSprite.play(&"default")
		$ExplosionSound.play()
	
	mistakes += 0 if wordSimilarity >= similarityThreshold else 1
	updateStatus()
	
func updateStatus() -> void:
	%Status.text = "[center][font_size=24]%d/%d\nFautes : %d" % [currentQuestionNumber, maxQuestionNumber, mistakes]
	
func incrementQuestionNumber() -> void:
	currentQuestionNumber += 1

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
	incrementQuestionNumber()
	updateStatus()
	
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
			showResult(WordManager.checkEnteredWord(currentWord, playerWord), wordSimilarityThreshold)
			%SendButton.disabled = false
			%SendButton.text = "Suivant"

func onEnglishTextSubmitted(newText: String) -> void:
	if not newText.is_empty():
		sendButtonPressed()

func onEnglishTextChanged(newText: String) -> void:
	%SendButton.disabled = newText.is_empty()
