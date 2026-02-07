extends Control

const ERROR_THRESHOLD : float = 0.8
var RANDOMIZED_WORDS : Array[WordResource]
var CURRENT_WORD_INDEX : int = -1
var has_answered : bool = false
var mistakes : int = 0

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
	%Status.text = "[font_size=24]%d/%d\nFautes : %d" % [CURRENT_WORD_INDEX + 1, len(RANDOMIZED_WORDS), mistakes]
	%Context.text = "[color=dark_gray][font_size=32][center]%s" % RANDOMIZED_WORDS[CURRENT_WORD_INDEX].CONTEXT
	%EnglishBox.grab_focus()

func textUpdated(new_text : String) -> void:
	%SendButton.disabled = new_text.is_empty() and not has_answered

func sendAnswer() -> void:
	if has_answered:
		has_answered = false
		%SendButton.text = "Envoyer"
		%EnglishBox.editable = true
		%EnglishBox.text = ""
		%Result.visible = false
		update_word()
	else:
		var enteredWord : String = %EnglishBox.text
		if enteredWord.is_empty():
			return
		
		has_answered = true
		var similarity = WordManager.checkEnteredWord(RANDOMIZED_WORDS[CURRENT_WORD_INDEX], enteredWord)
		var sucess =  similarity >= ERROR_THRESHOLD
		%SendButton.text = "Suivant"
		%EnglishBox.editable = false
		
		var englishStr : String = " / ".join(RANDOMIZED_WORDS[CURRENT_WORD_INDEX].ENGLISH)
		
		%EnglishBox.text = englishStr
		%Result.visible = true
		
		if sucess and similarity == 1:
			%Result.text = "[center][font_size=46][color=green]Correct !"
		elif sucess and similarity != 1:
			%Result.text = "[center][font_size=46][color=orange]Presque !"
		else:
			%Result.text = "[center][font_size=46][color=red]Faux !"
		
		mistakes += 0 if sucess else 1
		%Status.text = "[font_size=24]%d/%d\nFautes : %d" % [CURRENT_WORD_INDEX + 1, len(RANDOMIZED_WORDS), mistakes]
		%SendButton.grab_focus()

func _on_english_box_text_submitted(_new_text: String) -> void:
	sendAnswer()
