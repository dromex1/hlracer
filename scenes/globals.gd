extends Control

signal score_changed()
signal nitro_changed()
@warning_ignore("unused_signal")
signal game_over()

const MEDAL_VALUE: int = 10000

var score_distance := 0 : set = _on_set_score_distance
var score_coins := 0 : set = _on_set_score_coins
var score_jump := 0 : set = _on_set_score_jump
var score_backflip := 0 : set = _on_set_score_backflip
var score_medals := 0 : set = _on_set_score_medals
var nitro := 5.0 : set = _on_set_nitro

# --- UPGRADES ---
# Max level is 10 for each
var upgrade_levels := {
	"engine": 1,
	"suspension": 1,
	"tires": 1,
	"nitro": 1
}

func get_upgrade_cost(type: String) -> int:
	var level = upgrade_levels.get(type, 1)
	return level * 1500

func purchase_upgrade(type: String) -> bool:
	var cost = get_upgrade_cost(type)
	if score_coins >= cost and upgrade_levels[type] < 10:
		score_coins -= cost
		upgrade_levels[type] += 1
		save_config()
		return true
	return false

# --- LEVEL PROGRESSION ---
const LEVEL_FINISH_DISTANCE: int = 3500 # Approx 3-4 minutes driving
signal level_completed()

var game_finished := false
var current_level_index := 0
var _start_time_msec: int = 0
var fuel := 100.0
var max_fuel := 100.0

var game_levels := [
	{"name": "WIEŚ", "cost": 0, "sky": Color(0.5, 0.8, 1.0), "grass": Color(0.4, 0.8, 0.2), "dirt": Color(0.5, 0.3, 0.1)},
	{"name": "JESIENNY LAS", "cost": 5000, "sky": Color(0.6, 0.7, 0.8), "grass": Color(0.8, 0.5, 0.1), "dirt": Color(0.4, 0.2, 0.1)},
	{"name": "PUSTYNIA", "cost": 15000, "sky": Color(0.9, 0.7, 0.3), "grass": Color(0.9, 0.8, 0.4), "dirt": Color(0.8, 0.6, 0.3)},
	{"name": "ŚNIEŻNA KRAINA", "cost": 25000, "sky": Color(0.8, 0.9, 1.0), "grass": Color(0.9, 0.95, 1.0), "dirt": Color(0.75, 0.82, 0.9)},
	{"name": "BAGNO", "cost": 40000, "sky": Color(0.3, 0.4, 0.2), "grass": Color(0.2, 0.3, 0.1), "dirt": Color(0.15, 0.1, 0.05)},
	{"name": "CANYON", "cost": 65000, "sky": Color(0.8, 0.5, 0.2), "grass": Color(0.7, 0.4, 0.1), "dirt": Color(0.6, 0.3, 0.1)},
	{"name": "WULKAN", "cost": 100000, "sky": Color(0.3, 0.1, 0.1), "grass": Color(0.2, 0.05, 0.05), "dirt": Color(0.1, 0.05, 0.05)},
	{"name": "KSIĘŻYC", "cost": 150000, "sky": Color(0.05, 0.05, 0.1), "grass": Color(0.6, 0.6, 0.6), "dirt": Color(0.3, 0.3, 0.3)},
	{"name": "MARS", "cost": 250000, "sky": Color(0.4, 0.2, 0.1), "grass": Color(0.8, 0.3, 0.1), "dirt": Color(0.6, 0.2, 0.1)},
	{"name": "KRYSTALICZNA JASKINIA", "cost": 400000, "sky": Color(0.1, 0.1, 0.2), "grass": Color(0.3, 0.8, 0.9), "dirt": Color(0.1, 0.4, 0.5)},
	{"name": "NEONOWE MIASTO", "cost": 650000, "sky": Color(0.05, 0.0, 0.15), "grass": Color(0.1, 0.9, 0.9), "dirt": Color(0.2, 0.1, 0.3)},
	{"name": "CYBER ZIEMIA", "cost": 850000, "sky": Color(0.1, 0.8, 0.4), "grass": Color(0.0, 1.0, 0.3), "dirt": Color(0.0, 0.5, 0.2)},
	{"name": "DŻUNGLA", "cost": 1000000, "sky": Color(0.4, 0.6, 0.3), "grass": Color(0.1, 0.5, 0.1), "dirt": Color(0.2, 0.15, 0.05)},
	{"name": "ZMROŻONE SZCZYTY", "cost": 1500000, "sky": Color(0.6, 0.8, 1.0), "grass": Color(1.0, 1.0, 1.0), "dirt": Color(0.5, 0.6, 0.8)},
	{"name": "PŁONĄCE PUSTKOWIA", "cost": 2000000, "sky": Color(0.5, 0.2, 0.0), "grass": Color(0.8, 0.4, 0.0), "dirt": Color(0.4, 0.1, 0.0)},
	{"name": "TOKSYCZNE MOKRADŁA", "cost": 2750000, "sky": Color(0.2, 0.5, 0.1), "grass": Color(0.4, 0.9, 0.1), "dirt": Color(0.2, 0.3, 0.0)},
	{"name": "WYSPA W CHMURACH", "cost": 3500000, "sky": Color(0.9, 0.95, 1.0), "grass": Color(0.8, 0.9, 0.9), "dirt": Color(0.6, 0.7, 0.8)},
	{"name": "CZARNA DZIURA", "cost": 5000000, "sky": Color(0.0, 0.0, 0.0), "grass": Color(0.2, 0.0, 0.5), "dirt": Color(0.1, 0.0, 0.2)},
	{"name": "WYMIAR LUSTER", "cost": 7500000, "sky": Color(0.9, 0.1, 0.9), "grass": Color(0.5, 0.1, 0.8), "dirt": Color(0.8, 0.8, 0.9)},
	{"name": "NIESKOŃCZONOŚĆ", "cost": 10000000, "sky": Color(1.0, 0.8, 0.0), "grass": Color(1.0, 1.0, 0.0), "dirt": Color(1.0, 0.5, 0.0)}
]

