extends Resource
class_name VerbResource

@export var ID : int
@export var FRENCH : String
@export var CONTEXT : String
@export var INFINITIVE : PackedStringArray 
@export var PRETERIT : PackedStringArray
@export var PRESENT_PARTICIPLE : PackedStringArray

func _init(newId : int, newFr : String, newContext : String, newInfinitive : PackedStringArray, newPreterit : PackedStringArray, newPresentParticiple : PackedStringArray):
	ID = newId
	FRENCH = newFr
	CONTEXT = newContext
	INFINITIVE = newInfinitive
	PRETERIT = newPreterit
	PRESENT_PARTICIPLE = newPresentParticiple
