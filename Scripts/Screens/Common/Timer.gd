extends Control

var maxRoundTimer : int = -1
var roundTimer : int = 0

@export var blinkCurve : Curve = Curve.new()
@export var shakeCurve : Curve = Curve.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	blinkCurve.bake()
	shakeCurve.bake()

func setMaxRoundTimer(value : int) -> void:
	maxRoundTimer = value
	if maxRoundTimer == -1:
		hide()
	else:
		show()

func setRoundTimer(value : int) -> void:
	roundTimer = value
	var timerPercentage = 1 - (float(roundTimer) / float(maxRoundTimer))
	var blinkValue = lerp(0, 2, blinkCurve.sample_baked(timerPercentage))
	var shakeValue = lerp(0, 10, shakeCurve.sample_baked(timerPercentage))
	
	var shakeModifier : String = "[shake level=%s]" % shakeValue
	var blinkModifier : String = "[pulse freq=%s color=#ff000040 ease=-2.0]" % blinkValue if blinkValue > 0 else ""
	var text : String = "%s%s%s" % [shakeModifier, blinkModifier, roundTimer]
	$TimerText.text = text
	#if GameManager.DEBUG_MODE:
		#print(text)
