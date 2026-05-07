extends TextureRect

@export var angle_x_max: float = 15.0
@export var angle_y_max: float = 15.0
@export var max_offset_shadow: float = 50.0

@export_category("Oscillator")
@export var spring: float = 150.0
@export var damp: float = 10.0
@export var velocity_multiplier: float = 2.0

var displacement: float = 0.0 
var oscillator_velocity: float = 0.0

var tween_rot: Tween
var tween_hover: Tween
var tween_destroy: Tween
var tween_handle: Tween

var last_mouse_pos: Vector2
var mouse_velocity: Vector2
var following_mouse: bool = false
var last_pos: Vector2
var velocity: Vector2

var y_angle : float = 0.0

@onready var card_texture: TextureRect = self

func _ready() -> void:
	# Convert to radians because lerp_angle is using that
	angle_x_max = deg_to_rad(angle_x_max)
	angle_y_max = deg_to_rad(angle_y_max)
	%SoloMode.word_changed.connect(spin)
	%MultiplayerMode.word_changed.connect(spin)


func _process(_delta: float) -> void:
	card_texture.material.set_shader_parameter("rect_size", get_tree().root.size)
	$SubViewport.size = get_tree().root.size

func _input(event) -> void:
	if mouse_filter == MouseFilter.MOUSE_FILTER_IGNORE:
		return
	
	#if Input.is_key_pressed(KEY_G):
	#	spin()
	$SubViewport.push_input(event)

func _gui_input(event) -> void:
	if mouse_filter == MouseFilter.MOUSE_FILTER_IGNORE:
		return
	
	# Don't compute rotation when moving the card
	if following_mouse: return
	if not event is InputEventMouseMotion: 
		$SubViewport.push_input(event)
		return
	
	# Handles rotation
	# Get local mouse pos
	var mouse_pos: Vector2 = get_local_mouse_position()
	#print("Mouse: ", mouse_pos)
	#print("Card: ", position + size)

	var lerp_val_x: float = remap(mouse_pos.x, 0.0, size.x, 0, 1)
	var lerp_val_y: float = remap(mouse_pos.y, 0.0, size.y, 0, 1)
	#print("Lerp val x: ", lerp_val_x)
	#print("lerp val y: ", lerp_val_y)

	var rot_x: float = rad_to_deg(lerp_angle(-angle_x_max, angle_x_max, lerp_val_x))
	var rot_y: float = rad_to_deg(lerp_angle(angle_y_max, -angle_y_max, lerp_val_y))
	#print("Rot x: ", rot_x)
	#print("Rot y: ", rot_y)
	
	card_texture.material.set_shader_parameter("x_rot", rot_y)
	card_texture.material.set_shader_parameter("y_rot", rot_x)

func _on_mouse_entered() -> void:
	if tween_hover and tween_hover.is_running():
		tween_hover.kill()
	tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween_hover.tween_property(self, "scale", Vector2(1.2, 1.2), 0.5)

func _on_mouse_exited() -> void:
	# Reset rotation
	if tween_rot and tween_rot.is_running():
		tween_rot.kill()
	tween_rot = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_parallel(true)
	tween_rot.tween_property(card_texture.material, "shader_parameter/x_rot", 0.0, 0.5)
	tween_rot.tween_property(card_texture.material, "shader_parameter/y_rot", 0.0, 0.5)
	
	# Reset scale
	if tween_hover and tween_hover.is_running():
		tween_hover.kill()
	tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween_hover.tween_property(self, "scale", Vector2.ONE, 0.55)

func set_card_y_rot(rot_y : float):
		card_texture.material.set_shader_parameter("y_rot", rot_y)

func spin() -> void:
	following_mouse = true
	
	var position_tween : = create_tween()
	var rotation_tween : = create_tween()
	
	position_tween.set_ease(Tween.EASE_IN_OUT)
	position_tween.set_trans(Tween.TRANS_CUBIC)
	position_tween.tween_property(self, "position", Vector2(0, -50), 0.125)
	position_tween.tween_property(self, "position", Vector2(0, 0), 0.125)
	
	rotation_tween.set_ease(Tween.EASE_IN_OUT)
	rotation_tween.set_trans(Tween.TRANS_CUBIC)
	rotation_tween.tween_method(set_card_y_rot, 0, 90, 0.125)
	rotation_tween.tween_method(set_card_y_rot, -90, 0, 0.125)
	rotation_tween.tween_callback(func() : 
		following_mouse = false
		set_card_y_rot(0)
		)
	
