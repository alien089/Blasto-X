class_name Player
extends KinematicBody2D

signal update_healthbar
signal death

onready var collision_shape : CollisionShape2D = $Pivot/PlayerHitBox/CollisionShape2D
onready var sprite: Sprite = $Sprite
onready var attack_collision: Area2D = $Pivot/AttackCollision
onready var pivot: Node2D = $Pivot

onready var cooldownAttack1_timer: Timer = $CooldownAttack1Timer
onready var cooldownAttack2_timer: Timer = $CooldownAttack2Timer

onready var anim_player: AnimationPlayer = $AnimationPlayer
onready var bullet = preload("res://scenes/pg/Bullet.tscn")
onready var position2d: Position2D = $Pivot/Position2D
onready var spritePivot: Position2D = $SpritePivot
onready var go = get_parent().get_node("GUI/UI/Go")
onready var state_label = $StateLabel
onready var invincibility_timer = $InvincibilityTimer
onready var invincible = false
onready var timerShake: Timer = $TimerShake
onready var phisicBody: CollisionShape2D = $CollisionShape2D

#test
export var debug_mode : bool

enum STATE {IDLE, MOVE, KNOCKBACK, ATTACK1, ATTACK2, HIT, SHOOT, SHAKE, WIN, DIED}

export(bool) var isPlayerTwo: bool = false
export(int) var speed: int = 300
export(int) var damage: int = 1
export(int) var HP: int = 20
export(bool) var moving: bool = false
export(bool) var boss: bool = false
export(Vector2) var direction: = Vector2.ZERO
export(Vector2) var orientation: = Vector2.RIGHT

export(float) var rebonuce_distance := 500.0
export(float) var rebounce_speed := 700.0

export var attack1Cooldown: float = 1.0
export var attack2Cooldown: float = 1.0

var current_state = STATE.IDLE
var sceneManager = null
var paused = false

var canAttack1 = true
var canAttack2 = true

var inputManager
var lifesList
var lifeCount: int

var actualAttackType: int

func _ready() -> void:
	anim_player.play("idle")
	sceneManager = get_parent().get_parent().get_node("StageManager")

	if !isPlayerTwo:
		lifesList = get_parent().get_parent().get_node("GUI/UI/LifesList/Blasto")
	else:
		lifesList = get_parent().get_parent().get_node("GUI/UI/LifesList/Ceru")
	
	lifeCount = lifesList.get_child_count()

	cooldownAttack1_timer.wait_time = attack1Cooldown
	cooldownAttack1_timer.one_shot = true
	cooldownAttack1_timer.start()

	cooldownAttack2_timer.wait_time = attack2Cooldown
	cooldownAttack2_timer.one_shot = true
	cooldownAttack2_timer.start()
	
	if (!boss):
		linkSignals()

func linkSignals():
	sceneManager.AreaGo.connect("area_entered", self, "_on_AreaGo_area_entered")

func _process(_delta: float) -> void:
	if(isPlayerTwo):
		inputManager = Global.player2_input
	else:
		inputManager = Global.player1_input
	
	if(!paused):
		if current_state != STATE.KNOCKBACK:
			direction = _get_direction()
			if direction.x:
				orientation.x = direction.x
		
		match current_state:
			STATE.IDLE:
				phisicBody.disabled = false
				if Input.is_action_just_pressed(inputManager[4]) && canAttack1 == true:
					current_state = STATE.ATTACK1
					actualAttackType = 1
					canAttack1 = false
				if Input.is_action_just_pressed(inputManager[5]) && canAttack2 == true:
					current_state = STATE.ATTACK2
					actualAttackType = 2
					canAttack2 = false
					
				if Input.is_action_just_pressed(inputManager[6]):
					current_state = STATE.SHOOT
					
				if direction:
					current_state = STATE.MOVE
					
				else:
					anim_player.play("idle")
					
				
			STATE.ATTACK1:
				anim_player.play("attack1")
			STATE.ATTACK2:
				anim_player.play("attack2")
			STATE.HIT:
				anim_player.play("hit")
			STATE.KNOCKBACK:
				anim_player.play("hit")

				phisicBody.disabled = true

				var pos = Vector2()
				pos.y = global_position.y
				
				if direction.x < 0:
					pos.x = global_position.x + rebonuce_distance
				else:
					pos.x = global_position.x - rebonuce_distance
			
				move_rebounce(pos, rebounce_speed)

				if global_position == pos:
					current_state = STATE.IDLE
			STATE.SHOOT:
				anim_player.play("shoot")
			STATE.MOVE:
				if direction.x < 0:
					if pivot.scale.x > 0:
						pivot.scale.x = - pivot.scale.x	
						spritePivot.scale.x = -spritePivot.scale.x	
				if direction.x > 0:
					if pivot.scale.x < 0:
						pivot.scale.x = - pivot.scale.x
						spritePivot.scale.x = -spritePivot.scale.x	

					
				move_and_slide(direction * speed)
				anim_player.play("move")
				
				if !direction:
					current_state = STATE.IDLE
					
				
			STATE.DIED:
				collision_shape.disabled = true
				anim_player.play("died")
			
		
		if debug_mode:
			state_label.text = str(global_position.x)
			
		
	else:
		anim_player.stop()
	

