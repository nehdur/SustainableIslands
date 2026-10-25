extends Control

@onready var email_field: LineEdit = $EmailField
@onready var send_button: Button = $SendButton
@onready var back_button: Button = $BackButton
@onready var status_label: Label = $StatusLabel


func _on_send_pressed() -> void:
	var email := email_field.text.strip_edges()

	if not email.contains("@"):
		status_label.text = "Please enter a valid email address."
		return

	set_busy(true)
	status_label.text = "Sending your reset link..."

	var result: Dictionary = await Supabase.reset_password(email)

	set_busy(false)

	if result.get("ok", false):
		status_label.text = "If that email exists, a reset link has been sent."
	else:
		status_label.text = "Could not send the link. Please try again."


func set_busy(busy: bool) -> void:
	send_button.disabled = busy
	back_button.disabled = busy
	email_field.editable = not busy
	send_button.text = "Sending..." if busy else "Send Reset Link"


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LoginScreen.tscn")
