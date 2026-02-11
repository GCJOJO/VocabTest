extends Control

const ERROR_THRESHOLD : float = 0.8
var RANDOMIZED_WORDS : Array[WordResource]
var CURRENT_WORD_INDEX : int = -1
var has_answered : bool = false
var mistakes : int = 0

var LobbyOptions = {
	"max_words" : 10,
	"categories": 16,
	"round_timer": 15, 
	"similarity_threshold": 0.8
}

var roundTimer : int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$GameMenu.hide()
	%WordQuestion.readyNextQuestion.connect(update_word)
	%GameOptions.wordsCountChanged.connect(func(value : int): LobbyOptions["max_words"] = value)
	%GameOptions.timerChanged.connect(func(value : int): LobbyOptions["round_timer"] = value)
	%GameOptions.wordsThresholdChanged.connect(func(value : float): LobbyOptions["similarity_threshold"] = value)
	#update_word()
	$GameMenu/Timer.timeout.connect(onTimerTick)
	%WordQuestion.entered_word.connect(func(_word): $GameMenu/Timer.paused = true)
	%WordQuestion.wordChanged.connect(func(_word): 
		$GameMenu/Timer.paused = false
		roundTimer = LobbyOptions["round_timer"])
	
func onTimerTick() -> void:
	if roundTimer > 0:
		roundTimer -= 1
		if roundTimer == 0:
			%WordQuestion.showResult(0, LobbyOptions["similarity_threshold"])
		$GameMenu/TimerScreen.setRoundTimer(roundTimer)
	
func loadSoloMode() -> void:
	$GameMenu.hide()
	$OptionScreen.show()
	if WordManager.WORDS == null or len(WordManager.WORDS) == 0:
		print("No words")
		#get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
		return
	
	RANDOMIZED_WORDS = WordManager.WORDS
	RANDOMIZED_WORDS.shuffle()
	%GameOptions.setup()
	
func startGame() -> void:
	$OptionScreen.hide()
	$GameMenu.show()
	%WordQuestion.setup(true, LobbyOptions["max_words"], LobbyOptions["similarity_threshold"])
	roundTimer = LobbyOptions["round_timer"]
	$GameMenu/TimerScreen.setRoundTimer(roundTimer)
	$GameMenu/TimerScreen.setMaxRoundTimer(LobbyOptions["round_timer"])
	update_word()
	$GameMenu/Timer.start()

func update_word() -> void:
	CURRENT_WORD_INDEX += 1
	if(CURRENT_WORD_INDEX >= min(len(RANDOMIZED_WORDS), LobbyOptions["max_words"])):
		#get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
		# show results
		$OptionScreen.show()
		$GameMenu.hide()
		return
	
	%WordQuestion.changeWord(RANDOMIZED_WORDS[CURRENT_WORD_INDEX])
