extends Resource
class_name WordResource

@export var ID : int
@export var FRENCH : String
@export var ENGLISH : PackedStringArray

func _init(newId : int, newFr : String, newEn : PackedStringArray):
	ID = newId
	FRENCH = newFr
	ENGLISH = newEn
