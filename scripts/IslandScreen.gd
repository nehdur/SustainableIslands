extends Control
var metrics: Dictionary = {}
var bars: Dictionary = {}
var detail: Control
var selected := "guesthouse"
var toast: Label
var forecast_label: Label
var day_button: Button
var sound_button: Button
var modal: Control
var audio: AudioStreamPlayer
var cloud_button: Button
var is_syncing := false

func _ready() -> void:
 var bg := ColorRect.new()
 bg.color = Color("e8eddf")
 bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(bg)
 IslandUI.texture(self,"res://assets/island/leaf.svg",Rect2(38,22,66,66))
 IslandUI.label(self,"SustainableIsland",Rect2(122,21,600,46),36)
 IslandUI.label(self,"A LITTLE ISLAND. A LASTING DIFFERENCE.",Rect2(124,70,670,27),18,IslandUI.MUTED)
 IslandUI.button(self,"How to play",Rect2(1120,30,190,54),show_help)
 sound_button = IslandUI.button(self,"Sound",Rect2(1324,30,155,54),toggle_sound)
 IslandUI.button(self,"Journal",Rect2(1493,30,155,54),show_journal)
 IslandUI.button(self,"Menu",Rect2(1662,30,210,54),go_menu)
 var titles := ["ISLAND COINS","DAY / 14","ACTIONS LEFT","LOCAL JOBS / 12","TOURISM RATING","SATISFACTION"]
 var keys := ["money","day","ap","jobs","rating","satisfaction"]
 for i in range(keys.size()):
  var p := IslandUI.panel(self,Rect2(40+i*308,119,296,104))
  IslandUI.label(p,titles[i],Rect2(20,12,268,26),18,IslandUI.MUTED)
  metrics[keys[i]] = IslandUI.label(p,"",Rect2(20,42,262,54),36)
 var map_frame := IslandUI.panel(self,Rect2(40,243,1200,800),Color("69bec0"))
 map_frame.clip_contents = true
 var map := Control.new()
 map.set_script(load("res://scripts/IslandMap.gd"))
 map.size = Vector2(1200,800)
 map_frame.add_child(map)
 map.selected.connect(select_zone)
 var banner := IslandUI.panel(map_frame,Rect2(22,19,710,74),Color("f7f3e7"))
 IslandUI.label(banner,"YOUR ISLAND  /  Select a location to manage",Rect2(18,11,670,28),23)
 IslandUI.label(banner,"Faded buildings are available construction sites.",Rect2(18,41,670,23),18,IslandUI.MUTED)
 var news := IslandUI.panel(map_frame,Rect2(22,701,1156,76),Color("233f43"))
 forecast_label = IslandUI.label(news,"",Rect2(20,9,1116,27),22,Color("f8edc9"))
 toast = IslandUI.label(news,"",Rect2(20,41,1116,26),18,Color("c6dacf"))
 toast.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
 var env := IslandUI.panel(self,Rect2(1264,243,608,237))
 IslandUI.label(env,"ISLAND HEALTH",Rect2(22,14,330,30),21)
 for i in range(5):
  var key: String = ["marine","forest","water","energy","waste"][i]
  var x := 22 + (i % 2) * 290
  var y := 55 + int(i / 2.0) * 56
  var l := IslandUI.label(env,key.capitalize(),Rect2(x,y,265,22),18)
  var bar := ProgressBar.new()
  bar.position = Vector2(x,y+27)
  bar.size = Vector2(265,10)
  bar.show_percentage = false
  bar.max_value = 200 if key == "waste" else 100
  bar.add_theme_stylebox_override("background",IslandUI.style(Color("dde4d6"),5,0))
  bar.add_theme_stylebox_override("fill",IslandUI.style(Color("bb8c56") if key == "waste" else Color("5c9682"),5,0))
  env.add_child(bar)
  bars[key] = {"label":l,"bar":bar}
 bars["impact"] = IslandUI.label(env,"",Rect2(312,167,275,52),18)
 detail = IslandUI.panel(self,Rect2(1264,496,608,408))
 cloud_button = IslandUI.button(self,"Save / cloud sync",Rect2(1264,922,290,54),sync_cloud)
 IslandUI.button(self,"Season goals",Rect2(1570,922,302,54),show_goals)
 day_button = IslandUI.button(self,"Next Day  →",Rect2(1264,992,608,52),next_day,true)
 audio = AudioStreamPlayer.new()
 add_child(audio)
 IslandGame.changed.connect(refresh)
 refresh()
 ensure_toolbox()
 if IslandGame.data.explored.is_empty():
  show_help()
 elif IslandGame.data.finished:
  show_ending()

