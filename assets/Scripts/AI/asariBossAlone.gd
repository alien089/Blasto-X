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
onready var attack_area2d : Area2D = $Pivot/AttackCollision
onready var jump_position2D : Position2D = $JumpPosition
onready var UIHealthBar: Node2D = $UI/HealthContainer

enum STATE {ATTACK, JUMP, FLOATING, LANDING, SPRINT, IDLE, HIT, DIED,   PREPARE_SPRINT, START_SPRINT, RUNNING, DO_HIT, JUMP_ASCENDING, JUMP_FALL, PREPARE_ATTACK}

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
var timerEnded: bool = false

var sceneManager = null

var gp: Vector2

var next_state = STATE.IDLE
var received_hit:bool = false
var hit_anim_done : bool = false

func _ready():
	rng = RandomNumberGenerator.new()
	anim_player.play("idle")
	#acquisizione healthbar
	healthBar = UIHealthBar
	
	sceneManager = get_parent().get_parent()
	idle_wait_timer.connect("timeout", self, "timer_ended")
	#acquisizione posizione fissa di destinazione del jump
	jumpPos = jump_position2D.global_position
	$Pivot/FallCollision/CollisionShape2D.disabled = true
	set_idle_with_timer()

func _process(_delta: float) -> void:
	gp = global_position
	
	# scelta player da bersagliare
	actual_target = select_target()
	
	# primissima cosa, non toccare direttamente current_state ma creare un next_state che aggiorna
	#   il current state giusto prima dello switch case
	# 2 soppressione del oneTime, meglio uno stato in più che stabilizzi il determinismo della FSM

	if(!paused):
		
		# la prima assegnazione è a next_state
		current_state = next_state


		if received_hit:
			current_state = STATE.HIT

		if amount >= HP:
			current_state = STATE.DIED

		# successivamente se uno dei flag degli altri eventi è settato, faccio gli altri check in 
		#   ordine prioritario inverso, dal meno al più prioritario quindi. Es. la morte del boss 
		#   sovrascrive tutti gli eventi.

		match current_state:
			STATE.IDLE:
				# prima run non ripreparo lo sprint ma corro direttamente
				if timerEnded == true:
					next_state = STATE.START_SPRINT
				else:
					next_state = STATE.IDLE


			STATE.PREPARE_SPRINT:
				if timerEnded == true:
					next_state = STATE.START_SPRINT
				else:
					if anim_player.current_animation != "idle":
						anim_player.play("idle")
					next_state = STATE.PREPARE_SPRINT


			STATE.START_SPRINT:
				# inizio a inseguire il player

				#disabilito la collisione
				$Pivot/AttackCollision/CollisionShape2D.disabled = false
				directionPlayer = actual_target.global_position
				
				#prendo la direzione verso cui muovermi (verso il player)
				direction = Vector2(directionPlayer - global_position).normalized()
				#setto i valori di attacco attuale
				attack_setup(dpsSprint, "Sprint")
				movement = direction * sprint_speed * _delta
				flip_sprite(directionPlayer)
				next_state = STATE.RUNNING
			
			STATE.RUNNING:
				#movimento by frame
				global_position += movement
				
				# di default resto in RUNNING
				next_state = STATE.RUNNING

				# @alien occhio, qua puoi definire la priorità. se tocco il player contemporaneamente alla posizione
				#   salto o attacco? Con l'implementazione attuale attacco; invertendo i due if sotto invece salto.

				# se tocco il player, attacco
				if near_player:
					next_state = STATE.ATTACK

				# se arrivo alla posizione del player ma questi non c'è salto
				if global_position >= directionPlayer && direction > Vector2(0, 0) || global_position <= directionPlayer && direction < Vector2(0, 0):
					next_state = STATE.JUMP

			STATE.HIT:
				received_hit = false # reset pre-animazione
				anim_player.play("hit")
				next_state = STATE.DO_HIT
			
			STATE.DO_HIT:
				if hit_anim_done:
					hit_anim_done = false
					set_idle_with_timer()
					next_state = STATE.JUMP
				else:
					next_state = STATE.DO_HIT

			STATE.JUMP:
				# inizializza la sequenza di salto
				didLandingAtk = false

				#disabilito le collision (in scena è presente un collider soffitto da oltrepassare durante il salto)
				$Pivot/FallCollision/CollisionShape2D.disabled = true
				$Pivot/AttackCollision/CollisionShape2D.disabled = true
				#setto i valori di attacco attuale
				attack_setup(0, "Jump")
				#calcolo la posizione da raggiungere con il salto, una posizione in linea d'aria sopra di me ad altezza predeterminata
				targetPos = Vector2(global_position.x, jumpPos.y + 700)
				collision_shape_body.disabled = true

				#se l'animazione è nel frame di salto effettivo mi muovo
				
				next_state = STATE.JUMP_ASCENDING
				

			STATE.JUMP_ASCENDING:
				if sprite.frame == 8:
					move_towards(targetPos, jump_speed)
				#se ho raggiunto l'altitudine prevista passo in landing/discesa
				if global_position <= targetPos:
					oneTime = false
					next_state = STATE.JUMP_FALL
			

			STATE.JUMP_FALL:
				attack_setup(dpsLanding, "Falling")
				#ottengo la posizione del player
				targetPos = actual_target.global_position

				#mi sposto sopra di lui all'altitudine corrente
				global_position = Vector2(actual_target.global_position.x, global_position.y)
				next_state = STATE.LANDING


			STATE.LANDING:
				#scendo
				move_towards(targetPos, fall_speed)
				sprite.frame = 8
				$Pivot/FallCollision/CollisionShape2D.disabled = false
				
				#se arrivo alla posizione prevista riattivo le mie collisioni e 
				if global_position >= targetPos:
					anim_player.play("Falling")
					$Pivot/AttackCollision/CollisionShape2D.disabled = true
					collision_shape_body.disabled = false

					if didLandingAtk:
						attack()
					#se non ho attacco entro in idle e attendo il timer
					set_idle_with_timer()
					next_state = STATE.IDLE

			STATE.ATTACK:
				#se il player è vicino e non in stato già di hitted, attacco
				if near_player:
					anim_player.play("attack")
				
				near_player = false # disattivo per evitare doppio attacco, il resto è gestito in  _on_AttackCollision_area_entered
				
				#finito l'attacco salto
				if anim_player.current_animation != "attack":
					next_state = STATE.JUMP
				else:
					next_state = STATE.ATTACK
					

			STATE.DIED:
				collision_shape_body.disabled = true
				collision_shape.disabled = true
				collition_area2d.disabled = true
				
				anim_player.play("died")
				
				var directionDead = Vector2((global_position.x - actual_target.position.x), 0).normalized()
				
				move_and_slide(directionDead * death_speed)


		#$HealthDisplay/Label.text = STATE.keys()[current_state]
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
		received_hit = true 



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
	if current_state == STATE.ATTACK:
		for area in attack_area2d.get_overlapping_areas():
			if area.owner.is_in_group("player"):
				actual_target.hit(actual_dps, "melee", self)
	else:
		actual_target.hit(actual_dps, "melee", self)
	

