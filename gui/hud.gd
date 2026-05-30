extends CanvasLayer

const HUD_MESSAGE_SCENE := preload("res://gui/misc/hud_message.tscn")

var _msg_jump_score = null
var _msg_backflip_score = null

@onready var hud_main: MarginContainer = %HudMain
@onready var progress_bar: TextureProgressBar = %ProgressBar
@onready var score_label: Label = %ScoreLabel
@onready var level_progress_bar: ProgressBar = %LevelProgressBar
@onready var level_complete_label: Label = %LevelCompleteLabel
@onready var pause_btn: Button = %PauseButton


func _ready() -> void:
	Globals.game_over.connect(_on_game_over)
	Globals.score_changed.connect(_on_score_changed)
	Globals.nitro_changed.connect(_on_nitro_changed)
	Globals.level_completed.connect(_on_level_completed)
	level_complete_label.visible = false
	level_progress_bar.max_value = Globals.LEVEL_FINISH_DISTANCE
	level_progress_bar.value = 0
	_apply_level_sky()
	
	if pause_btn:
		pause_btn.pressed.connect(func():
			var ev = InputEventAction.new()
			ev.action = "ui_cancel"
			ev.pressed = true
			Input.parse_input_event(ev)
			# Release instantly
			var ev2 = InputEventAction.new()
			ev2.action = "ui_cancel"
			ev2.pressed = false
			Input.parse_input_event(ev2)
		)


func _process(_delta: float) -> void:
	# Update progress bar
	level_progress_bar.value = clampf(Globals.score_distance, 0, Globals.LEVEL_FINISH_DISTANCE)


func _apply_level_sky() -> void:
	# Set the sky color based on the current level's palette
	var lvl_idx = clampi(Globals.current_level_index, 0, Globals.game_levels.size() - 1)
	var sky_color: Color = Globals.game_levels[lvl_idx].sky
	RenderingServer.set_default_clear_color(sky_color)


func _on_level_completed() -> void:
	level_complete_label.visible = true
	level_complete_label.text = "POZIOM UKOŃCZONY!\n+5000 MONET"


func _on_game_over():
	hud_main.visible = false


func _on_score_changed():
	var score := Globals.score_distance
	score += Globals.score_coins
	score += ceili(Globals.score_jump)
	score += ceili(Globals.score_backflip)
	score += Globals.score_medals * Globals.MEDAL_VALUE
	score_label.text = tr("SCORE") + ": " + str(score)


func _on_nitro_changed():
	progress_bar.value = Globals.nitro


func _on_car_jump_scored(score: int) -> void:
	if not is_instance_valid(_msg_jump_score) or not _msg_jump_score.is_running():
		_msg_jump_score = HUD_MESSAGE_SCENE.instantiate()
		hud_main.add_child(_msg_jump_score)
		_msg_jump_score.position = Vector2(300, 170)
		_msg_jump_score.set_title("SKOK")
	_msg_jump_score.set_message("+" + str(score))


func _on_car_jump_landed() -> void:
	_msg_jump_score = null


func _on_car_backflip_performed(multi: int) -> void:
	if not is_instance_valid(_msg_backflip_score) or not _msg_backflip_score.is_running():
		_msg_backflip_score = HUD_MESSAGE_SCENE.instantiate()
		hud_main.add_child(_msg_backflip_score)
		_msg_backflip_score.position = Vector2(450, 230)
		_msg_backflip_score.set_title("SALTO")
	if multi == 1:
		_msg_backflip_score.set_title("SALTO")
		_msg_backflip_score.set_message("+1000")
	else:
		_msg_backflip_score.set_title("SALTO x" + str(multi))
		_msg_backflip_score.set_message("+" + str(1000 * multi))
