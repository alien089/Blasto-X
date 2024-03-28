class_name asariBoss
extends KinematicBody2D

signal attackDone
signal didSprintAttack
signal hasDied
signal chooseLanding
signal chooseMove

onready var sprite: Sprite = $Sprite
onready var pivot: Node2D = $Pivot
onready var idle_wait_timer: Timer = $IdleWait
onready var anim_player : AnimationPlayer = $AnimationPlayer
onready var collision_shape : CollisionShape2D = $Pivot/HitBox/CollisionShape2D
onready var collision_shape_body : CollisionShape2D = $CollisionShape2D
onready var collition_area2d : CollisionShape2D = $Pivot/AttackCollision/CollisionShape2D
onready var jump_position2D : Position2D = $JumpPosition

enum STATE {ATTACK, JUMP, FLOATING, LANDING, SPRINT, IDLE, HIT, DIED}

export(int) var death_speed := 150
export(int) var sprint_speed := 250
export(float) var jump_speed := 500.0
export(float) var fall_speed := 500.0
export(int) var dpsSprint := 15
export(int) var dpsLanding := 20
export(int) var HP := 5
export var HealthBarName = ""
export var wait_time_attack := 2


var current_state = STATE.IDLE
var actual_target: Player = null
var directionPlayer = Vector2()
var near_player: bool = false
var healthBar = null
var amount = 0
var paused = false
var areaCollided = null
var targetList = null
var actual_dps = dpsSprint
var has_sprinted : bool = false
var direction : Vector2 
var movement

var targetPos: Vector2
var oneTime = false
var jumpPos: Vector2
var isAlone = false

var rng

var UIHealthBar: Node2D 
var didLandingAtk: bool = false
var canLand: bool = false

var sceneManager = null

var gp: Vector2

func _ready():
	rng = RandomNumberGenerator.new()
	UIHealthBar = get_parent().get_parent().get_parent().get_node(HealthBarName)
	anim_player.play("idle")
	healthBar = UIHealthBar
	
	sceneManager = get_parent().get_parent()
	jumpPos = jump_position2D.global_position

func _process(_delta: float) -> void:
	gp = global_position
	actual_target = select_target()
	
	if(!paused):

		match current_state:
			STATE.IDLE:
				if anim_player.current_animation != "idle":
					anim_player.play("idle")

			STATE.HIT:
				anim_player.play("hit")

			STATE.ATTACK:
				if near_player && !actual_target.invincible:
					anim_player.play("attack")
					
				if anim_player.current_animation != "attack":
					if !isAlone:
						emit_signal("attackDone")
						emit_signal("didSprintAttack")
						current_state = STATE.IDLE
					if isAlone:
						current_state = STATE.JUMP

			STATE.JUMP:
				if oneTime == false:
					attack_setup(0, "Jump")
					has_sprinted = true
					targetPos = Vector2(global_position.x, jumpPos.y)
					collision_shape_body.disabled = true
					oneTime = true
				if sprite.frame == 8:
					move_towards(targetPos, jump_speed)

				if global_position <= targetPos:
					if isAlone:
						oneTime = false
						current_state = STATE.LANDING
					if !isAlone:
						oneTime = false
						current_state = STATE.FLOATING

			STATE.FLOATING:
				if canLand:
					canLand = false
					current_state = STATE.LANDING

			STATE.LANDING:
				if oneTime == false:
					attack_setup(dpsLanding, "Falling")
					targetPos = actual_target.global_position
					global_position = Vector2(actual_target.global_position.x, global_position.y)
					
					oneTime = true
				move_towards(targetPos, fall_speed)

			STATE.SPRINT:
				if oneTime == false:
					directionPlayer = actual_target.global_position
					
					direction = Vector2(directionPlayer - global_position).normalized()
					attack_setup(dpsSprint, "Sprint")
					movement = direction * sprint_speed * _delta
					flip_sprite(directionPlayer)
					oneTime = true
				
				global_position += movement
				
				if global_position >= directionPlayer && direction > Vector2(0, 0) || global_position <= directionPlayer && direction < Vector2(0, 0):
					if isAlone:
						current_state = STATE.JUMP
					if !isAlone:
						emit_signal("attackDone")
						emit_signal("didSprintAttack")
						oneTime = false
						current_state = STATE.IDLE
			
			STATE.DIED:
				collision_shape_body.disabled = true
				collision_shape.disabled = true
				
				collition_area2d.disabled = true
				
				emit_signal("hasDied")
				anim_player.play("died")
				
				var directionDead = Vector2((global_position.x - actual_target.position.x), 0).normalized()
				
				move_and_slide(directionDead * death_speed)
				
		
		$HealthDisplay/Label.text = STATE.keys()[current_state]
	else:
		anim_player.stop()


func select_target() -> Player:
	var distance: float = 100000
	var choosedTarget: Player = null
	for target in targetList:
		var tmpDistance: float = global_position.distance_to(target.global_position)
		if(tmpDistance < distance):
			choosedTarget = target 
			distance = tmpDistance
	
	return choosedTarget


func hit(dpsTaken, attackType, source) -> void:
	if (current_state != STATE.JUMP && current_state != STATE.SPRINT):
		healthBar.update_healthbar(dpsTaken)
		amount = amount + dpsTaken
		if amount >= HP:
			current_state = STATE.DIED
		else:
			current_state = STATE.HIT


func move_towards(target: Vector2, speed):
	if target:
		flip_sprite(target)
				
		var velocity = global_position.direction_to(target)
		move_and_slide(velocity * speed)


func move_sprint(_movement):
	global_position += _movement


func flip_sprite(target: Vector2):
	if target:
		if global_position.y > target.y:
			z_index = 0
		else:
			z_index = -1
		
		var velocity = global_position.direction_to(target)
		
		if velocity.x < 0:
			sprite.flip_h = true
			if pivot.scale.x > 0:
				pivot.scale.x = - pivot.scale.x
		elif velocity.x > 0:
			sprite.flip_h = false
			if pivot.scale.x < 0:
				pivot.scale.x = - pivot.scale.x


func attack():
	actual_target.hit(actual_dps, self)


func death():
	queue_free()


func pause():
	anim_player.stop()
	set_process(false)


func choose_array_numb(array):
	return array[randi() % array.size()]


func _on_FallCollision_area_entered(area): #impact area when landing after falling attack
	if area.owner.is_in_group("player"):
		if current_state == STATE.LANDING:
			didLandingAtk = true
			attack()
			set_idle_with_timer()
			

func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if anim_name == "hit":
		oneTime = false
		current_state = STATE.IDLE
	
	if anim_name == "Falling":
		oneTime = false
		collision_shape_body.disabled = false
		if didLandingAtk == false:
			set_idle_with_timer()
			
	if anim_name == "attack":
		oneTime = false

func _on_AttackCollision_area_entered(area):
	if area.owner.is_in_group("player") && current_state == STATE.SPRINT:
		current_state = STATE.ATTACK
		near_player = true

func _on_IdleWait_timeout():
	if isAlone:
		current_state = STATE.SPRINT
	if !isAlone:
		emit_signal("attackDone")

func attack_setup(dpsChanged, animationName):
	actual_dps = dpsChanged
	anim_player.play(animationName)


func set_idle_with_timer():
	current_state = STATE.IDLE
	idle_wait_timer.stop()
	idle_wait_timer.wait_time = wait_time_attack
	idle_wait_timer.start()
