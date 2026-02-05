extends Resource
class_name UserResource

@export var USER_ID : String
@export var USERNAME : String
@export var FIRST_NAME : String
@export var LAST_NAME : String

func _init(userId : String, username : String, userFirstName : String, userLastName) -> void:
	USER_ID = userId
	USERNAME = username
	FIRST_NAME = userFirstName
	LAST_NAME = userLastName
