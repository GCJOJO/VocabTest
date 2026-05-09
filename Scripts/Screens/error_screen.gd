extends Control
class_name ErrorScreen

func show_screen() -> void:
	get_tree().call_group("3d_card_effect", "set_ignore_mouse", true)
	show()
	
func hide_screen() -> void:
	hide()
	get_tree().call_group("3d_card_effect", "set_ignore_mouse", false)

func set_title(new_title : String) -> void:
	%Title.text = "[b]%s[/b]" % new_title
	
func set_content(new_content : String) -> void:
	%Content.text = new_content


func _on_content_meta_clicked(meta: Variant) -> void:
	if meta is String:
		meta = meta.replace("{", "")
		meta = meta.replace("}", "")
		print(str(meta))
		OS.shell_open(str(meta))
