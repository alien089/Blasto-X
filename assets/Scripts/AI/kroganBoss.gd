class_name KroganBoss
extends KinematicBody2D

onready var sprite: Sprite = $Sprite
onready var pivot: Node2D = $Pivot
onready var attack_delay_timer: Timer = $AttackDelayTimer
onready var cooldownShake_timer: Timer = $CooldownShakeTimer
onready var timerShake: Timer = $TimerShake
onready var cooldownCharge_timer: Timer = $CooldownChargeTimer
onready var timerCharge: Timer = $TimerCharge
onready var anim_player : AnimationPlayer = $AnimationPlayer
onready var collision_shape : CollisionShape2D = $HitBox/CollisionShape2D
onready var collision_shape_body : CollisionShape2D = $CollisionShape2D
onready var collition_area2d : CollisionShape2D = $Pivot/AttackCollision/CollisionShape2D
onready var UIHealthBar: Node2D = get_parent().get_parent().get_parent().get_node("GUI/UI/HealthBossContainer")
onready var camera: Camera2D = get_parent().get_parent().get_parent().get_node("Camera2D")
enum STATE {CHASE, ATTACK, SHAKE, CHARGE_START, CHARGE_MID, CHARGE_END, WAIT, IDLE, HIT, DIED}

export(int) var death_speed := 150
export(int) var moving_speed := 50
export(int) var charge_speed := 100
export(int) var dps := 10
export(int) var dpsCharge := 20
export(int) var HP := 5
export(float) var ShakeDuration := 5.0
export(float) var ShakeDeelay := 5.0
export(float) var ChargeDeelay := 5.0

var current_state = STATE.CHASE
var actual_target: Player = null
var directionPlayer = Vector2()
var near_player: bool = false
var near_enemy: bool = false
var healthBar = null
var amount = 0
var paused = false
var areaCollided = null
var targetList = null

var shakeFree: bool = false
var chargeFree: bool = false

var sceneManager = null

func _ready():
	anim_player.play("idle")
	healthBar = UIHealthBar
	
	sceneManager = get_parent().get_parent()
	cooldownShake_timer.wait_time = ShakeDeelay
	cooldownShake_timer.one_shot = true
	cooldownShake_timer.start()
	cooldownCharge_timer.wait_time = ChargeDeelay
	cooldownCharge_timer.one_shot = true
	cooldownCharge_timer.start()
	

func _process(_delta: float) -> void:
	actual_target = select_target()
	
	if chargeFree && (current_state != STATE.SHAKE &&
		current_state != STATE.DIED):
		current_state = STATE.CHARGE_START
	elif shakeFree && (
		current_state != STATE.CHARGE_START && 
		current_state != STATE.CHARGE_MID && 
		current_state != STATE.CHARGE_END &&
		current_state != STATE.DIED):
		current_state = STATE.SHAKE
	
	if(!paused):
		match current_state:
			STATE.HIT:
				anim_player.play("hit")
			STATE.CHASE:
				anim_player.play("move")
				if !near_player:
					move_towards(actual_target.global_position, moving_speed)
				else:
					current_state = STATE.WAIT
			STATE.WAIT:
				if near_player:
					anim_player.play("idle")
					if attack_delay_timer.is_stopped():
						attack_delay_timer.wait_time = 1
						attack_delay_timer.start()
				else:
					current_state = STATE.CHASE
			STATE.IDLE:
				anim_player.play("idle")
				if !near_enemy:
					current_state = STATE.WAIT
			STATE.ATTACK:
					if near_player && !actual_target.invincible:
						anim_player.play("attack")
					elif anim_player.current_animation != "attack":
						current_state = STATE.WAIT
						attack_delay_timer.stop()
			STATE.SHAKE:
				#timerCharge.set_paused(true)
				if timerShake.is_stopped() && shakeFree:
					anim_player.play("shake")
				if anim_player.current_animation != "shake":
					current_state = STATE.IDLE
					#timerCharge.set_paused(false)
			STATE.CHARGE_START:
				#timerShake.set_paused(true)
				if timerCharge.is_stopped() && chargeFree:
					anim_player.play("ChargeStart")
			STATE.CHARGE_MID:
				if anim_player.current_animation != "ChargeMid":
					anim_player.play("ChargeMid")
				
				if directionPlayer.x < 0:
					sprite.flip_h = true
					if pivot.scale.x > 0:
						pivot.scale.x = - pivot.scale.x
					
				elif directionPlayer.x > 0:
					sprite.flip_h = false
					if pivot.scale.x < 0:
						pivot.scale.x = - pivot.scale.x
						
				move_and_slide(directionPlayer * charge_speed)
			STATE.CHARGE_END:
				if (areaCollided != null):
					if (areaCollided.owner.is_in_group("player")):
						actual_target.hit(dpsCharge, "melee", self)
				if anim_player.current_animation != "ChargeEnd":
					#timerShake.set_paused(false)
					areaCollided = null
					cooldownCharge_timer.wait_time = ChargeDeelay
					cooldownCharge_timer.one_shot = true
					cooldownCharge_timer.start()
					current_state = STATE.WAIT
			STATE.DIED:
				collision_shape_body.disabled = true
				collision_shape.disabled = true
				
				collition_area2d.disabled = true
				
				anim_player.play("died")
				
				var directionDead = Vector2((global_position.x - actual_target.global_position.x), 0).normalized()
				
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
	if (current_state != STATE.CHARGE_START && current_state != STATE.CHARGE_MID && current_state != STATE.CHARGE_END):
		healthBar.update_healthbar(dpsTaken)
		amount = amount + dpsTaken
		if amount >= HP:
			current_state = STATE.DIED
		else:
			current_state = STATE.HIT
		

