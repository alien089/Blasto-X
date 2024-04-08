class_name Enemy
extends KinematicBody2D

onready var sprite: Sprite = $Sprite
onready var pivot: Node2D = $Pivot
onready var attack_delay_timer: Timer = $AttackDelayTimer
onready var cooldown_timer: Timer = $CooldownTimer
onready var anim_player : AnimationPlayer = $AnimationPlayer
onready var collision_shape : CollisionShape2D = $Pivot/HitBox/CollisionShape2D
onready var collision_shape_body : CollisionShape2D = $CollisionShape2D
onready var collition_area2d : CollisionShape2D = $Pivot/AttackCollision/CollisionShape2D
onready var attack_area2d : Area2D = $Pivot/AttackCollision
onready var audio: AudioStreamPlayer = $PunchSFX

enum STATE {CHASE, ATTACK, WAIT, IDLE, HIT, DIED}

export(int) var death_speed := 150
export(int) var moving_speed := 50
export(int) var dps := 10
export(int) var HP := 5
export(float) var rebonuceDistance := 5.0
export(float) var rebounce_speed := 5.0
export(bool) var group = false

var current_state = STATE.CHASE

var actual_target: Player = null
var near_player: bool = false
var near_enemy: bool = false
var healthBar = null
var amount = 0
var paused = false

var sceneManager = null

var actualAttackTypeReceived: int

func _ready():
	anim_player.play("idle")
	healthBar = get_node("HealthDisplay")
	
	if !group:
		sceneManager = get_parent().get_parent()
	else:
		sceneManager = get_parent().get_parent().get_parent()
	

func _process(_delta: float) -> void:
	actual_target = select_target()
	
	match current_state:
		STATE.HIT:
			anim_player.play("hit")
			
			if actualAttackTypeReceived == 2:
				var pos = Vector2()
				pos.y = global_position.y
				
				if global_position.x > actual_target.global_position.x:
					pos.x = global_position.x + rebonuceDistance
				else:
					pos.x = global_position.x - rebonuceDistance
			
				print("layers active: ",  collision_layer)
				print("masks active: ",  collision_mask)
				move_rebounce(pos, rebounce_speed)
				
		STATE.CHASE:
			anim_player.play("move")
			if !near_player && is_instance_valid(actual_target):
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
		STATE.DIED:
			collision_shape_body.disabled = true
			collision_shape.disabled = true
			
			collition_area2d.disabled = true
			
			anim_player.play("died")
			
			var direction = Vector2((global_position.x - actual_target.global_position.x), 0).normalized()
			
			move_and_slide(direction * death_speed)
			
			
		
	$HealthDisplay/Label.text = STATE.keys()[current_state]


func select_target() -> Player:
	if !group:
		var distance: float = 100000
		var choosedTarget: Player = null
		for target in sceneManager.playersParent.get_children():
			var tmpDistance: float = global_position.distance_to(target.global_position)
			if(tmpDistance < distance):
				choosedTarget = target 
				distance = tmpDistance

		return choosedTarget
	else:
		var distance: float = 100000
		var choosedTarget: Player = null
		var t = sceneManager.playersParent.get_children()
		for target in sceneManager.playersParent.get_children():
			var tmpDistance: float = global_position.distance_to(target.global_position)
			if(tmpDistance < distance):
				choosedTarget = target 
				distance = tmpDistance

		return choosedTarget



func hit(dpsTaken, attackType, source) -> void:
	healthBar.update_healthbar(dpsTaken)
	amount = amount + dpsTaken
	if amount >= HP:
		current_state = STATE.DIED
	else:
		current_state = STATE.HIT
		if attackType == "melee":
			actualAttackTypeReceived = source
		switchLayers(true)
		
	
func switchLayers(hitting):
	if hitting:
		set_collision_layer_bit(3, true)
		set_collision_layer_bit(2, false)
		set_collision_mask_bit(2, false)
		set_collision_mask_bit(0, false)
	else:
		set_collision_layer_bit(3, false)
		set_collision_layer_bit(2, true)
		set_collision_mask_bit(2, true)
		set_collision_mask_bit(0, true)

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

func move_rebounce(target: Vector2, speed):
	if target:
		if global_position.y > target.y:
			z_index = 0
		else:
			z_index = -1
			
		var velocity = global_position.direction_to(target)
				
		move_and_slide(velocity * speed)

func pause():
	anim_player.stop()
	set_process(false)
	

func attack():
	if near_player:
		for area in attack_area2d.get_overlapping_areas():
			if area.owner.is_in_group("player"):
				actual_target.hit(dps, "melee", self)
			
	

func death():
	sceneManager.points = sceneManager.points + 100
	sceneManager.kill = sceneManager.kill + 1
	
	queue_free()
	

func _on_Area2D_area_entered(area: Area2D) -> void:
	if (area.owner.is_in_group("player")):
		near_player = true
	
	if(area.owner.is_in_group("enemy")):
		var otherSprite: Sprite = area.owner.get_node("Sprite")
		if(sprite.flip_h == otherSprite.flip_h):
			current_state = STATE.IDLE
			near_enemy = true
		
	

func _on_Area2D_area_exited(area: Area2D) -> void:
	if current_state == STATE.DIED:
		pass
	elif area.owner && area.owner.is_in_group("player"):
		near_player = false
	if area.owner && area.owner.is_in_group("enemy"):
		near_enemy = false
	

func _on_Timer_timeout() -> void:
	if current_state == STATE.WAIT:
		current_state = STATE.ATTACK
	

func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if anim_name == "attack":
		current_state = STATE.CHASE
	if anim_name == "hit":
		switchLayers(false)
		current_state = STATE.CHASE
		
	
