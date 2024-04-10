extends Node

signal fading

export var n_positions = 5
export(Array, PackedScene) var enemy_types
export(int) var current_stage := 0
export var next_stage = ""
export var current_level = ""
export var totalFightPhases = 2
export(bool) var horizonal_vertical = false
export(int) var heightLevel = 0

onready var camera : Camera2D = get_parent().get_node("Camera2D")
onready var wall: StaticBody2D = $MovingWall
onready var AreaGo: Area2D = $MovingWall/AreaGo
onready var sound = get_parent().get_node("ost")
onready var playersParent = get_parent().get_node("PlayersList")
onready var go = get_parent().get_node("GUI/UI/Go")
onready var game_over: Sprite = get_parent().get_node("GUI/UI/GAME OVER")
onready var win = get_parent().get_node("GUI/UI/WIN")

onready var ScoreFolder = get_parent().get_node("GUI/UI/Sprite/SCORE")
onready var TotalPoints = get_parent().get_node("GUI/UI/Sprite/SCORE/TotalPoints")
onready var showedPoints = get_parent().get_node("GUI/UI/ShowedPoints")
onready var Hit = get_parent().get_node("GUI/UI/Sprite/SCORE/Hit")
onready var Kill = get_parent().get_node("GUI/UI/Sprite/SCORE/Kill")
onready var points = 0
onready var hit = 0
onready var kill = 0
onready var ActualFightPhase = 0

var spawned = false
var positions : Array = []
var spawnList: Array = []
var menuShowed = false
var players
var actualCamera

var right_left = false
var previous_limit
var firstTime = true

func _ready() -> void:
	positions = $Positions.get_children()
	players = playersParent.get_children()

	_select_stage(current_stage)
	randomize()	

func _process(_delta: float) -> void:
	TotalPoints.text = str(points)
	showedPoints.text = str(points)
	Kill.text = str(kill)
	Hit.text = str(hit)
	players = playersParent.get_children()
	
	if playersParent.get_child_count() > 1:
		checkPlayersDeep()

	for player in players:
		if right_left:
			if player.global_position.x > wall.global_position.x - 750 && spawned == false && ActualFightPhase <= totalFightPhases - 1 && current_stage != positions.size() - 1:
				_enemy_spawn(current_stage, ActualFightPhase)
		else:
			if player.global_position.x < wall.global_position.x + 750 && spawned == false && ActualFightPhase <= totalFightPhases - 1 && current_stage != positions.size() - 1:
				_enemy_spawn(current_stage, ActualFightPhase)
		
	var t = $EnemiesContainer.get_child_count()
	if $EnemiesContainer.get_child_count() == 0 && spawned == true && ActualFightPhase == totalFightPhases - 1:
		go.visible = true
		spawned = true
		
	
	if $EnemiesContainer.get_child_count() == 0 && spawned == true && ActualFightPhase < totalFightPhases - 1:
		spawned = false
		ActualFightPhase = ActualFightPhase + 1
		
	
	if win.visible == true:
		go.visible = false
	
	checkPlayersDead()
	
	if Input.is_action_pressed("ui_accept") && game_over.visible == true:
		SaveManager.game_data.lastScore = Global.totalScore
		
		if SaveManager.game_data.highScore < Global.totalScore:
			SaveManager.game_data.highScore = Global.totalScore
		SaveManager.save_game()

		get_tree().change_scene("res://scenes/levels/" + Global.dirType + current_level + ".tscn")
		
	
	if Input.is_action_pressed("ui_accept") && win.visible == true:
		Global.scoreZone = Global.scoreZone + points
		Global.totalScore = Global.totalScore + points

		SaveManager.game_data.lastScore = Global.totalScore
		SaveManager.save_game()

		next_stage = "res://scenes/levels/" + Global.dirType + next_stage + ".tscn"
		get_tree().change_scene(next_stage)
		
	

func _select_stage(number):
	right_left = !right_left

	if positions.size() - 1 == number: 
		ScoreFolder.visible = true
		showedPoints.visible = false
		
		win.visible = true
		
		var pausable_members = get_tree().get_nodes_in_group("pausable")
		for member in pausable_members:
			member.pause()
			
		
	else:
		if !horizonal_vertical:
			camera.limit_right = (positions[number + 1] as Position2D).global_position.x
			
			wall.global_position = (positions[number + 1] as Position2D).global_position
		else:
			if right_left:
				camera.limit_right = (positions[number + 1] as Position2D).global_position.x
				camera.limit_left = players[0].global_position.x - 100
			else:
				camera.limit_left = (positions[number + 1] as Position2D).global_position.x
				camera.limit_right = players[0].global_position.x + 100
			
			if !firstTime:
				emit_signal("fading")
			else:
				firstTime = false

			wall.global_position = (positions[number + 1] as Position2D).global_position
		
	

func _enemy_spawn(number, actualFightPhase):
	spawned = true
	var enemyNumber = NodePath((number) as String)
	var phase =  NodePath((actualFightPhase) as String)
	
	spawnList = $EnemiesSpawn.get_node(enemyNumber).get_node(phase).get_children()
	
	for spawn in spawnList:
		var rand_index:int = randi() % enemy_types.size()
		
		var enemy_instance = enemy_types[rand_index].instance()
		$EnemiesContainer.add_child(enemy_instance)
		enemy_instance.global_position = (spawn as Position2D).global_position
		
	

func checkPlayersDead():
	if players.size() == 0:
		showedPoints.visible = false
		ScoreFolder.visible = true
		
		game_over.visible = true
	

func checkPlayersDeep():
	if players[0].global_position.y > players[1].global_position.y:
		players[0].z_index = 1
		players[1].z_index = 0
	else:
		players[0].z_index = 0
		players[1].z_index = 1

func transition():
	for player in players:
		player.global_position.y = player.global_position.y + heightLevel
	
	camera.global_position = players[0].global_position
	camera.limit_bottom = camera.limit_bottom + heightLevel

func _on_Blasto_death(p) -> void:
	eventDeath(p)
	

func _on_Ceru_Star_death(p):
	eventDeath(p)


func eventDeath(p):
	if(p.lifeCount > 0):
		respawn(p)
	else:
		for playerTmp in players:
			if playerTmp != p:
				if playerTmp.lifeCount == 0:
					var pausable_members = get_tree().get_nodes_in_group("pausable")
		
					for member in pausable_members:
						member.pause()
					
				
			
		
	


func respawn(p):
	var respawnPoint

	if !horizonal_vertical:
		respawnPoint = Vector2(wall.global_position.x - 750, p.global_position.y)
	else:
		if right_left:
			respawnPoint = Vector2(wall.global_position.x - 750, p.global_position.y)
		else:
			respawnPoint = Vector2(wall.global_position.x + 750, p.global_position.y)
		
	p.global_position = respawnPoint


func _on_FadingSystem_black_screen():
	transition()
