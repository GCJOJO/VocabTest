extends Node

@export var error_screen : PackedScene = preload("uid://c0wgwvdh8vkcr")
var error_screen_instance : ErrorScreen

@onready var canvas_layer : CanvasLayer = CanvasLayer.new()

func _ready() -> void:
	canvas_layer.layer = 100
	add_child(canvas_layer)
	
	var node_instance = error_screen.instantiate()
	if node_instance == null:
		return
	if node_instance is not ErrorScreen:
		node_instance.queue_free()
		return
		
	error_screen_instance = node_instance as ErrorScreen
	if error_screen_instance == null:
		node_instance.queue_free()
		return
		
	canvas_layer.add_child(error_screen_instance)
	error_screen_instance.hide()

func show_error(title : String, content : String) -> void:
	push_error("Error ! %s\n%s" % [title, content])
	
	error_screen_instance.set_title(title)
	error_screen_instance.set_content(content)
	
	error_screen_instance.show_screen()
