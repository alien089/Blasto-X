class_name Player
extends KinematicBody2D

signal update_healthbar
signal death

onready var collision_shape : CollisionShape2D = $Pivot/PlayerHitBox/CollisionShape2D
onready var camera: Camera2D = $Camera2D
onready var sprite: Sprite = $Sprite
onready var attack_collision: Area2D = $Pivot/AttackCollision
onready var pivot: Node2D = $Pivot
onready var anim_player: AnimationPlayer = $AnimationPlayer
onready var bullet = preload("res://scenes/pg/Bullet.tscn")
onready var position2d: Position2D = $Pivot/Position2D
onready var go = get_parent().get_node("GUI/UI2/Go")
onready var state_label = $StateLabel
onready var invincibility_timer = $InvincibilityTimer
onready var invincible = false
onready var timerShake: Timer = $TimerShake

export var debug_mode : bool

enum STATE {IDLE, MOVE, ATTACK, HIT, SHOOT, SHAKE, WIN, DIED}

export(int) var speed: int = 300
export(bool) var moving: bool = false
export(bool) var boss: bool = false
export(Vector2) var direction: = Vector2.ZERO
export(Vector2) var orientation: = Vector2.RIGHT
export var randomShackeStrenght: float = 30.0
export var shakeDecayRate: float = 5.0

var current_state = STATE.IDLE
var sceneManager = null
var paused = false
var timer = Timer.new()
var shakeStrenght: float = 0.0
var defaultOffset

export var collidings_areas = []

func _ready() -> void:
	anim_player.play("idle")
	sceneManager = get_parent().get_node("StageManager")
	defaultOffset = camera.offset
	timer.connect("timeout",self,"do_this")
	timer.wait_time = 1
	timer.one_shot = true
	add_child(timer)
	timer.start()
	

func do_this():
	if boss == false:
		camera.smoothing_speed = 5
		timer.disconnect("timeout", self, "do_this")
	else:
		camera.smoothing_speed = 0
		timer.disconnect("timeout", self, "do_this")
	

func _process(delta: float) -> void:
	if(!paused):
		direction = _get_direction()
		if direction.x:
			orientation.x = direction.x
		
		match current_state:
			STATE.IDLE:
				if Input.is_action_just_pressed("attack"):
					current_state = STATE.ATTACK
					
				if Input.is_action_just_pressed("shoot"):
					current_state = STATE.SHOOT
					
				if direction:
					current_state = STATE.MOVE
					
				else:
					anim_player.play("idle")
					
				
			STATE.ATTACK:
				anim_player.play("attack")
			STATE.HIT:
				anim_player.play("hit")
			STATE.SHOOT:
				anim_player.play("shoot")
			STATE.MOVE:
				if direction.x < 0:
					sprite.flip_h = true
					if pivot.scale.x > 0:
						pivot.scale.x = - pivot.scale.x
					
				elif direction.x > 0:
					sprite.flip_h = false
					if pivot.scale.x < 0:
						pivot.scale.x = - pivot.scale.x
					
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
	for area in collidings_areas:
		if area.owner.is_in_group("enemy"):
			var enemy = area.owner
			enemy.hit(1)
			
		
	

func nothing():
	pass

func shoot():
	var bullet_instance = bullet.instance()
	bullet_instance.direction = orientation
	owner.add_child(bullet_instance)
	bullet_instance.global_transform = position2d.global_transform
	

func pause():
	anim_player.stop()
	set_process(false)
	

func death():
	emit_signal("death")
	

func _get_direction() -> Vector2:
	var input_direction = Vector2()
	input_direction.x = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	input_direction.y = int(Input.is_action_pressed("move_down")) - int(Input.is_action_pressed("move_up"))
	return input_direction
	

func hit(dps):
	if invincible == false:
		if !boss:
			if sceneManager.points > 0:
				sceneManager.points -= 20
			sceneManager.hit += 1
		if current_state != STATE.HIT:
			var amount = 0
			current_state = STATE.HIT
			emit_signal("update_healthbar", dps)
		
	

func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if anim_name == "attack":
		current_state = STATE.IDLE
	
	if anim_name == "shoot":
		current_state = STATE.IDLE
	
	if anim_name == "hit":
		current_state = STATE.IDLE
	

func _on_AttackCollision_area_entered(area: Area2D) -> void:
	collidings_areas.append(area)
	

func _on_AttackCollision_area_exited(area: Area2D) -> void:
	collidings_areas.erase(area)
	

func audioStop():
	var audio = get_node("GunSFX")
	audio.stop()
	

func audioPlay():
	var audio = get_node("GunSFX")
	audio.play()
	

func _on_AreaGo_area_entered(area: Area2D) -> void:
	if area.name == "PlayerHitBox":
		if (get_parent().get_node("StageManager/EnemiesContainer").get_child_count() == 0 
		&& sceneManager.ActualFightPhase == sceneManager.totalFightPhases - 1):
			sceneManager.current_stage = sceneManager.current_stage + 1
			sceneManager._select_stage(sceneManager.current_stage)
			sceneManager.spawned = false
			sceneManager.ActualFightPhase = 0
			go.visible = false
			
		
	

func _on_HealthBar_value_changed(value: float) -> void:
	if value == 0:
		current_state = STATE.DIED
	

func _on_InvincibilityTimer_timeout() -> void:
	invincible = false
	

func _on_AnimationPlayer_animation_started(anim_name: String) -> void:
	if anim_name == "hit":
		invincibility_timer.start(1)
		invincible = true
	

