extends Node
var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(message)
func _ready() -> void:
 call_deferred("run")
func run() -> void:
 IslandGame.profile = "automated_test"
 IslandGame.muted = true
 IslandGame.reset()
 check(IslandGame.jobs() == 2, "Starter accommodation has two jobs")
 check(IslandGame.active("guesthouse") == 1, "Starter accommodation opens")
 IslandGame.build("market")
 check(IslandGame.active("market") == 0, "Unstaffed business earns nothing")
 IslandGame.hire("market")
 check(IslandGame.active("market") == 1, "Staffed business opens")
 IslandGame.build("waste")
 var snapshot := IslandGame.data.duplicate(true)
 IslandGame.conserve("reef")
 check(IslandGame.data == snapshot,"No actions means no mutation")
 IslandGame.end_day()
 check(IslandGame.data.visitors == 8, "Visitors respect accommodation capacity")
 IslandGame.hire("waste")
 IslandGame.build("culture")
 IslandGame.hire("culture")
 IslandGame.end_day()
 IslandGame.build("utilities")
 IslandGame.hire("utilities")
 IslandGame.conserve("forest")
 IslandGame.end_day()
 check(IslandGame.jobs() == 8,"Employment sums assigned teams")
 check(IslandGame.save_local(),"Local save succeeds")
 var money := int(IslandGame.data.money)
 IslandGame.data.money = 99
 check(IslandGame.load_local() and int(IslandGame.data.money) == money,"Save round trip restores state")
 snapshot = IslandGame.data.duplicate(true)
 check(not IslandGame.restore({"version":1}),"Incomplete save rejected")
 check(IslandGame.data == snapshot,"Bad save leaves current state unchanged")
 var original_profile := IslandGame.save_path()
 IslandGame.profile = "separate_account_test"
 check(IslandGame.save_path() != original_profile,"Account save isolation")
 IslandGame.profile = "automated_test"
 for i in range(10):
  IslandGame.end_day()
 var last := IslandGame.end_day()
 check(bool(last.finished),"Season ends on day 14")
 check(IslandGame.won(),"Balanced strategy can win")
 snapshot = IslandGame.data.duplicate(true)
 IslandGame.end_day()
 IslandGame.build("hotel")
 check(IslandGame.data == snapshot,"Finished seasons cannot advance or build")
 print("Balanced route: rating=%d jobs=%d money=%d marine=%d forest=%d" % [IslandGame.rating(),IslandGame.jobs(),IslandGame.data.money,IslandGame.data.marine,IslandGame.data.forest])
 IslandGame.reset()
 IslandGame.data.money = 0
 snapshot = IslandGame.data.duplicate(true)
 IslandGame.build("hotel")
 check(IslandGame.data == snapshot,"Insufficient funds block construction")
 IslandGame.data.staff.guesthouse = 0
 IslandGame.end_day()
 check(IslandGame.data.finished,"Unfunded operating costs end the season")
 IslandGame.reset()
 for i in range(14):
  IslandGame.end_day()
 check(not IslandGame.won(),"Unmanaged island does not win")
 check(IslandGame.data.marine < 65,"Uncollected waste harms marine habitat")
 # Instantiate every shipped user screen to catch node-path and script failures.
 for path in ["LoginScreen","CreateAccount","ForgotPassword","MainMenu","Game"]:
  var screen := load("res://scenes/%s.tscn" % path).instantiate() as Control
  add_child(screen)
  await get_tree().process_frame
  await get_tree().process_frame
  if path == "Game":
   screen.close_modal()
   for key in IslandGame.FACILITIES:
    screen.select_zone(key)
   screen.select_zone("forest")
   screen.select_zone("reef")
   screen.show_toolbox()
   screen.close_modal()
   screen.show_goals()
   screen.close_modal()
   screen.show_journal()
   screen.close_modal()
  screen.queue_free()
  await get_tree().process_frame
 print("TEST RESULT: %d checks, %d failures" % [checks,failures])
 await get_tree().process_frame
 await get_tree().process_frame
 get_tree().quit(1 if failures else 0)
