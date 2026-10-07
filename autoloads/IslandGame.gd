extends Node
## Small deterministic simulation. All money values are fictional island coins.
signal changed
const DAYS := 14
const WORKERS := 12
const FACILITIES := {
 "guesthouse": {"title":"Palm Guesthouse", "cost":500, "staff":2, "max":3, "sdg":"SDG 8 • Decent work", "description":"Small, locally staffed accommodation. Each level adds 8 visitor spaces; workers keep it open."},
 "hotel": {"title":"Bay Hotel", "cost":750, "staff":4, "max":2, "sdg":"SDG 8 / 12 • Responsible growth", "description":"Each level adds 16 spaces, but construction removes 6 forest points. More visitors also use more resources."},
 "market": {"title":"Village Market", "cost":300, "staff":2, "max":2, "sdg":"SDG 8 • Local businesses", "description":"Food and crafts made by local businesses. Each staffed level earns 7 extra coins per visitor."},
 "culture": {"title":"Heritage House", "cost":350, "staff":2, "max":2, "sdg":"SDG 8 / 12 • Cultural heritage", "description":"Support local guides and traditional crafts. Staffed levels improve satisfaction and earn 4 coins per visitor."},
 "waste": {"title":"Recycling Station", "cost":350, "staff":1, "max":2, "sdg":"SDG 12 • Responsible consumption", "description":"Each staffed level removes 12 waste each day. Uncollected waste damages marine and forest habitats."},
 "utilities": {"title":"Clean Utilities", "cost":400, "staff":1, "max":2, "sdg":"SDG 12 • Resource efficiency", "description":"Rainwater tanks and solar panels. Each staffed level restores 20 extra water and energy daily."}
}
var data: Dictionary = {}
var profile := "guest"
var storage_notice := ""
var muted := false
var last_sync := ""

func _ready() -> void:
 reset()
 var cfg := ConfigFile.new()
 if cfg.load("user://island_settings.cfg") == OK:
  muted = bool(cfg.get_value("audio", "muted", false))

func reset() -> void:
 data = {"version":1, "day":1, "money":1800, "ap":3, "water":100, "energy":100, "waste":5, "marine":82, "forest":85, "satisfaction":70, "visitors":0, "total_visitors":0, "finished":false, "updated":0, "buildings":{}, "staff":{}, "explored":[], "log":[], "last_report":"Welcome, island manager. Select a location to begin."}
 for key in FACILITIES:
  data.buildings[key] = 0
  data.staff[key] = 0
 data.buildings.guesthouse = 1
 data.staff.guesthouse = 2
 changed.emit()

func select_profile(id: String) -> bool:
 profile = id if not id.is_empty() else "guest"
 reset()
 storage_notice = ""
 return load_local()

func save_path() -> String:
 return "user://island_%s.json" % profile.sha256_text().substr(0, 24)

func save_local() -> bool:
 data.updated = int(Time.get_unix_time_from_system())
 var path := save_path()
 var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
 if file == null:
  storage_notice = "Could not save locally. Check device storage."
  return false
 file.store_string(JSON.stringify(data))
 file.close()
 var error := DirAccess.rename_absolute(path + ".tmp", path)
 if error != OK:
  storage_notice = "Could not replace the local save."
  return false
 storage_notice = "Saved on this device"
 return true

func load_local() -> bool:
 if not FileAccess.file_exists(save_path()):
  return false
 var parsed = JSON.parse_string(FileAccess.get_file_as_string(save_path()))
 if not restore(parsed):
  storage_notice = "Save could not be read. A new island is ready; the old file was not changed."
  return false
 return true

func restore(value: Variant) -> bool:
 if not value is Dictionary or int(value.get("version", 0)) != 1:
  return false
 for key in ["day","money","ap","water","energy","waste","marine","forest","satisfaction","visitors","total_visitors","updated"]:
  if not value.has(key) or not (value[key] is int or value[key] is float):
   return false
 if not value.get("buildings") is Dictionary or not value.get("staff") is Dictionary:
  return false
 if not value.get("log") is Array or not value.get("explored") is Array or not value.get("finished") is bool:
  return false
 for key in FACILITIES:
  if not value.buildings.has(key) or not value.staff.has(key):
   return false
  if not (value.buildings[key] is float or value.buildings[key] is int) or not (value.staff[key] is float or value.staff[key] is int):
   return false
  if int(value.buildings[key]) < 0 or int(value.buildings[key]) > int(FACILITIES[key].max):
   return false
  if int(value.staff[key]) < 0 or int(value.staff[key]) > int(FACILITIES[key].staff) or (int(value.buildings[key]) == 0 and int(value.staff[key]) != 0):
   return false
 var workers := 0
 for n in value.staff.values():
  workers += int(n)
 if workers > WORKERS or int(value.day) < 1 or int(value.day) > DAYS or int(value.ap) < 0 or int(value.ap) > 3:
  return false
 data = value.duplicate(true)
 for key in ["water","energy","marine","forest","satisfaction"]:
  data[key] = clampi(int(data[key]), 0, 100)
 data.waste = clampi(int(data.waste), 0, 200)
 data.money = maxi(0, int(data.money))
 data.last_report = str(data.get("last_report", "Island restored."))
 changed.emit()
 return true

