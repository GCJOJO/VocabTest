extends ScrollContainer

signal wordsCountChanged(newValue : int)
signal wordsThresholdChanged(newValue : float)
signal timerChanged(newValue : int)
signal categoriesChanged(newValue : int)

var useTimer : bool = false

func _ready() -> void:
	setup()
	
func setup():
	var max_word_number : int = WordManager.WORDS.size()
	var max_verb_number : int = WordManager.VERBS.size()
	
	%WordsSpinBox.min_value = 1
	%WordsSpinBox.max_value = max_word_number + max_verb_number
	%WordsSpinBox.value = min(10, max_word_number + max_verb_number)

func setIsDisabled(disabled : bool) -> void:
	%WordsSpinBox.editable = not disabled
	%WordThresholdSlider.editable = not disabled
	%TimerSlider.editable = not disabled

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
