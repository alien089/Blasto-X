class_name SalarianBoss
extends KinematicBody2D

onready var sprite: Sprite = $Sprite
onready var pivot: Node2D = $Pivot
onready var attack_delay_timer: Timer = $AttackDelayTimer
onready var anim_player : AnimationPlayer = $AnimationPlayer
onready var collision_shape : CollisionShape2D = $HitBox/CollisionShape2D
onready var collision_shape_body : CollisionShape2D = $CollisionShape2D
onready var collition_area2d : CollisionShape2D = $Pivot/AttackCollision/CollisionShape2D
onready var UIHealthBar: Node2D = get_parent().get_parent().get_parent().get_node("GUI/UI/HealthBossContainer")
onready var camera: Camera2D = get_parent().get_parent().get_parent().get_node("Camera2D")

onready var spear_list_pos: Array = get_parent().get_parent().get_node("spearZones").get_children()
onready var gun_list_pos: Array = get_parent().get_parent().get_node("gunZones").get_children()
#onready var vine_spear = preload("res://scenes/pg/bosses/Vine Spear.tscn")
#onready var vine_gun = preload("res://scenes/pg/bosses/Vine Gun.tscn")
onready var cooldown: Timer = $Cooldown
enum STATE {KNOCKBACK, SELECTING_VINE, VINE, ATTACK, IDLE, HIT, DIED}

export(int) var death_speed := 150
export(int) var moving_speed := 50

export(float) var delay_after_spear := 3.0
export(float) var delay_after_gun := 3.0

export(int) var dps := 10
export(int) var HP := 5
export(PackedScene) var vine_spear
export(PackedScene) var vine_gun
export(float) var shooot_delay

var current_state = STATE.IDLE
var actual_target: Player = null
var directionPlayer = Vector2()
var near_player: bool = false
var near_enemy: bool = false
var healthBar = null
var amount = 0
var paused = false
var areaCollided = null
var targetList = null

var canAttack = false
var attack_type = 2
var actual_vine = null
var actual_list_pos: Array
var rng
var sceneManager = null
var just_changed = false
var actual_zone
var choosed_pos = -1

func _ready():
	anim_player.play("idle")
	healthBar = UIHealthBar
	rng = RandomNumberGenerator.new()
	sceneManager = get_parent().get_parent()
	

func _process(_delta: float) -> void:
	actual_target = select_target()
	
	if(!paused):
		match current_state:
			STATE.HIT:
				anim_player.play("hit")
			STATE.IDLE:
				anim_player.play("idle")
				if near_player:
					if attack_delay_timer.is_stopped():
						attack_delay_timer.wait_time = 1
						attack_delay_timer.start()
			STATE.ATTACK:
				if near_player && !actual_target.invincible:
					anim_player.play("attack")
				elif anim_player.current_animation != "attack":
					current_state = STATE.IDLE
					attack_delay_timer.stop()
				else:
					current_state = STATE.IDLE
			STATE.KNOCKBACK:
				anim_player.play("knockback")
			STATE.SELECTING_VINE:
				just_changed = true
				if choosed_pos != -1:
					actual_vine = vine_gun
					actual_list_pos = gun_list_pos
					attack_type = 1
					actual_zone = actual_list_pos.size()-1
					current_state = STATE.VINE
				elif attack_type == 1:
					actual_vine = vine_spear
					actual_list_pos = spear_list_pos
					attack_type = 2
					current_state = STATE.VINE
				else:
					actual_vine = vine_gun
					actual_list_pos = gun_list_pos
					attack_type = 1
					current_state = STATE.VINE
			STATE.VINE:
				if just_changed == true:
					if attack_type == 1:
						anim_player.play("gun")
					else:
						anim_player.play("spear")
					#anim_player.play("vine")
					just_changed = false

				elif anim_player.current_animation != "gun" && anim_player.current_animation != "spear":
					if choosed_pos == -1:
						randomize()
						actual_zone = int(rand_range(0, actual_list_pos.size()-1))
						
					var i = 1

					for pos in actual_list_pos[actual_zone].get_children():
						var actual_vine_instance = actual_vine.instance()

						if attack_type == 1:
							var test = shooot_delay * i
							(actual_vine_instance as VineGun).delay = test

						if pos.name == "1" || pos.name == "2":
							actual_vine_instance.z_index = -2
						else:
							actual_vine_instance.z_index = 3
						
						owner.add_child(actual_vine_instance)
						actual_vine_instance.global_transform = pos.global_transform
						i = i + 1

					if attack_type == 1:
						cooldown.wait_time = delay_after_gun
					elif attack_type == 2:
						cooldown.wait_time = delay_after_spear
					cooldown.start()
					choosed_pos = -1
					current_state = STATE.IDLE
			STATE.DIED:
				collision_shape_body.disabled = true
				collision_shape.disabled = true
				
				collition_area2d.disabled = true
				
				anim_player.play("died")
		
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
	if not source is Bullet: 
		healthBar.update_healthbar(dpsTaken)
		amount = amount + dpsTaken
		if amount >= HP:
			current_state = STATE.DIED
		else:
			current_state = STATE.HIT
			
func do_knockback():
	actual_target.knockback()
	choosed_pos = 0

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
	if (area.owner.is_in_group("player")):
		near_player = true
	

func _on_Area2D_area_exited(area: Area2D) -> void:
	if current_state == STATE.DIED:
		pass
	elif area.owner && area.owner.is_in_group("player"):
		near_player = false


func _on_Timer_timeout() -> void:
	if current_state == STATE.IDLE:
		current_state = STATE.ATTACK
	

func _on_Cooldown_timeout():
	if current_state == STATE.IDLE:
		current_state = STATE.SELECTING_VINE


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if anim_name == "attack":
		current_state = STATE.IDLE
	if anim_name == "hit":
		current_state = STATE.KNOCKBACK
	if anim_name == "knockback":
		current_state = STATE.IDLE
		


