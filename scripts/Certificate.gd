extends Control
## On-screen reward. The player's name stays in this scene's memory.

var recipient_name: String = ""
var previous_focus: Control

@onready var name_field: LineEdit = $NamePrompt/PromptPanel/NameField
@onready var name_label: Label = $CertificatePage/Paper/RecipientName

func unlocked() -> bool:
	return bool(IslandGame.data.finished) and IslandGame.won()

func open() -> bool:
	if not unlocked():
		hide()
		return false
	previous_focus = get_viewport().gui_get_focus_owner()
	show()
	if recipient_name.is_empty():
		edit_name()
	else:
		name_field.text = recipient_name
		show_certificate()
	return true

func edit_name() -> void:
	$CertificatePage.hide()
	$NamePrompt.show()
	$NamePrompt/PromptPanel/ErrorLabel.text = ""
	name_field.text = recipient_name
	name_field.grab_focus()
	name_field.select_all()

func show_certificate() -> void:
	if not unlocked():
		close()
		return
	var full_name := name_field.text.strip_edges()
	if full_name.is_empty():
		$NamePrompt/PromptPanel/ErrorLabel.text = "Please enter your full name."
		name_field.grab_focus()
		return
	recipient_name = full_name
	name_label.text = full_name
	# Reduce the name's font size only when a long name needs more room.
	var font: Font = name_label.get_theme_font("font")
	var font_size: int = 54
	while font_size > 12 and font.get_string_size(full_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > name_label.size.x:
		font_size -= 1
	name_label.add_theme_font_size_override("font_size", font_size)
	$CertificatePage/Paper/ResultsLabel.text = "Rating %d/100  •  Local jobs %d  •  Funds %d coins" % [
		IslandGame.rating(), IslandGame.jobs(), int(IslandGame.data.money)
	]
	$CertificatePage/Paper/HabitatsLabel.text = "Marine health %d/100  •  Mangrove health %d/100" % [
		int(IslandGame.data.marine), int(IslandGame.data.forest)
	]
	$NamePrompt.hide()
	$CertificatePage.show()
	$CertificatePage/CloseButton.grab_focus()

func close() -> void:
	hide()
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree():
		previous_focus.grab_focus()

func _on_name_submitted(_text: String) -> void:
	show_certificate()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