func refresh() -> void:
 for key in ["money","day","ap"]:
  metrics[key].text = str(int(IslandGame.data[key]))
 metrics.jobs.text = str(IslandGame.jobs())
 metrics.rating.text = "%d / 100" % IslandGame.rating()
 metrics.satisfaction.text = "%d%%" % int(IslandGame.data.satisfaction)
 for key in ["marine","forest","water","energy","waste"]:
  bars[key].label.text = "%s   %d%s" % [key.capitalize(),int(IslandGame.data[key])," (lower is better)" if key == "waste" else " / 100"]
  bars[key].bar.value = IslandGame.data[key]
 bars.impact.text = "Impact: %d / 100\nLower is better" % IslandGame.impact()
 forecast_label.text = IslandGame.forecast()
 sound_button.text = "Sound: off" if IslandGame.muted else "Sound: on"
 day_button.text = "View season results" if IslandGame.data.finished else ("Finish season  →" if int(IslandGame.data.day) == 14 else "Next Day  →")
 refresh_detail()

func select_zone(key: String) -> void:
 selected = key
 IslandGame.visit(key)
 play_sound("click")
 refresh_detail()

func clear_children(node: Node) -> void:
 for child in node.get_children():
  node.remove_child(child)
  child.queue_free()

func refresh_detail() -> void:
 clear_children(detail)
 IslandUI.texture(detail,"res://assets/island/%s.svg" % selected,Rect2(18,14,90,90))
 if IslandGame.FACILITIES.has(selected):
  var item: Dictionary = IslandGame.FACILITIES[selected]
  IslandUI.label(detail,item.title,Rect2(117,23,470,38),29)
  IslandUI.label(detail,item.sdg,Rect2(117,67,470,28),18,IslandUI.MUTED)
  IslandUI.paragraph(detail,item.description,Rect2(24,114,555,91),22)
  var level := int(IslandGame.data.buildings[selected])
  var staff := int(IslandGame.data.staff[selected])
  IslandUI.label(detail,"Level %d / %d    •    Workers %d / %d    •    1 action per change" % [level,item.max,staff,item.staff],Rect2(24,210,562,25),18)
  var price := IslandGame.cost(selected)
  var build_btn := IslandUI.button(detail,("Build" if level == 0 else "Upgrade") + " • %d coins" % price,Rect2(24,249,555,52),do_build,true)
  build_btn.disabled = level >= int(item.max) or IslandGame.blocked(price) != ""
  build_btn.tooltip_text = "Maximum level reached." if level >= int(item.max) else IslandGame.blocked(price)
  var hire_btn := IslandUI.button(detail,"Assign team",Rect2(24,316,266,52),do_hire)
  hire_btn.disabled = level == 0 or staff >= int(item.staff) or IslandGame.blocked(0) != "" or IslandGame.jobs() + int(item.staff) - staff > IslandGame.WORKERS
  var release_btn := IslandUI.button(detail,"Release team",Rect2(306,316,273,52),do_release)
  release_btn.disabled = staff == 0 or IslandGame.blocked(0) != ""
 else:
  var forest := selected == "forest"
  IslandUI.label(detail,"Mangrove Forest" if forest else "Coral Sanctuary",Rect2(117,23,470,38),29)
  IslandUI.label(detail,"SDG 15 • Life on land" if forest else "SDG 14 • Life below water",Rect2(117,67,470,28),20,IslandUI.MUTED)
  IslandUI.paragraph(detail,"Native forests support wildlife and protect island habitats. Hotel construction and accumulated waste reduce forest health." if forest else "Healthy coastal habitats support marine life. Uncollected tourism waste damages the reef each day. Prevention is cheaper than repeated repairs.",Rect2(24,115,555,117),23)
  var btn := IslandUI.button(detail,"Plant native trees • 130 coins" if forest else "Protect the reef • 130 coins",Rect2(24,249,555,52),func(): do_action("forest" if forest else "reef"),true)
  btn.disabled = IslandGame.blocked(130) != ""
  IslandUI.label(detail,"Restores up to 12 health points • uses 1 action",Rect2(24,320,555,35),21,IslandUI.MUTED)

func play_sound(name: String) -> void:
 if not IslandGame.muted:
  audio.stop()
  audio.stream = load("res://assets/audio/%s.wav" % name)
  audio.play()

func show_message(message: String) -> void:
 toast.text = message
 toast.tooltip_text = message
 play_sound("click")

func do_build() -> void:
 show_message(IslandGame.build(selected))

func do_hire() -> void:
 show_message(IslandGame.hire(selected))

func do_release() -> void:
 show_message(IslandGame.release(selected))

func do_action(kind: String) -> void:
 show_message(IslandGame.conserve(kind))
 close_modal()

func close_modal() -> void:
 if is_instance_valid(modal):
  remove_child(modal)
  modal.queue_free()
 modal = null

func dialog(title: String, text: String, height: int = 570) -> Panel:
 close_modal()
 modal = Control.new()
 modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(modal)
 var shade := ColorRect.new()
 shade.color = Color(0.08,0.19,0.20,0.76)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 modal.add_child(shade)
 var p := IslandUI.panel(modal,Rect2(470,(1080-height)/2.0,980,height))
 IslandUI.label(p,title,Rect2(36,26,910,60),34)
 var scroll := ScrollContainer.new()
 scroll.position = Vector2(36,105)
 scroll.size = Vector2(908,height-205)
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 p.add_child(scroll)
 var body := Label.new()
 body.text = text
 body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 body.add_theme_color_override("font_color",IslandUI.INK)
 body.add_theme_font_size_override("font_size",25)
 scroll.add_child(body)
 IslandUI.button(p,"Continue",Rect2(36,height-76,908,52),close_modal,true)
 return p

