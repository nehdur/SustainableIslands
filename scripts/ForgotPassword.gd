extends Control


@onready var email_field: LineEdit = $CenterContainer/AuthPanel/VBox/EmailField
@onready var send_button: Button = $CenterContainer/AuthPanel/VBox/SendButton
@onready var back_button: Button = $CenterContainer/AuthPanel/VBox/BackButton
@onready var status_label: Label = $CenterContainer/AuthPanel/VBox/StatusLabel


func _ready() -> void:

	send_button.pressed.connect(_on_send_pressed)
	back_button.pressed.connect(_on_back_pressed)

	status_label.text = ""


func _on_send_pressed() -> void:

	var email := email_field.text.strip_edges()


	if email.is_empty() or not email.contains("@"):

		status_label.text = "Please enter a valid email address."

		return


	send_button.disabled = true
	send_button.text = "Sending..."


	var result := await Supabase.reset_password(email)


	if result["ok"]:

		status_label.text = "If that email exists, a reset link has been sent!"

	else:

		status_label.text = "Could not send reset link. Please try again."


	send_button.disabled = false
	send_button.text = "✉ Send Reset Link"


func _on_back_pressed() -> void:

	get_tree().change_scene_to_file(
		"res://scenes/LoginScreen.tscn"
	)