func attack():
	for area in attack_collision.get_overlapping_areas():
		if area.owner.is_in_group("enemy"):
			var enemy = area.owner
			enemy.hit(damage, "melee", actualAttackType)
		
	

func shoot():
	var bullet_instance = bullet.instance()
	if spritePivot.scale.x < 0 == true:
		bullet_instance.direction = Vector2(-1,0)
	else:
		bullet_instance.direction = Vector2(1,0)
	owner.add_child(bullet_instance)
	bullet_instance.global_transform = position2d.global_transform
	

func pause():
	anim_player.stop()
	set_process(false)
	

func knockback():
	current_state = STATE.KNOCKBACK


func move_rebounce(target: Vector2, rebounceSpeed):
	if target:
		if global_position.y > target.y:
			z_index = 0
		else:
			z_index = -1
			
		var velocity = global_position.direction_to(target)
				
		move_and_slide(velocity * rebounceSpeed)

func _get_direction() -> Vector2:
	var input_direction = Vector2()
	input_direction.x = int(Input.is_action_pressed(inputManager[3])) - int(Input.is_action_pressed(inputManager[2]))
	input_direction.y = int(Input.is_action_pressed(inputManager[1])) - int(Input.is_action_pressed(inputManager[0]))
	return input_direction
	

func hit(dps, type, source):
	if current_state != STATE.DIED:
		if invincible == false:
			if !boss:
				if sceneManager.points > 0:
					sceneManager.points -= 20
				sceneManager.hit += 1
			if current_state != STATE.HIT || current_state != STATE.DIED:
				current_state = STATE.HIT
				emit_signal("update_healthbar", dps)
		
	

func death():
	if lifeCount > 1:
		respawn()
	else:
		KO()
		
	emit_signal("death", self)
	collision_shape.disabled = false
	

func removeLife():
	lifeCount = lifeCount - 1
	for life in lifesList.get_children():
		if life.visible == true:
			life.visible = false
			break
			
		
	

func respawn():
	removeLife()
	current_state = STATE.IDLE
	emit_signal("update_healthbar", -HP)

func KO():
	removeLife()
	queue_free()

func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if current_state != STATE.DIED:
		if anim_name == "attack1":
			current_state = STATE.IDLE

		if anim_name == "attack2":
			current_state = STATE.IDLE
		
		if anim_name == "shoot":
			current_state = STATE.IDLE
		
		if anim_name == "hit":
			current_state = STATE.IDLE
		
	

func audioStop():
	var audio = get_node("GunSFX")
	audio.stop()
	

func audioPlay():
	var audio = get_node("GunSFX")
	audio.play()
	

func _on_AreaGo_area_entered(area: Area2D) -> void:
	if area.name == "PlayerHitBox":
		if (get_parent().get_parent().get_node("StageManager/EnemiesContainer").get_child_count() == 0 
		&& sceneManager.ActualFightPhase == sceneManager.totalFightPhases - 1):
			sceneManager.current_stage = sceneManager.current_stage + 1
			sceneManager._select_stage(sceneManager.current_stage)
			sceneManager.spawned = false
			sceneManager.ActualFightPhase = 0
			sceneManager.go.visible = false
			
		
	

func _on_HealthBar_value_changed(value: float) -> void:
	if value <= 0:
		current_state = STATE.DIED
	

func _on_InvincibilityTimer_timeout() -> void:
	invincible = false
	

func _on_AnimationPlayer_animation_started(anim_name: String) -> void:
	if anim_name == "hit":
		invincibility_timer.start(1)
		invincible = true


func _on_CooldownAttack1Timer_timeout():
	canAttack1 = true;
	cooldownAttack1_timer.wait_time = attack1Cooldown
	cooldownAttack1_timer.one_shot = true
	cooldownAttack1_timer.start()



func _on_CooldownAttack2Timer_timeout():
	canAttack2 = true;
	cooldownAttack2_timer.wait_time = attack2Cooldown
	cooldownAttack2_timer.one_shot = true
	cooldownAttack2_timer.start()