func jobs() -> int:
 var count := 0
 for n in data.staff.values():
  count += int(n)
 return count

func active(key: String) -> int:
 return int(data.buildings[key]) if int(data.staff[key]) == int(FACILITIES[key].staff) else 0

func impact() -> int:
 return clampi(roundi((200.0 - float(data.marine) - float(data.forest)) / 2.0), 0, 100)

func rating() -> int:
 var economic := minf(100.0, float(data.money) / 15.0)
 return roundi((float(data.marine) + float(data.forest) + float(data.satisfaction) + jobs() * 100.0 / WORKERS + economic) / 5.0)

func won() -> bool:
 return rating() >= 70 and jobs() >= 8 and int(data.marine) >= 65 and int(data.forest) >= 65 and int(data.money) >= 700

func visit(key: String) -> void:
 if not data.explored.has(key):
  data.explored.append(key)
  save_local()
  changed.emit()

func cost(key: String) -> int:
 return int(FACILITIES[key].cost) + int(data.buildings[key]) * 150

func blocked(price: int) -> String:
 if data.finished:
  return "This season is complete. Start a new island from the menu."
 if int(data.ap) <= 0:
  return "No actions left today. Select Next Day."
 if int(data.money) < price:
  return "Not enough coins for this action."
 return ""

func commit(message: String, price: int) -> String:
 data.money = int(data.money) - price
 data.ap = int(data.ap) - 1
 data.log.append("Day %d: %s" % [data.day, message])
 if data.log.size() > 80:
  data.log.pop_front()
 save_local()
 changed.emit()
 return message

func build(key: String) -> String:
 var price := cost(key)
 var reason := blocked(price)
 if reason != "":
  return reason
 if int(data.buildings[key]) >= int(FACILITIES[key].max):
  return "Already at maximum level."
 data.buildings[key] = int(data.buildings[key]) + 1
 if key == "hotel":
  data.forest = maxi(0, int(data.forest) - 6)
 return commit("%s is now level %d. Assign its workers to open it." % [FACILITIES[key].title, data.buildings[key]], price)

func hire(key: String) -> String:
 var reason := blocked(0)
 if reason != "":
  return reason
 if int(data.buildings[key]) == 0:
  return "Build this facility first."
 var needed := int(FACILITIES[key].staff) - int(data.staff[key])
 if needed <= 0:
  return "Already fully staffed."
 if jobs() + needed > WORKERS:
  return "Not enough available workers. Reassign a team first."
 data.staff[key] = int(FACILITIES[key].staff)
 return commit("Local team assigned to %s. Wages: %d coins/day." % [FACILITIES[key].title, needed * 6], 0)

func release(key: String) -> String:
 var reason := blocked(0)
 if reason != "":
  return reason
 if int(data.staff[key]) == 0:
  return "No workers are assigned here."
 data.staff[key] = 0
 return commit("Team returned to the available workforce. This facility is paused.", 0)

func conserve(kind: String) -> String:
 var prices := {"cleanup":100,"reef":130,"forest":130,"supplies":80,"culture":90}
 var price: int = prices[kind]
 var reason := blocked(price)
 if reason != "":
  return reason
 var message := ""
 match kind:
  "cleanup":
   data.waste = maxi(0, int(data.waste) - 25)
   data.marine = mini(100, int(data.marine) + 3)
   message = "Cleanup removed up to 25 waste and restored 3 marine points."
  "reef":
   data.marine = mini(100, int(data.marine) + 12)
   message = "Reef protection restored up to 12 marine points. SDG 14: protect life below water."
  "forest":
   data.forest = mini(100, int(data.forest) + 12)
   message = "Native planting restored up to 12 forest points. SDG 15: protect life on land."
  "supplies":
   data.water = mini(100, int(data.water) + 40)
   data.energy = mini(100, int(data.energy) + 40)
   message = "Emergency supplies restored up to 40 water and energy."
  "culture":
   data.satisfaction = mini(100, int(data.satisfaction) + 8)
   message = "A local cultural workshop raised satisfaction by up to 8 points."
 return commit(message, price)

