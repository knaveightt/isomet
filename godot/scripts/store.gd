extends RefCounted
# Versioned, non-executable user data. A failed save keeps the previous checkpoint.
static var SAVE = "user://smoke_journey.json" if "--smoke" in OS.get_cmdline_user_args() or "--tests" in OS.get_cmdline_user_args() else "user://journey.json"
static var SETTINGS = "user://smoke_settings.json" if "--smoke" in OS.get_cmdline_user_args() or "--tests" in OS.get_cmdline_user_args() else "user://settings.json"
static func read_json(path: String) -> Dictionary:
 if not FileAccess.file_exists(path): return {}
 var file = FileAccess.open(path, FileAccess.READ)
 if file == null: return {}
 var value = JSON.parse_string(file.get_as_text())
 return value if value is Dictionary else {}
static func write_json(path: String, value: Dictionary) -> bool:
 var file = FileAccess.open(path + ".tmp", FileAccess.WRITE)
 if file == null: return false
 file.store_string(JSON.stringify(value, "  "))
 file.flush()
 file.close()
 return DirAccess.rename_absolute(path + ".tmp", path) == OK
static func valid_save(value: Dictionary) -> bool:
 if value.get("version") != 1: return false
 if not value.get("name") is String or value.name.strip_edges().is_empty() or value.name.length() > 20: return false
 if not value.get("variant") is float and not value.get("variant") is int: return false
 if int(value.variant) < 0 or int(value.variant) > 7: return false
 if not value.get("location") in ["City", "Suburb", "Midwest"]: return false
 var p = value.get("position", [])
 if not p is Array or p.size() != 3: return false
 for v in p:
  if not (v is float or v is int) or not is_finite(float(v)): return false
 if abs(float(p[0])) > 5.6 or float(p[1]) < -1 or float(p[1]) > 4 or float(p[2]) < -19.5 or float(p[2]) > 7.5: return false
 return value.get("powered") is bool and value.get("escaped") is bool
