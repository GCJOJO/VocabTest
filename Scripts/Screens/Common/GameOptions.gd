extends ScrollContainer

@export var is_multiplayer_game : bool = false

signal wordsCountChanged(newValue : int)
signal wordsThresholdChanged(newValue : float)
signal timerChanged(newValue : int)
signal categoriesChanged(newValue : int)
signal gamemode_changed(new_game_mode : int)

var useTimer : bool = false

func _ready() -> void:
	$VBoxContainer/Mode.visible = is_multiplayer_game
	
func setup():
	var max_word_number : int = WordManager.WORDS.size()
	var max_verb_number : int = WordManager.VERBS.size()
	var max_country_number : int = WordManager.COUNTRIES.size()
	var max_grammar_number : int = WordManager.GRAMMAR.size()
	
	var max_question_number : int = max_word_number + max_verb_number + max_country_number + max_grammar_number
	
	%WordsSpinBox.min_value = 1
	%WordsSpinBox.max_value = max_question_number
	%WordsSpinBox.value = min(10, max_question_number)

func setIsDisabled(disabled : bool) -> void:
	%WordsSpinBox.editable = not disabled
	%WordThresholdSlider.editable = not disabled
	%TimerSlider.editable = not disabled
	%WordsCategory.disabled = disabled
	%VerbsCategory.disabled = disabled
	%CountryCategory.disabled = disabled
	%GrammarCategory.disabled = disabled
	%ModeOptionButton.disabled = disabled

func updateOptions(data) -> void:
	if data.has("max_words"):
		%WordsSpinBox.value = data["max_words"]
	if data.has("similarity_threshold"):
		%WordThresholdSlider.value = (data["similarity_threshold"] * 100)
		%WordThresholdText.text = "%.0f %%" % (data["similarity_threshold"] * 100)
	if data.has("round_timer"):
		var newTimer = data["round_timer"]
		%UseTimerCheckbob.button_pressed = newTimer >= 15
		if %UseTimerCheckbob.button_pressed:
			%TimerSlider.value = newTimer
			%TimerText.text = "%d secondes" % newTimer
	if data.has("categories"):
		var categories : int = data["categories"]
		
		var words_category : bool = categories & GameManager.WORD_CATEGORY
		var verbs_category : bool = categories & GameManager.VERB_CATEGORY
		var countries_category : bool = categories & GameManager.COUNTRY_CATEGORY
		var grammar_category : bool = categories & GameManager.GRAMMAR_CATEGORY
		
		%WordsCategory.button_pressed = words_category
		%VerbsCategory.button_pressed = verbs_category
		%CountryCategory.button_pressed = countries_category
		%GrammarCategory.button_pressed = grammar_category
		
	if data.has("lobby_mode"):
		%ModeOptionButton.select(data["lobby_mode"])

func onWordsCountChanged(value : float) -> void:
	wordsCountChanged.emit(floor(value))
	
func onWordsThresholdSliderChanged(valueChanged : bool) -> void:
	if valueChanged:
		var newValue : float = %WordThresholdSlider.value
		%WordThresholdText.text = "%.0f %%" % newValue
		wordsThresholdChanged.emit(newValue / 100)

func onUseTimerChanged() -> void:
	if %UseTimerCheckbob.button_pressed:
		timerChanged.emit(%TimerSlider.value)
		useTimer = true
	else:
		useTimer = false
		timerChanged.emit(-1)
		
func onTimerSliderChanged(valueChanged : bool) -> void:
	if valueChanged:
		var newValue : int = %TimerSlider.value
		%TimerText.text = "%d secondes" % newValue
		if useTimer:
			timerChanged.emit(newValue)

func onCategoriesChanged() -> void:
	var categories : int = 0
	if %WordsCategory.button_pressed:
		categories |= GameManager.WORD_CATEGORY
	if %VerbsCategory.button_pressed:
		categories |= GameManager.VERB_CATEGORY
	if %CountryCategory.button_pressed:
		categories |= GameManager.COUNTRY_CATEGORY
	if %GrammarCategory.button_pressed:
		categories |= GameManager.GRAMMAR_CATEGORY
		
	if categories == 0:
		categories |= GameManager.WORD_CATEGORY
		
	categoriesChanged.emit(categories)


func _on_mode_changed(index: int) -> void:
	if not is_multiplayer_game: return
	gamemode_changed.emit(index)
