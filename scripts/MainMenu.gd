extends Control
var status: Label
var start_button: Button
var continue_button: Button
var reset_dialog: ConfirmationDialog

func _ready() -> void:
 var bg := ColorRect.new()
 bg.color = Color("68bcc0")
 bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(bg)
 IslandUI.texture(self,"res://assets/island/island_map.svg",Rect2(650,-50,1550,1120))
 var p := IslandUI.panel(self,Rect2(90,115,730,850))
 IslandUI.texture(p,"res://assets/island/leaf.svg",Rect2(46,44,90,90))
 IslandUI.label(p,"SUSTAINABLEISLAND TOURISM COUNCIL",Rect2(46,159,650,30),20,IslandUI.MUTED)
 IslandUI.label(p,"Small island.\nBig responsibility.",Rect2(46,210,640,160),58)
 IslandUI.paragraph(p,"Welcome tourists. Support local livelihoods.\nKeep the island's forests and reefs alive.",Rect2(46,398,632,95),27)
 continue_button = IslandUI.button(p,"Continue island",Rect2(46,525,638,63),play,true)
 start_button = IslandUI.button(p,"Start a new island",Rect2(46,605,638,58),confirm_new)
 var back_button := IslandUI.button(p,"Back to login",Rect2(46,682,310,54),logout)
 var quit_button := IslandUI.button(p,"Quit",Rect2(372,682,312,54),func(): get_tree().quit())
 status = IslandUI.paragraph(p,"Loading your island…",Rect2(46,757,640,63),19)
 reset_dialog = ConfirmationDialog.new()
 reset_dialog.title = "Start a new island?"
 reset_dialog.dialog_text = "This replaces your current local island progress.\nCloud progress changes only when you choose Save / cloud sync."
 reset_dialog.ok_button_text = "Start new island"
 reset_dialog.confirmed.connect(func():
  IslandGame.reset()
  IslandGame.save_local()
  play()
 )
 add_child(reset_dialog)
 var expected := Supabase.user_id if Supabase.is_logged_in() else "guest"
 if IslandGame.profile != expected:
  IslandGame.select_profile(expected)
 continue_button.disabled = true
 start_button.disabled = true
 back_button.disabled = true
 quit_button.disabled = true
 status.text = await IslandGame.cloud_load()
 if not IslandGame.storage_notice.is_empty() and IslandGame.storage_notice != "Saved on this device":
  status.text += "\n" + IslandGame.storage_notice
 continue_button.disabled = false
 start_button.disabled = false
 back_button.disabled = false
 quit_button.disabled = false
 continue_button.text = "View season results" if IslandGame.data.finished else "Continue island • Day %d" % IslandGame.data.day

func play() -> void:
 get_tree().change_scene_to_file("res://scenes/Game.tscn")

func confirm_new() -> void:
 reset_dialog.popup_centered(Vector2i(660,210))

func logout() -> void:
 Supabase.sign_out()
 IslandGame.select_profile("guest")
 get_tree().change_scene_to_file("res://scenes/LoginScreen.tscn")
