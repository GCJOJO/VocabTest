extends Control

var RANDOMIZED_WORDS : Array[WordResource]
var CURRENT_WORD_INDEX : int = -1
var has_answered : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if WordManager.WORDS == null or len(WordManager.WORDS) == 0:
		print("No words")
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
		return
	
	RANDOMIZED_WORDS = WordManager.WORDS
	RANDOMIZED_WORDS.shuffle()
	update_word()

func update_word() -> void:
	CURRENT_WORD_INDEX += 1
	if(CURRENT_WORD_INDEX >= len(RANDOMIZED_WORDS)):
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
		return
	%SendButton.disabled = true
	%FrenchWord.text = "[font_size=64][center]%s" % RANDOMIZED_WORDS[CURRENT_WORD_INDEX].FRENCH

func textUpdated(new_text : String) -> void:
	%SendButton.disabled = new_text.is_empty() and not has_answered

func sendAnswer() -> void:
	if has_answered:
		has_answered = false
		%SendButton.text = "Envoyer"
		%EnglishBox.editable = true
		%EnglishBox.text = ""
		update_word()
	else:
		if %EnglishBox.text.is_empty():
			return
		
		has_answered = true
		print(WordManager.checkEnteredWord(RANDOMIZED_WORDS[CURRENT_WORD_INDEX], %EnglishBox.text))
		%SendButton.text = "Suivant"
		%EnglishBox.editable = false
		
		var englishStr : String = " / ".join(RANDOMIZED_WORDS[CURRENT_WORD_INDEX].ENGLISH)
			
		%EnglishBox.text = englishStr
	

func _on_english_box_text_submitted(_new_text: String) -> void:
	sendAnswer()