func show_help() -> void:
 dialog("Welcome to SustainableIsland", "Build a thriving island without losing what makes it special.\n\n1. Select a building on the map. Build it, then assign its local team.\n2. You have 3 management actions per day. Upgrades and team changes use 1.\n3. Select Next Day to earn income and pay wages, maintenance and utilities.\n4. Monitor water, energy and waste. Use Quick actions below for supplies and cleanup.\n5. Complete 14 days. Aim for rating 70+, 8 jobs, 65+ marine and forest health, and 700 coins.\n\nGuest mode works offline. Progress autosaves on this device after every action.",690)
 # Add persistent quick-action access after the first tutorial construction.
 ensure_toolbox()

func ensure_toolbox() -> void:
 if not has_node("QuickActions"):
  var b := IslandUI.button(self,"Quick actions",Rect2(875,30,230,54),show_toolbox)
  b.name = "QuickActions"
  if is_instance_valid(modal):
   move_child(modal,get_child_count()-1)

func show_toolbox() -> void:
 var p := dialog("Care for your island", "Each action costs 1 management point. Changes are capped at the indicator maximum.\nActions remaining: %d   •   Coins: %d" % [IslandGame.data.ap,IslandGame.data.money],610)
 var choices := [["cleanup","Collect waste  •  100 coins  •  -25 waste, +3 marine",100],["supplies","Emergency supplies  •  80 coins  •  +40 water & energy",80],["culture","Cultural workshop  •  90 coins  •  +8 satisfaction",90]]
 for i in range(choices.size()):
  var entry: Array = choices[i]
  var b := IslandUI.button(p,entry[1],Rect2(36,228+i*84,908,62),do_action.bind(entry[0]))
  b.disabled = IslandGame.blocked(int(entry[2])) != ""

func show_goals() -> void:
 dialog("Your 14-day challenge", "Earn a Sustainable Island award by meeting ALL five goals:\n\nTourism rating: %d / 70 required\nLocal employment: %d / 8 jobs required\nMarine health: %d / 65 required\nForest health: %d / 65 required\nRemaining budget: %d / 700 coins required\n\nRating averages marine health, forest health, satisfaction, employment and financial stability. These are simplified learning indicators." % [IslandGame.rating(),IslandGame.jobs(),IslandGame.data.marine,IslandGame.data.forest,IslandGame.data.money],670)

func show_journal() -> void:
 var entries: Array = IslandGame.data.log.slice(maxi(0,IslandGame.data.log.size()-9))
 dialog("Island journal", "\n".join(PackedStringArray(entries)) if not entries.is_empty() else "Your story starts here. Explore the island and make your first decision.",700)

func next_day() -> void:
 if IslandGame.data.finished:
  show_ending()
  return
 if int(IslandGame.data.ap) > 0:
  var p := dialog("End today with actions remaining?", "You still have %d actions. Unused actions do not carry over.\n\nEnd the day to welcome tourists and calculate operating costs." % IslandGame.data.ap,430)
  IslandUI.button(p,"End day anyway",Rect2(36,244,908,52),advance_day)
 else:
  advance_day()

func advance_day() -> void:
 var report := IslandGame.end_day()
 play_sound("day")
 if bool(report.get("finished",false)):
  show_ending()
 else:
  dialog("Daily island report",str(report.get("report","")),570)

func show_ending() -> void:
 var success := IslandGame.won()
 dialog("Sustainable Island award!" if success else "Season review", "Your island welcomed %d visitors and created %d local jobs.\n\nFinal tourism rating: %d / 100\nMarine health: %d   •   Forest health: %d\nRemaining funds: %d coins\n\n%s\n\nOpen Season goals to compare your results. Return to Menu to start a new island." % [IslandGame.data.total_visitors,IslandGame.jobs(),IslandGame.rating(),IslandGame.data.marine,IslandGame.data.forest,IslandGame.data.money,"You balanced local livelihoods with nature. Well done!" if success else "Try staffing a market early, investing in recycling, and keeping a reserve for conservation."],650)
 play_sound("success" if success else "day")

func toggle_sound() -> void:
 IslandGame.toggle_sound()
 refresh()

func go_menu() -> void:
 if is_syncing:
  show_message("Please wait for cloud sync to finish.")
  return
 IslandGame.save_local()
 get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func sync_cloud() -> void:
 if is_syncing:
  return
 if not IslandGame.save_local():
  show_message(IslandGame.storage_notice)
  return
 if not Supabase.is_logged_in():
  show_message("Saved on this device. Guest mode does not use cloud storage.")
  return
 is_syncing = true
 cloud_button.disabled = true
 cloud_button.text = "Syncing…"
 await IslandGame.cloud_save()
 is_syncing = false
 cloud_button.disabled = false
 cloud_button.text = "Save / cloud sync"
 show_message(IslandGame.last_sync)

func _unhandled_key_input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_cancel"):
  if is_instance_valid(modal):
   close_modal()
  else:
   go_menu()
