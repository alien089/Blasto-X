extends Node

export var asariBossName1 = ""
export var asariBossName2 = ""
export(float) var delay = 1.0

var asariBoss1: asariBoss
var asariBoss2: asariBoss
var timer = Timer.new()
var rng

var asari1Attacked = false
var asari2Attacked = false

func _ready():
	rng = RandomNumberGenerator.new()
	asariBoss1 = get_node(asariBossName1)
	asariBoss2 = get_node(asariBossName2)

	self.add_child(timer)
	timer.connect("timeout", self, "start")
	timer.wait_time = delay
	timer.one_shot = true
	timer.start()

func start():
	randomize()
	var choice = int(rand_range(0, 2))
	if choice == 0:
		asariBoss1.current_state = asariBoss1.STATE.JUMP
		asariBoss2.current_state = asariBoss2.STATE.SPRINT
	else:
		asariBoss1.current_state = asariBoss1.STATE.SPRINT
		asariBoss2.current_state = asariBoss2.STATE.JUMP

func choose_attack():
	randomize()
	var choice = int(rand_range(0, 2))
	if choice == 0:
		asariBoss1.current_state = asariBoss1.STATE.JUMP
		asariBoss2.current_state = asariBoss2.STATE.SPRINT
	else:
		asariBoss1.current_state = asariBoss1.STATE.SPRINT
		asariBoss2.current_state = asariBoss2.STATE.JUMP


func check_boss_attacks():
	if asari1Attacked && asari2Attacked:
		asariBoss1.current_state = asariBoss1.STATE.IDLE
		asariBoss2.current_state = asariBoss2.STATE.IDLE
		choose_attack()
		asariBoss1.oneTime = false
		asariBoss2.oneTime = false
		asari1Attacked = false
		asari2Attacked = false


func _on_asariBoss1_attackDone():
	asari1Attacked = true
	check_boss_attacks()


func _on_asariBoss2_attackDone():
	asari2Attacked = true
	check_boss_attacks()


func _on_asariBoss1_chooseMove():
	choose_attack()


func _on_asariBoss2_chooseMove():
	choose_attack()


func _on_asariBoss1_didSprintAttack():
	asariBoss2.oneTime = false
	asariBoss2.canLand = true


func _on_asariBoss2_didSprintAttack():
	asariBoss1.oneTime = false
	asariBoss1.canLand = true


func _on_asariBoss1_hasDied():
	asariBoss2.isAlone = true


func _on_asariBoss2_hasDied():
	asariBoss1.isAlone = true
