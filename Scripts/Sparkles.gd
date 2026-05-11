extends ColorRect

const BASE_REPEAT_X : float = 20.0
const BASE_REPEAT_Y : float = 12.0
const BASE_WIDTH : float = 1280.0
const BASE_HEIGHT : float = 720.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().root.size_changed.connect(on_viewport_size_changed)
	
	on_viewport_size_changed()

func on_viewport_size_changed() -> void:
	var new_size : Vector2 = get_tree().root.size
	
	if new_size.x == 0 or new_size.y == 0:
		return
	
	material.set_shader_parameter("repeat_x", (new_size.x / BASE_WIDTH) * BASE_REPEAT_X)
	material.set_shader_parameter("repeat_y", (new_size.y / BASE_HEIGHT) * BASE_REPEAT_Y)
