extends Node2D

@onready var camera_2d: Camera2D = %Camera2D
@onready var terrain: Node2D = %Terrain
@onready var car: RigidBody2D = %Car
@onready var tab_container: TabContainer = %TabContainer
@onready var play_button: Button = %PlayButton
@onready var credits_button: Button = %CreditsButton
@onready var settings_button: Button = %SettingsButton
@onready var exit_button: Button = %ExitButton
@onready var coins_label: Label = %CoinsLabel

# Upgrade UI references
@onready var engine_btn: Button = %EngineUpgradeBtn
@onready var suspension_btn: Button = %SuspensionUpgradeBtn
@onready var tires_btn: Button = %TiresUpgradeBtn
@onready var nitro_btn: Button = %NitroUpgradeBtn
@onready var engine_lvl: Label = %EngineLvlLabel
@onready var suspension_lvl: Label = %SuspensionLvlLabel
@onready var tires_lvl: Label = %TiresLvlLabel
@onready var nitro_lvl: Label = %NitroLvlLabel


@onready var levels_grid: GridContainer = %LevelsGrid

const GARAGE_PLANE := preload("res://scenes/planes/garage.tscn")
const PREMIUM_THEME := preload("res://gui/premium_theme.tres")

func _ready() -> void:
	car.position.y = terrain.get_position_y(car.position.x) - 150
	
	# Apply premium theme
	tab_container.get_node("Garage").theme = PREMIUM_THEME
	tab_container.get_node("LevelSelect").theme = PREMIUM_THEME
	
	# Stop the car driving infinitely on the menu
	car.set_physics_process(false)
	car.set_process(false)
	car.linear_velocity = Vector2.ZERO
	car.angular_velocity = 0
	car.freeze = true
	
	# Spawn garage background behind the car
	var garage_bg = GARAGE_PLANE.instantiate()
	terrain.add_child(garage_bg)
	garage_bg.position.x = car.position.x + 300
	garage_bg.position.y = car.position.y + 120 # Lowered slightly so car rests properly
	
	play_button.grab_focus()
	_refresh_ui()
	_build_levels_ui()


func _build_levels_ui() -> void:
	# Clear grid
	for child in levels_grid.get_children():
		child.queue_free()
		
	# Populate 20 dynamic levels
	for i in range(Globals.game_levels.size()):
		var lvl = Globals.game_levels[i]
		var is_unlocked = i in Globals.unlocked_levels
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(250, 200)
		btn.name = "LevelBtn_" + str(i)
		btn.pressed.connect(func(): _on_level_selected(i))
		
		var vb = VBoxContainer.new()
		vb.set_anchors_preset(Control.PRESET_FULL_RECT)
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(vb)
		
		var bg_prev = ColorRect.new()
		bg_prev.custom_minimum_size = Vector2(0, 80)
		bg_prev.color = lvl.sky
		bg_prev.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var grass_bar = ColorRect.new()
		grass_bar.custom_minimum_size = Vector2(0, 20)
		grass_bar.color = lvl.grass
		grass_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		grass_bar.offset_top = -20
		bg_prev.add_child(grass_bar)
		vb.add_child(bg_prev)
		
		var lbl = Label.new()
		lbl.text = lvl.name
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 24)
		vb.add_child(lbl)
		
		var lbl_cost = Label.new()
		lbl_cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if is_unlocked:
			lbl_cost.text = "ODBLOKOWANE"
			lbl_cost.modulate = Color(0.2, 1.0, 0.2)
		else:
			lbl_cost.text = "KOSZT: " + str(lvl.cost)
			lbl_cost.modulate = Color(1.0, 0.8, 0.2)
		vb.add_child(lbl_cost)
		
		levels_grid.add_child(btn)


func _on_level_selected(idx: int) -> void:
	var lvl = Globals.game_levels[idx]
	if idx in Globals.unlocked_levels:
		Globals.current_level_index = idx
		Globals.new_game()
	else:
		if Globals.score_coins >= lvl.cost:
			Globals.score_coins -= lvl.cost
			Globals.unlocked_levels.append(idx)
			Globals.save_config()
			_refresh_ui()
			_build_levels_ui()


func _process(_delta: float) -> void:
	if car.position.x >= -600:
		camera_2d.position.x = car.position.x + 600
	if tab_container.current_tab == 0:
		if Input.is_action_just_pressed(&"ui_cancel"):
			if exit_button.has_focus():
				_on_exit_button_pressed()
			else:
				exit_button.grab_focus()


func _refresh_ui() -> void:
	coins_label.text = "Monety: " + str(Globals.score_coins)
	engine_lvl.text = "Poz. " + str(Globals.upgrade_levels["engine"]) + "/10  |  Koszt: " + str(Globals.get_upgrade_cost("engine"))
	suspension_lvl.text = "Poz. " + str(Globals.upgrade_levels["suspension"]) + "/10  |  Koszt: " + str(Globals.get_upgrade_cost("suspension"))
	tires_lvl.text = "Poz. " + str(Globals.upgrade_levels["tires"]) + "/10  |  Koszt: " + str(Globals.get_upgrade_cost("tires"))
	nitro_lvl.text = "Poz. " + str(Globals.upgrade_levels["nitro"]) + "/10  |  Koszt: " + str(Globals.get_upgrade_cost("nitro"))
	engine_btn.disabled = Globals.upgrade_levels["engine"] >= 10 or Globals.score_coins < Globals.get_upgrade_cost("engine")
	suspension_btn.disabled = Globals.upgrade_levels["suspension"] >= 10 or Globals.score_coins < Globals.get_upgrade_cost("suspension")
	tires_btn.disabled = Globals.upgrade_levels["tires"] >= 10 or Globals.score_coins < Globals.get_upgrade_cost("tires")
	nitro_btn.disabled = Globals.upgrade_levels["nitro"] >= 10 or Globals.score_coins < Globals.get_upgrade_cost("nitro")


func _on_play_button_pressed() -> void:
	# Show Garage instead of starting directly
	tab_container.current_tab = 3
	_refresh_ui()


func _on_credits_button_pressed() -> void:
	tab_container.current_tab = 2


func _on_settings_button_pressed() -> void:
	tab_container.current_tab = 1


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_settings_back_pressed() -> void:
	tab_container.current_tab = 0
	settings_button.call_deferred(&"grab_focus")


func _on_credits_back_pressed() -> void:
	tab_container.current_tab = 0
	credits_button.call_deferred(&"grab_focus")


func _on_garage_back_pressed() -> void:
	tab_container.current_tab = 0
	play_button.call_deferred(&"grab_focus")


func _on_garage_start_pressed() -> void:
	# Show Level Select
	tab_container.current_tab = 4
	
	
func _on_level_select_back_pressed() -> void:
	tab_container.current_tab = 3
	_refresh_ui()


func _on_engine_upgrade_pressed() -> void:
	Globals.purchase_upgrade("engine")
	_refresh_ui()


func _on_suspension_upgrade_pressed() -> void:
	Globals.purchase_upgrade("suspension")
	_refresh_ui()


func _on_tires_upgrade_pressed() -> void:
	Globals.purchase_upgrade("tires")
	_refresh_ui()


func _on_nitro_upgrade_pressed() -> void:
	Globals.purchase_upgrade("nitro")
	_refresh_ui()
