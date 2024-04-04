class_name asariBossAlone
extends KinematicBody2D

signal hasDied

onready var sprite: Sprite = $Sprite
onready var pivot: Node2D = $Pivot
onready var idle_wait_timer: Timer = $IdleWait
onready var anim_player : AnimationPlayer = $AnimationPlayer
onready var collision_shape : CollisionShape2D = $Pivot/HitBox/CollisionShape2D
onready var collision_shape_body : CollisionShape2D = $CollisionShape2D
onready var collition_area2d : CollisionShape2D = $Pivot/AttackCollision/CollisionShape2D
onready var jump_position2D : Position2D = $JumpPosition
onready var UIHealthBar: Node2D = $UI/HealthContainer

enum STATE {ATTACK, JUMP, FLOATING, LANDING, SPRINT, IDLE, HIT, DIED}

export(int) var death_speed := 150
export(int) var sprint_speed := 250
export(float) var jump_speed := 500.0
export(float) var fall_speed := 500.0
export(int) var dpsSprint := 15
export(int) var dpsLanding := 20
export(int) var HP := 5
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
var direction : Vector2 
var movement

var targetPos: Vector2
var oneTime = false
var jumpPos: Vector2

var rng

var didLandingAtk: bool = false
var canLand: bool = false

var sceneManager = null

var gp: Vector2

func _ready():
	rng = RandomNumberGenerator.new()
	anim_player.play("idle")
	#acquisizione healthbar
	healthBar = UIHealthBar
	
	sceneManager = get_parent().get_parent()

	#acquisizione posizione fissa di destinazione del jump
	jumpPos = jump_position2D.global_position

func _process(_delta: float) -> void:
	gp = global_position
	
	# scelta player da bersagliare
	actual_target = select_target()
	
	if(!paused):
		match current_state:
			STATE.IDLE:
				oneTime = false
				if anim_player.current_animation != "idle":
					anim_player.play("idle")
				
				if idle_wait_timer.time_left == 0:
					current_state = STATE.SPRINT
					
			STATE.SPRINT:
				#prima volta nello stato
				if oneTime == false:
					#disanbilito la collisione
					$Pivot/AttackCollision/CollisionShape2D.disabled = false
					directionPlayer = actual_target.global_position
					
					#prendo la direzione verso cui muovermi (verso il player)
					direction = Vector2(directionPlayer - global_position).normalized()
					#setto i valori di attacco attuale
					attack_setup(dpsSprint, "Sprint")
					movement = direction * sprint_speed * _delta
					flip_sprite(directionPlayer)
					oneTime = true
				
				#movimento by frame
				global_position += movement
				
				#se arrivo alla posizione del player ma questi non c'è salto
				if global_position >= directionPlayer && direction > Vector2(0, 0) || global_position <= directionPlayer && direction < Vector2(0, 0):
					current_state = STATE.JUMP
					oneTime = false

			STATE.HIT:
				anim_player.play("hit")

			STATE.ATTACK:
				#se il player è vicino e non in stato già di hitted, attacco
				if near_player && !actual_target.invincible:
					anim_player.play("attack")
				
				#finito l'attacco salto
				if anim_player.current_animation != "attack":
					oneTime = false
					current_state = STATE.JUMP

			STATE.JUMP:
				#prima volta nello stato
				if oneTime == false:
					didLandingAtk = false

					#disabilito le collision (in scena è presente un collider soffitto da oltrepassare durante il salto)
					$Pivot/AttackCollision/CollisionShape2D.disabled = true
					#setto i valori di attacco attuale
					attack_setup(0, "Jump")
					#calcolo la posizione da raggiungere con il salto, una posizione in linea d'aria sopra di me ad altezza predeterminata
					targetPos = Vector2(global_position.x, jumpPos.y)
					collision_shape_body.disabled = true
					oneTime = true

				#se l'animazione è nel frame di salto effettivo mi muovo
				if sprite.frame == 8:
					move_towards(targetPos, jump_speed)

				#se ho raggiunto l'altitudine prevista passo in landing/discesa
				if global_position <= targetPos:
					oneTime = false
					current_state = STATE.LANDING
					
			STATE.LANDING:
				#prima volta nello stato
				if oneTime == false:
					#setto i valori di attacco attuale
					attack_setup(dpsLanding, "Falling")
					#ottengo la posizione del player
					targetPos = actual_target.global_position

					#mi sposto sopra di lui all'altitudine corrente
					global_position = Vector2(actual_target.global_position.x, global_position.y)
					oneTime = true
				
				#scendo
				move_towards(targetPos, fall_speed)
				
				#se arrivo alla posizione prevista riattivo le mie collisioni e 
				if global_position.y >= targetPos.y:
					$Pivot/AttackCollision/CollisionShape2D.disabled = true
					$Pivot/FallCollision/CollisionShape2D.disabled = false
					collision_shape_body.disabled = false
					#se non ho attacco entro in idle e attendo il timer
					if didLandingAtk == false:
						set_idle_with_timer()
			
			STATE.DIED:
				collision_shape_body.disabled = true
				collision_shape.disabled = true
				collition_area2d.disabled = true
				
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


func _on_FallCollision_area_entered(area): #collider posizionato alla mia base
	#se collido con il player e sono in landing
	if area.owner.is_in_group("player") && current_state == STATE.LANDING:
		print("falling attack!!")
		#segno che ho attaccato
		didLandingAtk = true
		#attacco, entro in idle e aspetto il timer
		attack()
		set_idle_with_timer()
		

func _on_AnimationPlayer_animation_finished(anim_name: String) -> void: #evento chiamato alla fine di ogni animazione
	#se l'animazione è hit passa in idle
	if anim_name == "hit":
		current_state = STATE.IDLE
	

func _on_AttackCollision_area_entered(area): #collider posizionato alla mia destra
	#se collido con il player e sono in sprint
	if area.owner.is_in_group("player") && current_state == STATE.SPRINT:
		#passo in attacco
		current_state = STATE.ATTACK
		#segno di essere vicino al player
		near_player = true

func _on_IdleWait_timeout():
	#quando finisce il timer passo in sprint
	current_state = STATE.SPRINT

func attack_setup(dpsChanged, animationName):
	actual_dps = dpsChanged
	anim_player.play(animationName)


func set_idle_with_timer():
	current_state = STATE.IDLE
	idle_wait_timer.stop()
	idle_wait_timer.wait_time = wait_time_attack
	idle_wait_timer.start()
