extends Control

func _on_send_pressed() -> void:
	if $SendButton.disabled:
		return
	var email: String = $EmailField.text.strip_edges()
	if not email.contains("@"):
		$StatusLabel.text = "Please enter a valid email address."
		return
	set_busy(true)
	$StatusLabel.text = "Sending your reset link..."
	var result: Dictionary = await Supabase.reset_password(email)
	set_busy(false)
	$StatusLabel.text = ("If that email exists, a reset link has been sent."
		if result.ok else "Could not send the link. Please try again.")

func set_busy(busy: bool) -> void:
	$SendButton.disabled = busy
	$BackButton.disabled = busy
	$EmailField.editable = not busy
	$SendButton.text = "Sending..." if busy else "Send Reset Link"

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LoginScreen.tscn")
