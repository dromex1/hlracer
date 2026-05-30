extends RigidBody2D

signal jump_scored(score : int)
signal jump_landed()
signal backflip_performed(multi : int)

const PARTICLES_BANG := preload("res://particles/bang.tscn")

@export var TORQUE := 700.0
@export var AUTO_ADVANCE := false
@export var ENABLE_USER := true
@export var MUTE := false

var _pitch := 0.0
var _air_time := 0.0
var _air_score := 0
var _backflip := false
var _backflip_multi := 1

# Upgrade-driven values (calculated once at _ready)
var _effective_torque := 700.0
var _effective_nitro_force := 150.0

@onready var pin_rear: PinJoint2D = $PinJointRear
@onready var pin_front: PinJoint2D = $PinJointFront
@onready var mark_rear: Marker2D = $PinJointRear/Marker2D
@onready var mark_front: Marker2D = $PinJointFront/Marker2D
@onready var wheel_rear: RigidBody2D = $PinJointRear/WheelRear
@onready var wheel_front: RigidBody2D = $PinJointFront/WheelFront
@onready var head: RigidBody2D = $Head
@onready var audio_engine: AudioStreamPlayer = $AudioEngine
@onready var particle_nitrous: GPUParticles2D = $ParticleNitrous
@onready var body_head_limit: StaticBody2D = $BodyHeadLimit


func _ready() -> void:
	_apply_upgrades()


func _apply_upgrades() -> void:
	var eng_lvl = Globals.upgrade_levels.get("engine", 1)
	var sus_lvl = Globals.upgrade_levels.get("suspension", 1)
	var tire_lvl = Globals.upgrade_levels.get("tires", 1)
	var nitro_lvl = Globals.upgrade_levels.get("nitro", 1)
	
	# Engine: +8% torque per level
	_effective_torque = TORQUE * (1.0 + (eng_lvl - 1) * 0.08)
	
	# Suspension: reduce linear damp for smoother ride
	linear_damp = maxf(0.0, linear_damp - (sus_lvl - 1) * 0.05)
	
	# Tires: increase wheel friction
	if wheel_rear.get_child_count() > 0:
		for child in wheel_rear.get_children():
			if child is CollisionShape2D and child.shape:
				wheel_rear.physics_material_override = _make_tire_material(tire_lvl)
				break
	if wheel_front.get_child_count() > 0:
		for child in wheel_front.get_children():
			if child is CollisionShape2D and child.shape:
				wheel_front.physics_material_override = _make_tire_material(tire_lvl)
				break
	
	# Nitro: +10% force per level
	_effective_nitro_force = 150.0 * (1.0 + (nitro_lvl - 1) * 0.1)


func _make_tire_material(tire_lvl: int) -> PhysicsMaterial:
	var mat = PhysicsMaterial.new()
	mat.friction = 1.0 + (tire_lvl - 1) * 0.08
	mat.bounce = 0.05
	return mat


func _physics_process(delta: float) -> void:
	if _pitch > 0:
		_pitch -= delta
	else:
		_pitch += delta
	_pitch += Input.get_action_strength(&"speed_up") * delta * 1.5
	_pitch -= Input.get_action_strength(&"speed_down") * delta * 1.5
	_pitch = clampf(_pitch, -1, 1)
	if MUTE:
		audio_engine.stop()
	audio_engine.pitch_scale = absf(_pitch) + 1.0
	
	# Score por saltos
	if not freeze and wheel_rear.get_contact_count() == 0 and wheel_front.get_contact_count() == 0:
		_air_time += delta
		if _air_time >= 0.5:
			_air_score += 50
			_air_time -= 0.5
			jump_scored.emit(_air_score)
	elif not freeze and _air_time > 0:
		jump_landed.emit()
		Globals.score_jump += _air_score
		_air_score = 0
		_air_time = 0.0
		_backflip_multi = 1
	
	# Score por volteretas
	if rotation_degrees > 160 and rotation_degrees < 200:
		if not _backflip:
			_backflip = true
			Globals.score_backflip += 1000 * _backflip_multi
			backflip_performed.emit(_backflip_multi)
			_backflip_multi += 1
	else:
		_backflip = false
	
	if AUTO_ADVANCE:
		wheel_rear.apply_torque_impulse(250)
		wheel_front.apply_torque_impulse(250)
	
	if ENABLE_USER:
		wheel_rear.apply_torque_impulse(_effective_torque * Input.get_action_strength(&"speed_up"))
		wheel_front.apply_torque_impulse(_effective_torque * Input.get_action_strength(&"speed_up"))
		wheel_rear.apply_torque_impulse(-_effective_torque * Input.get_action_strength(&"speed_down"))
		wheel_front.apply_torque_impulse(-_effective_torque * Input.get_action_strength(&"speed_down"))
		
		apply_torque_impulse(-1000.0 * Input.get_action_strength(&"turn_left"))
		apply_torque_impulse(1000.0 * Input.get_action_strength(&"turn_right"))
		
		wheel_rear.lock_rotation = Input.is_action_pressed(&"brake")
		wheel_front.lock_rotation = Input.is_action_pressed(&"brake")
		
		if Input.is_action_pressed(&"nitro"):
			if Globals.nitro > 0:
				Globals.nitro -= delta
				particle_nitrous.emitting = true
				var dir := pin_rear.global_position - mark_rear.global_position
				wheel_rear.apply_central_force(dir * _effective_nitro_force)
				dir = pin_front.global_position - mark_front.global_position
				wheel_front.apply_central_force(dir * _effective_nitro_force)
			else:
				particle_nitrous.emitting = false
		else:
			particle_nitrous.emitting = false


func _on_head_body_entered(body: Node) -> void:
	if body == body_head_limit:
		return
	set_deferred(&"freeze", true)
	wheel_front.set_deferred(&"freeze", true)
	wheel_rear.set_deferred(&"freeze", true)
	head.set_deferred(&"freeze", true)
	body.set_deferred(&"freeze", true)
	audio_engine.stop()
	Globals.game_over.emit()


func _on_head_collided(globalpos: Vector2) -> void:
	if has_meta(&"bang"):
		return
	set_meta(&"bang", true)
	var bang = PARTICLES_BANG.instantiate()
	add_child(bang)
	bang.global_position = globalpos


func _on_area_items_area_entered(area: Area2D) -> void:
	if not area.has_meta(&"type"):
		return
	if area.get_meta(&"type") == "nitro":
		Globals.nitro += 1.5
		area.get_parent().queue_free()
	if area.get_meta(&"type") == "coin":
		Globals.score_coins += 50
		area.get_parent().on_grab()
