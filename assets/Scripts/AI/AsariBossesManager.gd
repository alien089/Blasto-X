extends Node

export var asariBossName1 = ""
export var asariBossName2 = ""
export(float) var delay = 5.0
export(bool) var singleBoss = false
export(PackedScene) var asariBoss1Alone
export(PackedScene) var asariBoss2Alone

var asariBoss1: asariBoss
var asariBoss2: asariBoss
var timer = Timer.new()
var rng

var asari1Attacked = false
var asari2Attacked = false

func _ready():
	randomize()
	rng = RandomNumberGenerator.new()
	asariBoss1 = get_node(asariBossName1)
	if singleBoss == false:
		asariBoss2 = get_node(asariBossName2)

	self.add_child(timer)
	timer.connect("timeout", self, "start")
	timer.wait_time = delay
	timer.one_shot = true
	timer.start()

func start():
	if check_double_bosses() == false:
		var choice = int(rand_range(0, 2))
		if choice == 0:
			asariBoss1.current_state = asariBoss1.STATE.JUMP
			asariBoss2.current_state = asariBoss2.STATE.SPRINT
		else:
			asariBoss1.current_state = asariBoss1.STATE.SPRINT
			asariBoss2.current_state = asariBoss2.STATE.JUMP

func choose_attack():
	if check_double_bosses() == false:
		var choice = int(rand_range(0, 2))
		if choice == 0:
			asariBoss1.current_state = asariBoss1.STATE.JUMP
			asariBoss2.current_state = asariBoss2.STATE.SPRINT
		else:
			asariBoss1.current_state = asariBoss1.STATE.SPRINT
			asariBoss2.current_state = asariBoss2.STATE.JUMP
	

func check_boss_attacks():
	if check_double_bosses() == false:
		if asari1Attacked && asariBoss1.current_state == asariBoss1.STATE.IDLE && asari2Attacked && asariBoss2.current_state == asariBoss2.STATE.IDLE:
			choose_attack()
			asariBoss1.oneTime = false
			asariBoss2.oneTime = false
			asari1Attacked = false
			asari2Attacked = false

func check_double_bosses():
	if get_child_count() == 2:
		return true
	else:
		return false

func _on_asariBoss1_attackDone():
	if check_double_bosses() == false:
		asari1Attacked = true
		check_boss_attacks()


func _on_asariBoss2_attackDone():
	if check_double_bosses() == false:
		asari2Attacked = true
		check_boss_attacks()


func _on_asariBoss1_chooseMove():
	if check_double_bosses() == false:
		choose_attack()


func _on_asariBoss2_chooseMove():
	if check_double_bosses() == false:
		choose_attack()


func _on_asariBoss1_didSprintAttack():
	if check_double_bosses() == false:
		asariBoss2.oneTime = false
		asariBoss2.canLand = true


func _on_asariBoss2_didSprintAttack():
	if check_double_bosses() == false:
		asariBoss1.oneTime = false
		asariBoss1.canLand = true


func _on_asariBoss1_hasDied():
	remove_child(timer)
	#remove_child(asariBoss1)

	var tmpAmount = asariBoss2.amount
	var tmpPos = asariBoss2.global_position
	var tmpState = asariBoss2.current_state
	
	asariBoss2.queue_free()
	#remove_child(asariBoss2)
	var boss_instance = asariBoss2Alone.instance()
	add_child(boss_instance)
	boss_instance.healthBar.set_healtbar(boss_instance.HP - tmpAmount)
	boss_instance.amount = tmpAmount
	boss_instance.global_position = tmpPos
	get_parent().refill_bosses()
	
	if tmpState == boss_instance.STATE.FLOATING:
		boss_instance.next_state = boss_instance.STATE.JUMP
	
	
	

func _on_asariBoss2_hasDied():
	remove_child(timer)
	#remove_child(asariBoss2)

	var tmpAmount = asariBoss1.amount
	var tmpPos = asariBoss1.global_position
	var tmpState = asariBoss1.current_state
	
	asariBoss1.queue_free()
	#remove_child(asariBoss1)
	var boss_instance = asariBoss1Alone.instance()
	add_child(boss_instance)
	boss_instance.healthBar.set_healtbar(boss_instance.HP - tmpAmount)
	boss_instance.amount = tmpAmount
	boss_instance.global_position = tmpPos
	get_parent().refill_bosses()
	
	if tmpState == boss_instance.STATE.FLOATING:
		boss_instance.next_state = boss_instance.STATE.JUMP

	
