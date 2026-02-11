extends Resource
class_name WordResource

@export var ID : int
@export var FRENCH : String
@export var CONTEXT : String
@export var PREFIX : String = ""
@export var ENGLISH : PackedStringArray

func _init(newId : int, newFr : String, newContext : String, newEn : PackedStringArray, newPrefix : String = ""):
	ID = newId
	FRENCH = newFr
	CONTEXT = newContext
	PREFIX = newPrefix
	ENGLISH = newEn