var unlocked_levels := [0] # Array of unlocked level indices

func _ready() -> void:
	TranslationServer.set_locale("pl")
	load_config()

func save_config() -> void:
	var file := FileAccess.open("user://config.cfg", FileAccess.WRITE)
	if file == null:
		return
	var config := {
		"volume_music": AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Music")),
		"volume_fx": AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"FX")),
		"fullscreen": DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,
		"hdr": get_viewport().use_hdr_2d,
		"score_coins": score_coins,
		"upgrades": upgrade_levels,
		"unlocked_levels": unlocked_levels
	}
	file.store_string(JSON.stringify(config))

func load_config() -> void:
	var file := FileAccess.open("user://config.cfg", FileAccess.READ)
	if file == null:
		# Configuración por defecto
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Music"), linear_to_db(0.5))
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"FX"), linear_to_db(0.5))
		get_viewport().use_hdr_2d = true
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		return
	var config = JSON.parse_string(file.get_as_text())
	if config == null or typeof(config) != TYPE_DICTIONARY:
		return
	if config.has("volume_music"):
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Music"), config["volume_music"])
	if config.has("volume_fx"):
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"FX"), config["volume_fx"])
	if config.has("fullscreen"):
		if config["fullscreen"]:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	if config.has("hdr"):
		get_viewport().use_hdr_2d = config["hdr"]
	if config.has("score_coins"):
		score_coins = config["score_coins"]
	if config.has("upgrades") and typeof(config["upgrades"]) == TYPE_DICTIONARY:
		for key in config["upgrades"].keys():
			upgrade_levels[key] = config["upgrades"][key]
	if config.has("unlocked_levels") and typeof(config["unlocked_levels"]) == TYPE_ARRAY:
		unlocked_levels = []
		for l in config["unlocked_levels"]:
			unlocked_levels.append(int(l))

func new_game() -> void:
	score_distance = 0
	score_jump = 0
	score_backflip = 0
	score_medals = 0
	nitro = 5.0 + (upgrade_levels["nitro"] * 0.5) # Bonus start capacity
	max_fuel = 40.0 + (upgrade_levels["nitro"] * 10.0)
	fuel = max_fuel
	game_finished = false
	_start_time_msec = Time.get_ticks_msec()
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func check_game_completion() -> void:
	if not game_finished and score_distance >= LEVEL_FINISH_DISTANCE:
		game_finished = true
		score_coins += 5000 # Bonus for beating the level
		
		# Give medals based on run speed
		var run_sec = (Time.get_ticks_msec() - _start_time_msec) / 1000.0
		if run_sec < 140.0:
			score_medals = 4
		elif run_sec < 180.0:
			score_medals = 3
		elif run_sec < 230.0:
			score_medals = 2
		else:
			score_medals = 1
			
		level_completed.emit()
		
		# Auto-unlock next level
		var next_idx = current_level_index + 1
		if next_idx < game_levels.size() and not (next_idx in unlocked_levels):
			unlocked_levels.append(next_idx)
		
		save_config()
		game_over.emit()

func _on_set_score_distance(value : int) -> void:
	score_distance = value
	score_changed.emit()
	check_game_completion()


func _on_set_score_coins(value : int) -> void:
	score_coins = value
	score_changed.emit()


func _on_set_score_jump(value : int) -> void:
	score_jump = value
	score_changed.emit()


func _on_set_score_backflip(value : int) -> void:
	score_backflip = value
	score_changed.emit()


func _on_set_score_medals(value : int) -> void:
	score_medals = value
	score_changed.emit()


func _on_set_nitro(value : float) -> void:
	nitro = clampf(value, 0.0, 5.0)
	nitro_changed.emit()