func forecast() -> String:
 match int(data.day):
  4: return "Holiday arrivals • visitor demand +4 today."
  7: return "Storm warning • marine -6, forest -5 tonight."
  10: return "Dry day • no natural water refill tonight."
  12: return "Heritage festival • staffed Heritage House earns a 30% revenue bonus."
 return "Calm weather • plan your island's next step."

func end_day() -> Dictionary:
 if data.finished:
  return {}
 var day := int(data.day)
 var capacity := active("guesthouse") * 8 + active("hotel") * 16
 var demand := 5 + int(float(data.satisfaction) / 8.0) + active("culture") * 3
 if day == 4:
  demand += 4
 var tourists := mini(capacity, demand)
 var generation := tourists
 var collection := active("waste") * 12
 data.waste = clampi(int(data.waste) + generation - collection, 0, 200)
 var refill := active("utilities") * 20
 var water_delta := (0 if day == 10 else 20) + refill - tourists * 2
 var energy_delta := 20 + refill - tourists
 data.water = clampi(int(data.water) + water_delta, 0, 100)
 data.energy = clampi(int(data.energy) + energy_delta, 0, 100)
 var damage := int(float(data.waste) / 18.0)
 data.marine = maxi(0, int(data.marine) - damage)
 data.forest = maxi(0, int(data.forest) - int(float(damage) / 2.0))
 if day == 7:
  data.marine = maxi(0, int(data.marine) - 6)
  data.forest = maxi(0, int(data.forest) - 5)
 var satisfaction_delta := active("culture") * 2 + (1 if int(data.marine) >= 70 else -2)
 if int(data.waste) > 30:
  satisfaction_delta -= 4
 if int(data.water) < 20 or int(data.energy) < 20:
  satisfaction_delta -= 8
 data.satisfaction = clampi(int(data.satisfaction) + satisfaction_delta, 0, 100)
 var revenue := tourists * (20 + active("market") * 7 + active("culture") * 4)
 if day == 12 and active("culture") > 0:
  revenue = roundi(revenue * 1.3)
 var maintenance := 0
 for level in data.buildings.values():
  maintenance += int(level) * 10
 var expenses := jobs() * 6 + maintenance + 20
 var net := revenue - expenses
 var bankrupt := int(data.money) + net < 0
 data.money = maxi(0, int(data.money) + net)
 data.visitors = tourists
 data.total_visitors = int(data.total_visitors) + tourists
 var report := "DAY %d COMPLETE\n%d visitors  •  Income %d  •  Expenses %d  •  Net %+d coins\nWaste: +%d generated / -%d collected. Water %+d, energy %+d (capped at 100).\n%s\n\n%s" % [day,tourists,revenue,expenses,net,generation,collection,water_delta,energy_delta,forecast(),"Waste harms habitats; staffed recycling reduces daily pressure. Local jobs earn wages and raise your rating."]
 data.last_report = report
 data.log.append("Day %d closed: %d visitors, %+d coins, rating %d." % [day,tourists,net,rating()])
 data.finished = day >= DAYS or bankrupt
 if not data.finished:
  data.day = day + 1
  data.ap = 3
 if bankrupt:
  data.last_report += "\n\nThe island could not cover operating costs. Try fewer buildings and keep businesses staffed."
 save_local()
 changed.emit()
 return {"report":data.last_report,"finished":data.finished,"won":won() and not bankrupt}

func toggle_sound() -> void:
 muted = not muted
 var cfg := ConfigFile.new()
 cfg.set_value("audio", "muted", muted)
 cfg.save("user://island_settings.cfg")

func cloud_save() -> Dictionary:
 if not Supabase.is_logged_in():
  return {"ok":false,"error":"Guest progress is saved on this device. Log in to use cloud saves."}
 var result: Dictionary = await Supabase.island_request(HTTPClient.METHOD_POST, "/rest/v1/island_saves?on_conflict=user_id", {"user_id":Supabase.user_id,"save_data":data.duplicate(true)}, PackedStringArray(["Prefer: resolution=merge-duplicates"]))
 last_sync = "Cloud save complete." if result.ok else "Local save kept. Cloud unavailable: " + str(result.error)
 return result

func cloud_load() -> String:
 if not Supabase.is_logged_in():
  return "Guest mode • saves stay on this device."
 var result: Dictionary = await Supabase.island_request(HTTPClient.METHOD_GET, "/rest/v1/island_saves?select=save_data&user_id=eq." + Supabase.user_id)
 if not result.ok:
  return "Local mode • cloud unavailable. See README for database setup."
 if result.data is Array and not result.data.is_empty():
  var remote = result.data[0].get("save_data", {})
  if remote is Dictionary and int(remote.get("updated", 0)) > int(data.updated):
   if restore(remote):
    save_local()
    return "Latest cloud island restored."
   return "Cloud save unreadable. Local island kept."
 return "Island ready • local autosave enabled."
