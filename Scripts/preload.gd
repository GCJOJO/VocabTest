extends Node

func _ready() -> void:
	var args = OS.get_cmdline_args()
	if args.has("--server"):
		print("Starting Server...")
		ConnectionManager.startServer()
		Callable(func(): get_tree().change_scene_to_file("res://Scenes/mutliplayer_lobby.tscn")).call_deferred()
		return
	
	Callable(func(): get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")).call_deferred()
	
	
