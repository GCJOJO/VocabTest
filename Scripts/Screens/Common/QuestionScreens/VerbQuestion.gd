extends Control
class_name VerbQuestionScreen

var hasAnswered: bool = false
var currentVerb : VerbResource

signal enteredVerb(verbs: PackedStringArray)
signal verbChanged(verb : VerbResource)
signal readyNextQuestion()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%Infinitive.text_changed.connect(onEnglishTextChanged)
	%Preterit.text_changed.connect(onEnglishTextChanged)
	%PP.text_changed.connect(onEnglishTextChanged)
	
	%Infinitive.text_submitted.connect(func(_str): %Preterit.grab_focus())
	%Preterit.text_submitted.connect(func(_str): %PP.grab_focus())
	%PP.text_submitted.connect(func(pp : String): onVerbSubmitted([%Infinitive.text, %Preterit.text, pp]))
	%SendButton.disabled = true
	%Result.visible = false
	%ExplosionSprite.animation_finished.connect(%ExplosionSprite.hide)
	

func showResult(verbSimilarity: float, similarityThreshold : float, _showingInstantResult : bool) -> float:	
	%SendButton.text = "Suivant"
	%SendButton.disabled = false
	
	%Infinitive.editable = false
	%Preterit.editable = false
	%PP.editable = false
	
	hasAnswered = true
	%SendButton.grab_focus()
	
	var infStr : String = " / ".join(currentVerb.INFINITIVE)
	var preStr : String = " / ".join(currentVerb.PRETERIT)
	var ppStr : String = " / ".join(currentVerb.PRESENT_PARTICIPLE)
	
	%Infinitive.text = infStr
	%Preterit.text = preStr
	%PP.text = ppStr
	%Result.visible = true
	
	var mistakes : float = -1.0
	
	if verbSimilarity == 1:
		%Result.text = "[center][font_size=46][color=green]Correct !"
		mistakes = 0.0
		#%GreenParticles.emitting = true
		#%RedParticles.emitting = true
		#%OrangeParticles.emitting = true
	elif verbSimilarity >= similarityThreshold:
		%Result.text = "[center][font_size=46][color=orange]Presque !"
		mistakes = 1 - verbSimilarity
	else:
		%Result.text = "[center][font_size=46][color=red]Faux !"
		mistakes = 1.0
	
	return mistakes

func changeVerb(newVerb: VerbResource) -> void:
	currentVerb = newVerb
	
	%FrenchWord.text = newVerb.FRENCH
	%Context.text = "[color=dark_gray]%s[/color]" % newVerb.CONTEXT
	
	%SendButton.text = "Envoyer"
	
	%Infinitive.editable = true
	%Preterit.editable = true
	%PP.editable = true
	
	%Infinitive.text = ""
	%Preterit.text = ""
	%PP.text = ""
	
	%Result.visible = false
	%Infinitive.grab_focus()
	hasAnswered = false
	verbChanged.emit(currentVerb)
	
func sendButtonPressed():
	if hasAnswered:
		hasAnswered = false
		readyNextQuestion.emit()
		%SendButton.disabled = true
	else:
		if %Infinitive.text.is_empty() or %Preterit.text.is_empty() or %PP.text.is_empty():
			return
		var playerVerbs : PackedStringArray = [%Infinitive.text.to_lower(), %Preterit.text.to_lower(), %PP.text.to_lower() ]
		%SendButton.disabled = true
		%SendButton.text = "Envoyé"
		
		%Infinitive.editable = false
		%Preterit.editable = false
		%PP.editable = false
		
		enteredVerb.emit(playerVerbs)


func onVerbSubmitted(verbs: PackedStringArray) -> void:
	for verb in verbs:
		if verb.is_empty():
			return
	
	sendButtonPressed()

func onEnglishTextChanged(_newText: String) -> void:
	%SendButton.disabled = %Infinitive.text.is_empty() or %Preterit.text.is_empty() or %PP.text.is_empty()