func death():
	queue_free()


func pause():
	anim_player.stop()
	set_process(false)


func choose_array_numb(array):
	return array[randi() % array.size()]


func _on_FallCollision_area_entered(area): #collider posizionato alla mia base
	#se collido con il player e sono in landing
	if area.owner.is_in_group("player"):
		print("falling attack!!")
		#segno che ho attaccato
		didLandingAtk = true
		#attacco, entro in idle e aspetto il timer
		

func _on_AnimationPlayer_animation_finished(anim_name: String) -> void: #evento chiamato alla fine di ogni animazione
	# se l'animazione è hit passa in idle
	if anim_name == "hit":
		hit_anim_done = true
	# 	current_state = STATE.IDLE
	

func _on_AttackCollision_area_entered(area): #collider posizionato alla mia destra
	#se collido con il player e sono in sprint
	if area.owner.is_in_group("player"):
		near_player = true
	else:
		near_player = false

#func _on_IdleWait_timeout():
	# quando finisce il timer passo in sprint
	# current_state = STATE.SPRINT

func attack_setup(dpsChanged, animationName):
	actual_dps = dpsChanged
	anim_player.play(animationName)

func timer_ended():
	timerEnded = true

func set_idle_with_timer():
	timerEnded = false
	idle_wait_timer.stop()
	idle_wait_timer.wait_time = wait_time_attack
	idle_wait_timer.start()