func shake(): 
	shakeFree = false
	timerShake.wait_time = ShakeDuration
	timerShake.one_shot = true
	camera.smoothing_speed = 5
	camera.get_child(0).shaked = true
	for target in targetList:
		target.paused = true
	timerShake.start()
	cooldownShake_timer.wait_time = ShakeDeelay
	cooldownShake_timer.one_shot = true
	cooldownShake_timer.start()

func set_state_idle():
	camera.smoothing_speed = 0
	camera.get_child(0).shaked = false
	for target in targetList:
		target.paused = false
	

func ChargeStart():
	chargeFree = false
	current_state = STATE.CHARGE_MID
	var targetPositionStamp = Vector2()
	targetPositionStamp.x = actual_target.global_position.x
	targetPositionStamp.y = actual_target.global_position.y
	directionPlayer = Vector2((targetPositionStamp.x - global_position.x), (targetPositionStamp.y - global_position.y)).normalized()
	

func ChargeEnd():
	pass

func move_towards(target: Vector2, speed):
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
				
		move_and_slide(velocity * speed)
	

func attack():
	actual_target.hit(dps, "melee", self)
	

func death():
	queue_free()
	

func pause():
	anim_player.stop()
	set_process(false)
	

func _on_Area2D_area_entered(area: Area2D) -> void:
	if current_state == STATE.CHARGE_MID:
		if area.name != "BulletArea":
			anim_player.play("ChargeEnd")
			current_state = STATE.CHARGE_END
			if (area.owner.is_in_group("player")):
				areaCollided = area
	else:
		if (area.owner.is_in_group("player")):
			near_player = true
		
		if(area.owner.is_in_group("enemy")):
			current_state = STATE.IDLE
			near_enemy = true
			
		
	

func _on_Area2D_area_exited(area: Area2D) -> void:
	if current_state == STATE.DIED:
		pass
	elif area.owner && area.owner.is_in_group("player"):
		near_player = false
		#current_state = STATE.CHASE
		#attack_delay_timer.stop()
	if area.owner && area.owner.is_in_group("enemy"):
		near_enemy = false
		
	

func _on_Timer_timeout() -> void:
	if current_state == STATE.WAIT:
		current_state = STATE.ATTACK
	

func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if anim_name == "attack":
		current_state = STATE.CHASE
	if anim_name == "hit":
		current_state = STATE.CHASE
		
	

func _on_TimerShake_timeout():
	set_state_idle()

func _on_TimerCharge_timeout():
	pass

func _on_CooldownShakeTimer_timeout():
	shakeFree = true

func _on_CooldownChargeTimer_timeout():
	chargeFree = true
