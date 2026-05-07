extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"Version Label".text = "Version %s" % GameManager.VERSION_STRING 
