class_name TurianBoss
extends KinematicBody2D

onready var sprite: Sprite = $Sprite
onready var pivot: Node2D = $Pivot
onready var attack_delay_timer: Timer = $AttackDelayTimer
onready var anim_player : AnimationPlayer = $AnimationPlayer
onready var collision_shape : CollisionShape2D = $HitBox/CollisionShape2D
onready var collision_shape_body : CollisionShape2D = $CollisionShape2D

onready var UIHealthBar: Node2D = get_parent().get_parent().get_parent().get_node("GUI/UI/HealthBossContainer")

onready var spawnRifle : Position2D = $PositionRifle
onready var spawnGrenade : Position2D = $PositionGrenade
onready var spawnMissile : Position2D = $PositionMissile
onready var rifle : Rifle = $Rifle
onready var grenade : Grenade = $Grenade
onready var missile : Missile = $Missile

enum STATE {ATTACK, IDLE, HIT, DIED}

export(int) var death_speed := 150
#export(int) var moving_speed := 50

export(int) var dps := 10
export(int) var HP := 5
export(float) var shoot_delay

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

#attack variables
var selectedWeapon : TurianWeapon
var counterAttacks = 0
var animNameSelectedWeapon = "rifle"

var canAttack = true
var attack_type = 2
var sceneManager = null

func _ready():
	anim_player.play("idle")
	healthBar = UIHealthBar
	sceneManager = get_parent().get_parent()
	attack_delay_timer.wait_time = shoot_delay

func _process(_delta: float) -> void:
	actual_target = select_target()
	
	if(!paused):
		match current_state:
			STATE.HIT:
				anim_player.play("hit")
			STATE.IDLE:
				anim_player.play("idle")
				if attack_delay_timer.is_stopped():
					attack_delay_timer.wait_time = 1
					attack_delay_timer.start()
			STATE.ATTACK:
				if !actual_target.invincible && canAttack:
					#update the number of attack
					updateCounter()
					#calculate the attack with %3
					selectWeapon()
					#exec the attack choosing the selected weapon and bullet
					anim_player.play(animNameSelectedWeapon)
					canAttack = false
				#elif anim_player.current_animation != "rifle" && anim_player.current_animation != "grenade":
					#current_state = STATE.IDLE
				#else:
					#current_state = STATE.IDLE
			STATE.DIED:
				collision_shape_body.disabled = true
				collision_shape.disabled = true
				
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
	healthBar.update_healthbar(dpsTaken)
	amount = amount + dpsTaken
	if amount >= HP:
		current_state = STATE.DIED
	else:
		current_state = STATE.HIT

func shoot():
	selectedWeapon.shoot(actual_target)


func selectWeapon():
	if(counterAttacks % 2 == 0):
		selectedWeapon = missile
		selectedWeapon.position2d = spawnMissile
		animNameSelectedWeapon = "missile"
	elif(counterAttacks % 3 == 0):
		selectedWeapon = grenade
		selectedWeapon.position2d = spawnGrenade
		selectedWeapon.total_impact_zones = get_parent().get_parent().get_node("impactZones").get_children()
		animNameSelectedWeapon = "grenade"
	else:
		selectedWeapon = rifle
		selectedWeapon.position2d = spawnRifle
		animNameSelectedWeapon = "rifle"
	#selectedWeapon.direction.origin = global_position

func updateCounter():
	counterAttacks += 1
	

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
		canAttack = true


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if anim_name == "grenade" || anim_name == "rifle" || anim_name == "missile":
		current_state = STATE.IDLE
		attack_delay_timer.stop()
		canAttack = true
	if anim_name == "hit":
		current_state = STATE.IDLE
		
