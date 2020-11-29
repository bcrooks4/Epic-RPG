extends KinematicBody

var speed := 6.0
var normal_speed := 6.0
var crouch_move_speed := 3
var run_speed := 12.0
var crouch_speed := 8.0
var h_acceleration := 25.0
var air_acceleration := 0.75
var normal_acceleration := 8.0
var gravity := 20
var jump := 8
var full_contact := false
var default_height := 2.0
var crouch_height := 0.75

var camera_sensitivity := 0.2

const SWAY := 15
var sway_offset := Vector3()

var direction := Vector3()
var h_velocity := Vector3()
var movement := Vector3()
var gravity_vec := Vector3()
var move_direction := Vector3()

var swing_process := 0.0
var swing_speed := 50.0
var swing_start := Vector3()
var swing_finish := Vector3()

var attacking := false

onready var camera : Camera = $Camera
onready var ground_check : RayCast = $ground_check
onready var head_check : RayCast = $head_hit
onready var player_capsule : CollisionShape = $CollisionShape
onready var hand : Spatial = $Camera/Hand
onready var animation_player : AnimationPlayer = $AnimationPlayer

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	sway_offset = Vector3.ZERO


func _input(event):
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x * camera_sensitivity
		camera.rotation_degrees.x -= event.relative.y * camera_sensitivity
		camera.rotation.x = clamp(camera.rotation.x, deg2rad(-70), deg2rad(70))

func _process(delta):
	sway_offset.x = lerp_angle(sway_offset.x, (move_direction.normalized() * 0.25).z, SWAY * delta)
	sway_offset.z = lerp_angle(sway_offset.z, (-move_direction.normalized() * 0.25).x, SWAY * delta)
	
	hand.rotation += sway_offset
	
	if Input.is_action_pressed("attack") and not attacking:
		attacking = true
		animation_player.play("swing_0")
		yield(animation_player, "animation_finished")
		animation_player.play("idle-loop")
		yield(get_tree().create_timer(0.25), "timeout")
		attacking = false



#func _process(delta):
#	if attacking:
#		swing_process += swing_speed * delta
#		if swing_process >= 1.0:
#			attacking = false
#			swing_process = 0.0
#		hand.global_transform.origin = lerp(swing_start, hand_location.global_transform.origin - hand_location.global_transform.basis.x * 5.0, swing_process)
#	else:
#		sway_offset.x = -h_velocity.normalized().z * 0.15
#		sway_offset.z = -h_velocity.normalized().x * 0.15
#		hand.global_transform.origin = hand_location.global_transform.origin
#		hand.rotation.y = lerp_angle(hand.rotation.y, rotation.y - sway_offset.z, SWAY * delta)
#		hand.rotation.x = lerp_angle(hand.rotation.x, -camera.rotation.x - sway_offset.x, SWAY * delta)
#
#		if Input.is_action_just_pressed("attack"):
#			attacking = true
#			swing_start = hand_location.global_transform.origin
#			swing_finish = hand_location.global_transform.origin - hand_location.global_transform.basis.x * 5.0

func _physics_process(delta):
	var head_hit = false
	
	move_direction = Vector3.ZERO
	direction = Vector3()
	
	full_contact = ground_check.is_colliding()
	
	if not is_on_floor():
		gravity_vec += Vector3.DOWN * gravity * delta
		h_acceleration = air_acceleration
	elif is_on_floor() and full_contact:
		gravity_vec = -get_floor_normal() * gravity
		h_acceleration = normal_acceleration
	else:
		gravity_vec = -get_floor_normal()
		h_acceleration = normal_acceleration
	
	if head_check.is_colliding():
		head_hit = true
	
	if Input.is_action_just_pressed("jump") and (is_on_floor() or ground_check.is_colliding()):
		gravity_vec = Vector3.UP * jump
	
	if head_hit:
		gravity_vec.y = -2.0
	
	if Input.is_action_pressed("crouch"):
		player_capsule.shape.height -= crouch_speed * delta
	elif not head_hit:
		player_capsule.shape.height += crouch_speed * delta
	player_capsule.shape.height = clamp(player_capsule.shape.height, crouch_height, default_height)
	
	
	if Input.is_action_pressed("run") and not Input.is_action_pressed("crouch") and (is_on_floor() or ground_check.is_colliding()):
		speed = run_speed
	elif Input.is_action_pressed("crouch") and (is_on_floor() or ground_check.is_colliding()):
		speed = crouch_move_speed
	else:
		speed = normal_speed
	
	if Input.is_action_pressed("move_forward"):
		direction += transform.basis.z 
		move_direction += Vector3.FORWARD
	if Input.is_action_pressed("move_backward"):
		direction -= transform.basis.z 
		move_direction += Vector3.BACK
	if Input.is_action_pressed("move_left"):
		direction += transform.basis.x
		move_direction += Vector3.LEFT
	if Input.is_action_pressed("move_right"):
		direction -= transform.basis.x 
		move_direction += Vector3.RIGHT
	
	
	
	direction = direction.normalized()
	h_velocity = h_velocity.linear_interpolate(direction * speed, h_acceleration * delta)
	movement.z = h_velocity.z + gravity_vec.z
	movement.x = h_velocity.x + gravity_vec.x
	movement.y = gravity_vec.y
	
	var on_ground_before := is_on_floor()
	move_and_slide(movement, Vector3.UP)
