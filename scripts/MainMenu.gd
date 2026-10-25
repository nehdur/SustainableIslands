extends Control

@onready var status_label: Label = $StatusLabel
@onready var continue_button: Button = $ContinueButton
@onready var start_button: Button = $StartButton
@onready var back_button: Button = $BackButton
@onready var quit_button: Button = $QuitButton
@onready var reset_dialog: ConfirmationDialog = $ResetDialog


func _ready() -> void:
	var profile := Supabase.user_id if Supabase.is_logged_in() else "guest"

	if IslandGame.profile != profile:
		IslandGame.select_profile(profile)

	set_busy(true)
	status_label.text = await IslandGame.cloud_load()

	var notice: String = IslandGame.storage_notice
	if not notice.is_empty() and notice != "Saved on this device":
		status_label.text += "\n" + notice

	if IslandGame.data.finished:
		continue_button.text = "View Season Results"
	else:
		continue_button.text = "Continue Island • Day %d" % IslandGame.data.day

	set_busy(false)


func set_busy(busy: bool) -> void:
	continue_button.disabled = busy
	start_button.disabled = busy
	back_button.disabled = busy
	quit_button.disabled = busy


func play() -> void:
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func confirm_new() -> void:
	reset_dialog.popup_centered(Vector2i(660, 210))


func _on_start_confirmed() -> void:
	IslandGame.reset()
	IslandGame.save_local()
	play()


func logout() -> void:
	Supabase.sign_out()
	IslandGame.select_profile("guest")
	get_tree().change_scene_to_file("res://scenes/LoginScreen.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
